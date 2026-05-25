import Foundation

@MainActor
final class ClassDetailViewModel: ObservableObject {
    @Published var sections: [Section] = []
    @Published var errorMessage: String?

    private let classId: String
    private let repository = AttendanceRepository.shared
    private var listenerTask: Task<Void, Never>?

    init(classId: String) {
        self.classId = classId
        startListening()
    }
    deinit { listenerTask?.cancel() }

    private func startListening() {
        listenerTask = Task {
            for await result in repository.sectionsStream(classId: classId) {
                switch result {
                case .success(let sections): self.sections = sections
                case .failure(let error):   self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func addSection(name: String) async {
        do { try await repository.addSection(name: name, classId: classId) }
        catch { errorMessage = error.localizedDescription }
    }

    func deleteSection(_ section: Section) async {
        do { try await repository.deleteSection(sectionId: section.id) }
        catch { errorMessage = error.localizedDescription }
    }
}
