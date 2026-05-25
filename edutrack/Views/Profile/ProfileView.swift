import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(AppColors.primary)
                .padding(.top, 40)

            VStack(spacing: 8) {
                Text(authViewModel.professor?.name ?? "Professor")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(authViewModel.professor?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Button(action: {
                authViewModel.logout()
            }) {
                Text("Sign Out")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.absent)
                    .cornerRadius(10)
            }
            .padding()
            .padding(.bottom, 20)
        }
        .navigationTitle("Profile")
        .background(AppColors.background.ignoresSafeArea())
    }
}
