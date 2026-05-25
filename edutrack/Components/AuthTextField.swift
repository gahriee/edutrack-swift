import SwiftUI

struct AuthTextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        Group {
            if isSecure {
                SecureField(title, text: $text)
            } else {
                TextField(title, text: $text)
                    .keyboardType(inferKeyboard())
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        .padding(12)
        .background(AppColors.surface)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.outline, lineWidth: 1)
        )
    }

    private func inferKeyboard() -> UIKeyboardType {
        if title.lowercased().contains("email") { return .emailAddress }
        return .default
    }
}
