import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            switch authViewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppColors.background)
            case .unauthenticated:
                AuthView()
            case .authenticated:
                MainTabView()
            }
        }
        .animation(.default, value: authViewModel.state)
    }
}
