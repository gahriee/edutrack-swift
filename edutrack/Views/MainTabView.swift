import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Classes", systemImage: "rectangle.grid.2x2") }

            NavigationStack {
                StudentsLibraryView()
            }
            .tabItem { Label("Students", systemImage: "person.2") }

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.circle") }
        }
        .tint(AppColors.primary)
    }
}
