import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Avatar Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [AppColors.primary, AppColors.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 120, height: 120)
                            .shadow(color: AppColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Text(getInitials(name: authViewModel.professor?.name))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 4) {
                        Text(authViewModel.professor?.name ?? "Professor")
                            .font(.title2.bold())
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(authViewModel.professor?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                // Details Card (Visual placeholers for a premium feel)
                VStack(spacing: 0) {
                    ProfileRow(icon: "person.text.rectangle", title: "Account Details", subtitle: "Manage your profile")
                    Divider().padding(.leading, 72)
                    ProfileRow(icon: "bell.badge", title: "Notifications", subtitle: "Update preferences")
                    Divider().padding(.leading, 72)
                    ProfileRow(icon: "shield.checkerboard", title: "Privacy & Security", subtitle: "Password and authentication")
                }
                .background(AppColors.surface)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
                
                Spacer(minLength: 40)

                // Sign Out Button
                Button(action: {
                    authViewModel.logout()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .font(.headline)
                    .foregroundColor(AppColors.absent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.absent.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .background(AppColors.background.ignoresSafeArea())
    }
    
    private func getInitials(name: String?) -> String {
        guard let name = name, !name.isEmpty else { return "P" }
        let components = name.components(separatedBy: " ")
        if components.count > 1 {
            let first = components.first!.prefix(1)
            let last = components.last!.prefix(1)
            return String(first + last).uppercased()
        }
        return String(name.prefix(1)).uppercased()
    }
}

fileprivate struct ProfileRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.background)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(AppColors.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(AppColors.outline)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}
