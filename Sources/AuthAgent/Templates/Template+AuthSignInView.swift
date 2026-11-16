//  WHAT: The template of `AuthSignInView.swift`: the mark and a greeting over an email and a password, the link to the
//        reset sheet, the outlined button, and the footer to Sign Up.

extension Template {
    static let authSignInView = ##"""
    import SwiftUI

    /// Sign In: the app's mark and a greeting over an email and a password, a link to reset the password, the button,
    /// and a way to Sign Up. What `signIn` throws is shown under the fields.
    struct AuthSignInView: View {
        /// Signs in; nil leaves the button out.
        var signIn: (@MainActor (_ email: String, _ password: String) async throws -> Void)?
        /// Opens the reset sheet; nil leaves the link out.
        var forgot: (() -> Void)?
        /// Goes to Sign Up; nil leaves the footer out.
        var create: (() -> Void)?

        @State private var email = ""
        @State private var password = ""
        @State private var message: String?
        @State private var busy = false
        @FocusState private var focus: Field?

        private enum Field: Hashable { case email, password }

        /// The button acts once the trimmed email and the password are both there.
        private var ready: Bool {
            !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
        }

        var body: some View {
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: {{t:header.spacing}}) {
                    AuthMark()
                    Text({{s:signIn.title}})
                        .font(AuthLook.title)
                        .foregroundStyle(AuthLook.titleColor)
                    Text({{s:signIn.subtitle}})
                        .font(AuthLook.subtitle)
                        .foregroundStyle(AuthLook.subtitleColor)
                }
                .padding(.bottom, {{t:header.below}})
                VStack(spacing: {{t:fields.gap}}) {
                    AuthField({{s:email}}, text: $email, kind: .email)
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }
                    AuthField({{s:signIn.password}}, text: $password, kind: .password)
                        .focused($focus, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { submit() }
                }
                .padding(.horizontal, {{t:fields.inset}})
                if let forgot {
                    HStack {
                        Spacer()
                        Button {
                            forgot()
                        } label: {
                            Text({{s:signIn.forgot}})
                                .font(AuthLook.link)
                                .foregroundStyle(AuthLook.accent)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, {{t:fields.inset}})
                    .padding(.top, {{t:link.above}})
                }
                if let message {
                    Text(message)
                        .font(AuthLook.message)
                        .foregroundStyle(AuthLook.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, {{t:fields.inset}})
                        .padding(.top, {{t:message.above}})
                }
                if signIn != nil {
                    AuthButton({{s:signIn.button}}, enabled: ready, busy: busy, action: submit)
                        .padding(.horizontal, {{t:button.inset}})
                        .padding(.top, {{t:button.above}})
                }
                Spacer()
                if let create {
                    HStack(spacing: {{t:footer.gap}}) {
                        Text({{s:signIn.footer}})
                            .font(AuthLook.footer)
                            .foregroundStyle(AuthLook.secondaryForeground)
                        Button {
                            create()
                            AuthLook.impact()
                        } label: {
                            Text({{s:signIn.footerLink}})
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

        /// Return on the password field and the button: signs in with the trimmed email.
        private func submit() {
            guard ready, !busy, let signIn else { return }
            let address = email.trimmingCharacters(in: .whitespaces)
            focus = nil
            //@if signIn.check
            guard AuthFlow.isEmail(address), password.count >= {{t:password.minimum}} else {
                message = {{s:signIn.refusedInvalid}}
                return
            }
            //@endif
            message = nil
            busy = true
            Task {
                do {
                    try await signIn(address, password)
                } catch {
                    message = Self.refused(error)
                }
                busy = false
            }
        }

        //@if signIn.refused
        /// A refused sign-in as the screen says it: the prefix and the reason, never the prefix twice.
        private static func refused(_ error: Error) -> String {
            let reason = AuthFlow.reason(error)
            let prefix = {{s:signIn.refused}}
            return reason.hasPrefix(prefix) ? reason : prefix + reason
        }
        //@else
        /// A refused sign-in as the screen says it: the reason it was given.
        private static func refused(_ error: Error) -> String {
            AuthFlow.reason(error)
        }
        //@endif
    }

    #Preview {
        AuthSignInView(signIn: { _, _ in }, forgot: {}, create: {})
    }
    """##
}
