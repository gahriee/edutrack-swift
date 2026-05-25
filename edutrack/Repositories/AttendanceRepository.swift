import Foundation
import FirebaseAuth
import FirebaseFirestore

enum AppError: Error, LocalizedError {
    case notFound(String)
    
    var errorDescription: String? {
        switch self {
        case .notFound(let message):
            return message
        }
    }
}

final class AttendanceRepository {
    static let shared = AttendanceRepository()
    private let db = Firestore.firestore()
    private init() {}

    // MARK: - Auth

    func register(name: String, email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let professor = Professor(id: result.user.uid, name: name, email: email)
        try await db.collection("professors").document(professor.id).setData(professor.firestoreData)
    }

    func login(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func fetchProfessor(uid: String) async throws -> Professor {
        let doc = try await db.collection("professors").document(uid).getDocument()
        guard let professor = Professor(document: doc) else {
            throw AppError.notFound("Professor \(uid)")
        }
        return professor
    }

    // MARK: - Classes

    func classesStream(professorId: String) -> AsyncStream<Result<[SchoolClass], Error>> {
        AsyncStream { continuation in
            let listener = db.collection("classes")
                .whereField("professorId", isEqualTo: professorId)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.yield(.failure(error))
                    } else {
                        let classes = snapshot?.documents.compactMap(SchoolClass.init) ?? []
                        continuation.yield(.success(classes))
                    }
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func addClass(name: String, subject: String, professorId: String) async throws {
        let ref = db.collection("classes").document()
        let schoolClass = SchoolClass(id: ref.documentID, name: name, subject: subject, professorId: professorId)
        try await ref.setData(schoolClass.firestoreData)
    }

    func deleteClass(classId: String) async throws {
        let batch = db.batch()
        let sections = try await db.collection("sections")
            .whereField("classId", isEqualTo: classId).getDocuments()

        for sectionDoc in sections.documents {
            let records = try await db.collection("attendance_records")
                .whereField("sectionId", isEqualTo: sectionDoc.documentID).getDocuments()
            records.documents.forEach { batch.deleteDocument($0.reference) }
            batch.deleteDocument(sectionDoc.reference)
        }
        batch.deleteDocument(db.collection("classes").document(classId))
        try await batch.commit()
    }

    // MARK: - Sections

    func sectionsStream(classId: String) -> AsyncStream<Result<[Section], Error>> {
        AsyncStream { continuation in
            let listener = db.collection("sections")
                .whereField("classId", isEqualTo: classId)
                .addSnapshotListener { snapshot, error in
                    if let error { continuation.yield(.failure(error)) }
                    else {
                        let sections = snapshot?.documents.compactMap(Section.init) ?? []
                        continuation.yield(.success(sections))
                    }
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func addSection(name: String, classId: String) async throws {
        let ref = db.collection("sections").document()
        let section = Section(id: ref.documentID, name: name, classId: classId)
        try await ref.setData(section.firestoreData)
    }

    func deleteSection(sectionId: String) async throws {
        let batch = db.batch()
        let records = try await db.collection("attendance_records")
            .whereField("sectionId", isEqualTo: sectionId).getDocuments()
        records.documents.forEach { batch.deleteDocument($0.reference) }
        batch.deleteDocument(db.collection("sections").document(sectionId))
        try await batch.commit()
    }

    // MARK: - Students

    func allStudentsStream(professorId: String) -> AsyncStream<Result<[Student], Error>> {
        AsyncStream { continuation in
            let listener = db.collection("students")
                .whereField("professorId", isEqualTo: professorId)
                .addSnapshotListener { snapshot, error in
                    if let error { continuation.yield(.failure(error)) }
                    else {
                        let students = snapshot?.documents.compactMap(Student.init) ?? []
                        continuation.yield(.success(students))
                    }
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func studentsStream(studentIds: [String]) -> AsyncStream<Result<[Student], Error>> {
        // Firestore `in` queries are limited to 30 items; chunk if needed
        AsyncStream { continuation in
            guard !studentIds.isEmpty else {
                continuation.yield(.success([]))
                return
            }
            let listener = db.collection("students")
                .whereField(FieldPath.documentID(), in: studentIds)
                .addSnapshotListener { snapshot, error in
                    if let error { continuation.yield(.failure(error)) }
                    else {
                        let students = snapshot?.documents.compactMap(Student.init) ?? []
                        continuation.yield(.success(students))
                    }
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func createStudent(firstName: String, lastName: String, studentNumber: String,
                       email: String, professorId: String) async throws {
        let ref = db.collection("students").document()
        let student = Student(id: ref.documentID, firstName: firstName, lastName: lastName,
                              studentNumber: studentNumber, email: email, professorId: professorId)
        try await ref.setData(student.firestoreData)
    }

    func addStudentToSection(studentId: String, sectionId: String) async throws {
        try await db.collection("sections").document(sectionId)
            .updateData(["studentIds": FieldValue.arrayUnion([studentId])])
    }

    func removeStudentFromSection(studentId: String, sectionId: String) async throws {
        let batch = db.batch()
        // Remove from section
        batch.updateData(
            ["studentIds": FieldValue.arrayRemove([studentId])],
            forDocument: db.collection("sections").document(sectionId)
        )
        // Delete attendance records for this (student, section) pair
        let records = try await db.collection("attendance_records")
            .whereField("sectionId", isEqualTo: sectionId)
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments()
        records.documents.forEach { batch.deleteDocument($0.reference) }
        try await batch.commit()
    }

    // MARK: - Attendance

    func attendanceStream(sectionId: String, date: Date) -> AsyncStream<Result<AttendanceSession, Error>> {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay   = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        return AsyncStream { continuation in
            let listener = db.collection("attendance_records")
                .whereField("sectionId", isEqualTo: sectionId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                .whereField("date", isLessThan: Timestamp(date: endOfDay))
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.yield(.failure(error))
                    } else {
                        let records = snapshot?.documents.compactMap(AttendanceRecord.init) ?? []
                        let session = AttendanceSession(
                            id: sectionId + "_" + startOfDay.ISO8601Format(),
                            sectionId: sectionId,
                            date: date,
                            records: records
                        )
                        continuation.yield(.success(session))
                    }
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func updateRecord(sectionId: String, date: Date, studentId: String, status: AttendanceStatus) async throws {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let query = db.collection("attendance_records")
            .whereField("sectionId", isEqualTo: sectionId)
            .whereField("studentId", isEqualTo: studentId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("date", isLessThan: Timestamp(date: Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!))

        let existing = try await query.getDocuments()
        let data: [String: Any] = [
            "sectionId": sectionId,
            "studentId": studentId,
            "date": Timestamp(date: startOfDay),
            "status": status.rawValue
        ]

        if let doc = existing.documents.first {
            try await doc.reference.updateData(["status": status.rawValue])
        } else {
            let ref = db.collection("attendance_records").document()
            try await ref.setData(["id": ref.documentID].merging(data) { $1 })
        }
    }

    // MARK: - CSV Export (no third-party library needed)

    func exportAttendanceCSV(session: AttendanceSession?, students: [Student]) -> String {
        var lines = ["Student Number,Full Name,Status"]
        for student in students {
            let status = session?.records.first(where: { $0.studentId == student.id })?.status ?? .present
            lines.append("\(student.studentNumber),\(student.fullName),\(status.label)")
        }
        return lines.joined(separator: "\n")
    }
}
