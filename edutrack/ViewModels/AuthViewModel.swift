import Foundation
import Combine
import FirebaseAuth

enum AuthState: Equatable {
    case loading
    case unauthenticated
    case authenticated
}

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var state: AuthState = .loading
    @Published var professor: Professor?
    @Published var errorMessage: String?

    private let repository = AttendanceRepository.shared
    private var authHandle: AuthStateDidChangeListenerHandle?

    init() { listenToAuthState() }

    deinit { authHandle.map { Auth.auth().removeStateDidChangeListener($0) } }

    private func listenToAuthState() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { await self.handleAuthChange(user: user) }
        }
    }

    private func handleAuthChange(user: FirebaseAuth.User?) async {
        guard let user else {
            state = .unauthenticated
            professor = nil
            return
        }
        do {
            professor = try await repository.fetchProfessor(uid: user.uid)
            state = .authenticated
        } catch {
            state = .unauthenticated
        }
    }

    func login(email: String, password: String) async {
        errorMessage = nil
        do {
            try await repository.login(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func register(name: String, email: String, password: String) async {
        errorMessage = nil
        do {
            try await repository.register(name: name, email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        try? Auth.auth().signOut()
    }
}
