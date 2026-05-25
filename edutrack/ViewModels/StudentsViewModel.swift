import Foundation
import FirebaseAuth

@MainActor
final class StudentsViewModel: ObservableObject {
    @Published var students: [Student] = []
    @Published var searchText: String = ""
    @Published var errorMessage: String?

    private let repository = AttendanceRepository.shared
    private var listenerTask: Task<Void, Never>?

    var filtered: [Student] {
        guard !searchText.isEmpty else { return students }
        let q = searchText.lowercased()
        return students.filter {
            $0.fullName.lowercased().contains(q) ||
            $0.studentNumber.lowercased().contains(q) ||
            $0.email.lowercased().contains(q)
        }
    }

    init() { startListening() }
    deinit { listenerTask?.cancel() }

    private func startListening() {
        guard let professorId = Auth.auth().currentUser?.uid else { return }
        listenerTask = Task {
            for await result in repository.allStudentsStream(professorId: professorId) {
                if case .success(let students) = result { self.students = students }
            }
        }
    }

    func createStudent(firstName: String, lastName: String, studentNumber: String, email: String) async {
        guard let professorId = Auth.auth().currentUser?.uid else { return }
        do {
            try await repository.createStudent(
                firstName: firstName, lastName: lastName,
                studentNumber: studentNumber, email: email,
                professorId: professorId
            )
        } catch { errorMessage = error.localizedDescription }
    }
}
