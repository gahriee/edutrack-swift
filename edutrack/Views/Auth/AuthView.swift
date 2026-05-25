import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var confirmPassword = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header Space
                VStack(spacing: 16) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.white)
                        .padding(20)
                        .background(
                            Circle()
                                .fill(LinearGradient(colors: [AppColors.primary, AppColors.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: AppColors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                    
                    Text("EduTrack")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(isLogin ? "Welcome back, Professor" : "Create your account")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .animation(.none, value: isLogin)
                }
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // Form Card
                VStack(spacing: 24) {
                    // Custom Segmented Control
                    HStack(spacing: 0) {
                        TabButton(title: "Sign In", isSelected: isLogin) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isLogin = true
                            }
                        }
                        
                        TabButton(title: "Sign Up", isSelected: !isLogin) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isLogin = false
                            }
                        }
                    }
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .foregroundColor(AppColors.absent)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        if !isLogin {
                            AuthTextField(title: "Full Name", text: $name)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        AuthTextField(title: "Email", text: $email)
                        
                        AuthTextField(title: "Password", text: $password, isSecure: true)
                        
                        if !isLogin {
                            AuthTextField(title: "Confirm Password", text: $confirmPassword, isSecure: true)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    
                    // Submit Button
                    Button(action: handleAction) {
                        HStack {
                            if authViewModel.state == .loading {
                                ProgressView().tint(.white)
                            } else {
                                Text(isLogin ? "Sign In" : "Create Account")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [AppColors.primary, AppColors.secondary], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: AppColors.primary.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .disabled(authViewModel.state == .loading)
                    .opacity(authViewModel.state == .loading ? 0.7 : 1)
                }
                .padding(.vertical, 30)
                .background(AppColors.surface)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
                .padding(.horizontal, 20)
                
                Spacer(minLength: 40)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .onTapGesture {
            hideKeyboard()
        }
    }

    private func handleAction() {
        hideKeyboard()
        Task {
            if isLogin {
                await authViewModel.login(email: email, password: password)
            } else {
                guard password == confirmPassword else {
                    authViewModel.errorMessage = "Passwords do not match."
                    return
                }
                guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
                    authViewModel.errorMessage = "Please fill in all fields."
                    return
                }
                await authViewModel.register(name: name, email: email, password: password)
            }
        }
    }
}

fileprivate struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? AppColors.surface : Color.clear)
                        .shadow(color: isSelected ? Color.black.opacity(0.04) : Color.clear, radius: 2, x: 0, y: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
