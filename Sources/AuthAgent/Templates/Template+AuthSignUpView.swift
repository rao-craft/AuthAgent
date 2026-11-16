//  WHAT: The template of `AuthSignUpView.swift`: the mark and a greeting over an email, a password and its
//        confirmation, the hint while they differ, the outlined button, and the footer back to Sign In.

extension Template {
    static let authSignUpView = ##"""
    import SwiftUI

    /// Sign Up: the mark and a greeting over an email, a password and its confirmation, the button, and a way back to
    /// Sign In. The confirmation's line turns red while it differs; what `signUp` throws is shown under the fields.
    struct AuthSignUpView: View {
        /// Creates the account; nil leaves the button out.
        var signUp: (@MainActor (_ email: String, _ password: String) async throws -> Void)?
        /// Called with the email once `signUp` returns: the flow asks for the code sent to it.
        var created: ((_ email: String) -> Void)?
        /// Back to Sign In; nil leaves the footer out.
        var signInInstead: (() -> Void)?

        @State private var email = ""
        @State private var password = ""
        @State private var confirmation = ""
        @State private var message: String?
        @State private var busy = false
        @FocusState private var focus: Field?

        private enum Field: Hashable { case email, password, confirmation }

        /// The confirmation agrees with the password, or is not typed yet.
        private var matches: Bool { confirmation.isEmpty || password == confirmation }

        /// The button acts once there is an email, a password long enough, and the two passwords agree.
        private var ready: Bool {
            !email.trimmingCharacters(in: .whitespaces).isEmpty && password.count >= {{t:password.minimum}} && password == confirmation
        }

        var body: some View {
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: {{t:header.spacing}}) {
                    AuthMark()
                    Text({{s:signUp.title}})
                        .font(AuthLook.title)
                        .foregroundStyle(AuthLook.titleColor)
                    Text({{s:signUp.subtitle}})
                        .font(AuthLook.subtitle)
                        .foregroundStyle(AuthLook.subtitleColor)
                }
                .padding(.bottom, {{t:header.below}})
                VStack(spacing: {{t:fields.gap}}) {
                    AuthField({{s:email}}, text: $email, kind: .email)
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }
                    AuthField({{s:signUp.password}}, text: $password, kind: .newPassword)
                        .focused($focus, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focus = .confirmation }
                    AuthField({{s:signUp.confirm}}, text: $confirmation, kind: .newPassword, error: !matches)
                        .focused($focus, equals: .confirmation)
                        .submitLabel(.go)
                        .onSubmit { submit() }
                }
                .padding(.horizontal, {{t:fields.inset}})
                if !matches {
                    Text({{s:signUp.mismatch}})
                        .font(AuthLook.message)
                        .foregroundStyle(AuthLook.danger)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, {{t:fields.inset}})
                        .padding(.top, {{t:hint.above}})
                }
                if let message {
                    Text(message)
                        .font(AuthLook.message)
                        .foregroundStyle(AuthLook.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, {{t:fields.inset}})
                        .padding(.top, {{t:message.above}})
                }
                if signUp != nil {
                    AuthButton({{s:signUp.button}}, enabled: ready, busy: busy, action: submit)
                        .padding(.horizontal, {{t:button.inset}})
                        .padding(.top, {{t:button.above}})
                }
                Spacer()
                if let signInInstead {
                    HStack(spacing: {{t:footer.gap}}) {
                        Text({{s:signUp.footer}})
                            .font(AuthLook.footer)
                            .foregroundStyle(AuthLook.secondaryForeground)
                        Button {
                            signInInstead()
                            AuthLook.impact()
                        } label: {
                            Text({{s:signUp.footerLink}})
                                .font(AuthLook.footerLink)
                                .foregroundStyle(AuthLook.accent)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, {{t:footer.below}})
                }
            }
            .onTapGesture { focus = nil }
        }

        /// Return on the confirmation and the button: creates the account, then asks for its code.
        private func submit() {
            guard ready, !busy, let signUp else { return }
            let address = email.trimmingCharacters(in: .whitespaces)
            focus = nil
            message = nil
            busy = true
            Task {
                do {
                    try await signUp(address, password)
                    created?(address)
                } catch {
                    message = AuthFlow.reason(error)
                }
                busy = false
            }
        }
    }

    #Preview {
        AuthSignUpView(signUp: { _, _ in }, created: { _ in }, signInInstead: {})
    }
    """##
}
