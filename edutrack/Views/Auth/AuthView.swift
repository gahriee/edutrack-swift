import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var confirmPassword = ""

    var body: some View {
        VStack(spacing: 20) {
            Text(isLogin ? "Welcome Back" : "Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            Picker("Mode", selection: $isLogin) {
                Text("Login").tag(true)
                Text("Register").tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if let error = authViewModel.errorMessage {
                Text(error)
                    .foregroundColor(AppColors.absent)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 16) {
                if !isLogin {
                    AuthTextField(title: "Full Name", text: $name)
                }
                
                AuthTextField(title: "Email", text: $email)
                
                AuthTextField(title: "Password", text: $password, isSecure: true)
                
                if !isLogin {
                    AuthTextField(title: "Confirm Password", text: $confirmPassword, isSecure: true)
                }
            }
            .padding(.horizontal)

            Button(action: handleAction) {
                if authViewModel.state == .loading {
                    ProgressView().tint(.white)
                } else {
                    Text(isLogin ? "Sign In" : "Sign Up")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.primary)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 10)
            .disabled(authViewModel.state == .loading)

            Spacer()
        }
        .background(AppColors.background.ignoresSafeArea())
    }

    private func handleAction() {
        Task {
            if isLogin {
                await authViewModel.login(email: email, password: password)
            } else {
                guard password == confirmPassword else {
                    authViewModel.errorMessage = "Passwords do not match."
                    return
                }
                await authViewModel.register(name: name, email: email, password: password)
            }
        }
    }
}
