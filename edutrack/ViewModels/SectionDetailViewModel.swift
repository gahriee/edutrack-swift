import Foundation

@MainActor
final class SectionDetailViewModel: ObservableObject {
    @Published var students: [Student] = []
    @Published var session: AttendanceSession?
    @Published var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    @Published var errorMessage: String?

    private let section: Section
    private let repository = AttendanceRepository.shared
    private var studentsTask: Task<Void, Never>?
    private var attendanceTask: Task<Void, Never>?

    init(section: Section) {
        self.section = section
        startListening()
    }
    deinit {
        studentsTask?.cancel()
        attendanceTask?.cancel()
    }

    private func startListening() {
        studentsTask = Task {
            for await result in repository.studentsStream(studentIds: section.studentIds) {
                if case .success(let students) = result { self.students = students }
            }
        }
        listenToAttendance()
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

    func exportCSV() -> String {
        repository.exportAttendanceCSV(session: session, students: students)
    }
}
