//  WHAT: The template of `AuthField.swift`, the underline field: no box, the placeholder its only label, a thin line
//        along its bottom that turns to the error colour; secure entry for passwords.

extension Template {
    static let authField = ##"""
    import SwiftUI
    #if os(iOS)
    import UIKit
    #endif

    /// The underline field: no box, the placeholder its only label, and a thin line along its bottom that turns to the
    /// error colour. Passwords use secure entry; autocorrection and capitals are off.
    struct AuthField: View {
        /// What the field takes: its keyboard, what the system fills in, and whether it hides what is typed.
        enum Kind: Sendable {
            case email, password, newPassword, text
        }

        private let placeholder: LocalizedStringKey
        @Binding private var text: String
        private let kind: Kind
        private let error: Bool

        /// - Parameter error: draws the line in the error colour, as when a confirmation differs.
        init(_ placeholder: LocalizedStringKey, text: Binding<String>, kind: Kind = .text, error: Bool = false) {
            self.placeholder = placeholder
            self._text = text
            self.kind = kind
            self.error = error
        }

        var body: some View {
            entry
                .font(AuthLook.field)
                #if os(iOS)
                .keyboardType(kind == .email ? .emailAddress : .default)
                .textContentType(contentType)
                #endif
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .padding(.horizontal, {{t:field.horizontal}})
                .padding(.vertical, {{t:field.vertical}})
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(error ? AuthLook.lineError : AuthLook.line)
                        .frame(height: {{t:field.line}})
                        .padding(.horizontal, {{t:field.lineInset}})
                }
        }

        @ViewBuilder
        private var entry: some View {
            switch kind {
            case .password, .newPassword:
                SecureField(placeholder, text: $text)
            case .email, .text:
                TextField(placeholder, text: $text)
            }
        }

        #if os(iOS)
        /// What the system fills the field with: a saved email, a saved password, or a new one it suggests.
        private var contentType: UITextContentType? {
            switch kind {
            case .email: return .emailAddress
            case .password: return .password
            case .newPassword: return .newPassword
            case .text: return nil
            }
        }
        #endif
    }

    #Preview {
        VStack(spacing: 12) {
            AuthField("Email", text: .constant("name@example.com"), kind: .email)
            AuthField("Password", text: .constant(""), kind: .password)
            AuthField("Confirm password", text: .constant("secret"), kind: .newPassword, error: true)
        }
        .padding()
    }
    """##
}
