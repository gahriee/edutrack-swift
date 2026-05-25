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

    func updateClass(classId: String, name: String, subject: String) async throws {
        try await db.collection("classes").document(classId).updateData([
            "name": name,
            "subject": subject
        ])
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

    func updateSection(sectionId: String, name: String) async throws {
        try await db.collection("sections").document(sectionId).updateData([
            "name": name
        ])
    }

    func sectionStream(sectionId: String) -> AsyncStream<Result<Section, Error>> {
        AsyncStream { continuation in
            let listener = db.collection("sections").document(sectionId)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.yield(.failure(error))
                    } else if let snapshot = snapshot, snapshot.exists, let section = Section(document: snapshot) {
                        continuation.yield(.success(section))
                    } else {
                        continuation.yield(.failure(AppError.notFound("Section not found")))
                    }
                }
            continuation.onTermination = { _ in listener.remove() }
        }
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

    func updateStudent(studentId: String, firstName: String, lastName: String, studentNumber: String, email: String) async throws {
        try await db.collection("students").document(studentId).updateData([
            "firstName": firstName,
            "lastName": lastName,
            "studentNumber": studentNumber,
            "email": email
        ])
    }

    func deleteStudent(studentId: String) async throws {
        let batch = db.batch()
        
        // Remove from all sections
        let sections = try await db.collection("sections")
            .whereField("studentIds", arrayContains: studentId).getDocuments()
        for sectionDoc in sections.documents {
            batch.updateData(
                ["studentIds": FieldValue.arrayRemove([studentId])],
                forDocument: sectionDoc.reference
            )
        }
        
        // Delete all attendance records for this student
        let records = try await db.collection("attendance_records")
            .whereField("studentId", isEqualTo: studentId).getDocuments()
        records.documents.forEach { batch.deleteDocument($0.reference) }
        
        // Delete the student document
        batch.deleteDocument(db.collection("students").document(studentId))
        try await batch.commit()
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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        let dateString = formatter.string(from: date)

        return AsyncStream { continuation in
            let listener = db.collection("attendance_records")
                .whereField("sectionId", isEqualTo: sectionId)
                .whereField("dateString", isEqualTo: dateString)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.yield(.failure(error))
                    } else {
                        let records = snapshot?.documents.compactMap(AttendanceRecord.init) ?? []
                        let session = AttendanceSession(
                            id: sectionId + "_" + dateString,
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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        let dateString = formatter.string(from: date)
        
        let docId = "\(sectionId)_\(studentId)_\(dateString)"
        let record = AttendanceRecord(
            id: docId,
            sectionId: sectionId,
            studentId: studentId,
            date: Calendar.current.startOfDay(for: date),
            dateString: dateString,
            status: status
        )
        
        try await db.collection("attendance_records").document(docId).setData(record.firestoreData)
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
