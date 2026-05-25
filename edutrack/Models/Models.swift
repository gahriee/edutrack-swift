import Foundation
import FirebaseFirestore

// MARK: - Professor

struct Professor: Codable, Identifiable, Hashable {
    let id: String
    var name: String
    let email: String
    // password never stored on client; handled by Firebase Auth
}

// MARK: - SchoolClass

struct SchoolClass: Codable, Identifiable, Hashable {
    let id: String
    let name: String        // e.g. "Mathematics 101"
    let subject: String
    let professorId: String // → Professor
}

// MARK: - Section

struct Section: Codable, Identifiable, Hashable {
    let id: String
    let name: String        // e.g. "Section A"
    let classId: String     // → SchoolClass
    var studentIds: [String] = []
}

// MARK: - Student

struct Student: Codable, Identifiable, Hashable {
    let id: String
    let firstName: String
    let lastName: String
    let studentNumber: String
    let email: String
    let professorId: String // → Professor

    var fullName: String { "\(firstName) \(lastName)" }
}

// MARK: - AttendanceRecord

struct AttendanceRecord: Codable, Identifiable, Hashable {
    let id: String
    let sectionId: String   // → Section
    let studentId: String   // → Student
    let date: Date
    var status: AttendanceStatus
}

// MARK: - AttendanceSession

struct AttendanceSession: Identifiable {
    let id: String
    let sectionId: String
    let date: Date
    var records: [AttendanceRecord]
}

// MARK: - AttendanceStatus

enum AttendanceStatus: String, Codable, CaseIterable {
    case present  // ✅ green
    case absent   // ❌ red
    case late     // 🕐 orange

    var label: String { rawValue.capitalized }
}

// MARK: - Firestore Mapping Helpers

extension Professor {
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        self.id          = document.documentID
        self.name        = data["name"]  as? String ?? ""
        self.email       = data["email"] as? String ?? ""
    }

    var firestoreData: [String: Any] {
        ["name": name, "email": email]
    }
}

extension SchoolClass {
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        self.id          = document.documentID
        self.name        = data["name"] as? String ?? ""
        self.subject     = data["subject"] as? String ?? ""
        self.professorId = data["professorId"] as? String ?? ""
    }

    var firestoreData: [String: Any] {
        ["name": name, "subject": subject, "professorId": professorId]
    }
}

extension Section {
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        self.id          = document.documentID
        self.name        = data["name"] as? String ?? ""
        self.classId     = data["classId"] as? String ?? ""
        self.studentIds  = data["studentIds"] as? [String] ?? []
    }

    var firestoreData: [String: Any] {
        ["name": name, "classId": classId, "studentIds": studentIds]
    }
}

extension Student {
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        self.id            = document.documentID
        self.firstName     = data["firstName"] as? String ?? ""
        self.lastName      = data["lastName"] as? String ?? ""
        self.studentNumber = data["studentNumber"] as? String ?? ""
        self.email         = data["email"] as? String ?? ""
        self.professorId   = data["professorId"] as? String ?? ""
    }

    var firestoreData: [String: Any] {
        [
            "firstName": firstName,
            "lastName": lastName,
            "studentNumber": studentNumber,
            "email": email,
            "professorId": professorId
        ]
    }
}

extension AttendanceRecord {
    init?(document: DocumentSnapshot) {
        guard let data = document.data() else { return nil }
        self.id        = document.documentID
        self.sectionId = data["sectionId"] as? String ?? ""
        self.studentId = data["studentId"] as? String ?? ""
        
        if let timestamp = data["date"] as? Timestamp {
            self.date = timestamp.dateValue()
        } else {
            self.date = Date()
        }
        
        let statusString = data["status"] as? String ?? AttendanceStatus.present.rawValue
        self.status = AttendanceStatus(rawValue: statusString) ?? .present
    }

    var firestoreData: [String: Any] {
        [
            "sectionId": sectionId,
            "studentId": studentId,
            "date": Timestamp(date: date),
            "status": status.rawValue
        ]
    }
}
