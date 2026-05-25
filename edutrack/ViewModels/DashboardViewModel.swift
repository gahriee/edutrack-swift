import Foundation
import FirebaseAuth

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var classes: [SchoolClass] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository = AttendanceRepository.shared
    private var listenerTask: Task<Void, Never>?

    init() { startListening() }
    deinit { listenerTask?.cancel() }

    private func startListening() {
        guard let professorId = Auth.auth().currentUser?.uid else { return }
        listenerTask = Task {
            for await result in repository.classesStream(professorId: professorId) {
                switch result {
                case .success(let classes): self.classes = classes
                case .failure(let error):   self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func addClass(name: String, subject: String) async {
        guard let professorId = Auth.auth().currentUser?.uid else { return }
        do { try await repository.addClass(name: name, subject: subject, professorId: professorId) }
        catch { errorMessage = error.localizedDescription }
    }

    func deleteClass(_ schoolClass: SchoolClass) async {
        do { try await repository.deleteClass(classId: schoolClass.id) }
        catch { errorMessage = error.localizedDescription }
    }
}
