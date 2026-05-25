import Foundation
import FirebaseAuth

@MainActor
final class SectionDetailViewModel: ObservableObject {
    @Published var students: [Student] = []
    @Published var allStudents: [Student] = []
    @Published var session: AttendanceSession?
    @Published var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    @Published var errorMessage: String?

    private let section: Section
    private let repository = AttendanceRepository.shared
    private var sectionTask: Task<Void, Never>?
    private var studentsTask: Task<Void, Never>?
    private var allStudentsTask: Task<Void, Never>?
    private var attendanceTask: Task<Void, Never>?

    init(section: Section) {
        self.section = section
        startListening()
    }
    deinit {
        sectionTask?.cancel()
        studentsTask?.cancel()
        allStudentsTask?.cancel()
        attendanceTask?.cancel()
    }

    private func startListening() {
        sectionTask = Task {
            for await result in repository.sectionStream(sectionId: section.id) {
                if case .success(let updatedSection) = result {
                    updateStudentsStream(studentIds: updatedSection.studentIds)
                }
            }
        }
        guard let professorId = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        allStudentsTask = Task {
            for await result in repository.allStudentsStream(professorId: professorId) {
                if case .success(let allStudents) = result { self.allStudents = allStudents }
            }
        }
        listenToAttendance()
    }

    private func updateStudentsStream(studentIds: [String]) {
        studentsTask?.cancel()
        studentsTask = Task {
            for await result in repository.studentsStream(studentIds: studentIds) {
                if case .success(let students) = result { self.students = students }
            }
        }
    }

    func changeDate(to date: Date) {
        selectedDate = Calendar.current.startOfDay(for: date)
        attendanceTask?.cancel()
        listenToAttendance()
    }

    private func listenToAttendance() {
        attendanceTask = Task {
            for await result in repository.attendanceStream(sectionId: section.id, date: selectedDate) {
                if case .success(let session) = result { self.session = session }
            }
        }
    }

    // Default unrecorded students to .present
    func statusForStudent(_ student: Student) -> AttendanceStatus {
        session?.records.first(where: { $0.studentId == student.id })?.status ?? .present
    }

    func updateStatus(for student: Student, status: AttendanceStatus) async {
        do {
            try await repository.updateRecord(
                sectionId: section.id,
                date: selectedDate,
                studentId: student.id,
                status: status
            )
        } catch { errorMessage = error.localizedDescription }
    }

    func removeStudentFromSection(_ student: Student) async {
        do { try await repository.removeStudentFromSection(studentId: student.id, sectionId: section.id) }
        catch { errorMessage = error.localizedDescription }
    }

    func addStudentToSection(_ student: Student) async {
        do { try await repository.addStudentToSection(studentId: student.id, sectionId: section.id) }
        catch { errorMessage = error.localizedDescription }
    }

    func exportCSV() -> String {
        repository.exportAttendanceCSV(session: session, students: students)
    }
}
