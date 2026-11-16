//  WHAT: The template of `AuthFlow.swift`, the root view a page shows: it holds which screen is up and whether the reset
//        sheet is, and moves between them on the call's spring as the closures return.

extension Template {
    static let authFlow = ##"""
    import SwiftUI

    /// The sign-in flow: Sign In, Sign Up, the one-time code and the reset sheet, moving between them on its own. The
    /// app's account service does the work through the closures, and what a closure throws is shown under its fields;
    /// a closure that is nil leaves its control out.
    ///
    ///     AuthFlow(signIn: { try await account.signIn(email: $0, password: $1) },
    ///              signUp: { try await account.signUp(email: $0, password: $1) },
    ///              verify: { try await account.verify(email: $0, code: $1) },
    ///              reset: { try await account.reset(email: $0) })
    struct AuthFlow: View {
        /// Signs in with an email and a password.
        var signIn: (@MainActor (_ email: String, _ password: String) async throws -> Void)?
        /// Creates an account; once it returns, the code screen asks for the code sent to the email.
        var signUp: (@MainActor (_ email: String, _ password: String) async throws -> Void)?
        /// Checks the code sent to an email, after Sign Up or a reset.
        var verify: (@MainActor (_ email: String, _ code: String) async throws -> Void)?
        /// Sends the code again; nil leaves the link out.
        var resend: (@MainActor (_ email: String) async throws -> Void)?
        /// Sends a reset code to an email; nil leaves the link to the reset sheet out.
        var reset: (@MainActor (_ email: String) async throws -> Void)?

        @State private var step: AuthStep
        @State private var forgot: Bool

        /// - Parameter pendingEmail: an email still waiting for its code: the flow opens on the code screen for it.
        init(pendingEmail: String? = nil,
             signIn: (@MainActor (_ email: String, _ password: String) async throws -> Void)? = nil,
             signUp: (@MainActor (_ email: String, _ password: String) async throws -> Void)? = nil,
             verify: (@MainActor (_ email: String, _ code: String) async throws -> Void)? = nil,
             resend: (@MainActor (_ email: String) async throws -> Void)? = nil,
             reset: (@MainActor (_ email: String) async throws -> Void)? = nil) {
            self.signIn = signIn
            self.signUp = signUp
            self.verify = verify
            self.resend = resend
            self.reset = reset
            let opening = AuthLaunch.opening(pendingEmail: pendingEmail)
            _step = State(initialValue: opening.step)
            _forgot = State(initialValue: opening.forgot)
        }

        var body: some View {
            ZStack {
                switch step {
                case .signIn:
                    AuthSignInView(signIn: signIn,
                                   forgot: reset == nil ? nil : { forgot = true },
                                   create: signUp == nil ? nil : { step = .signUp })
                        .transition(Self.back)
                case .signUp:
                    AuthSignUpView(signUp: signUp,
                                   created: verify == nil ? nil : { step = .code(email: $0, reset: false) },
                                   signInInstead: { step = .signIn })
                        .transition(Self.forward)
                case .code(let email, let isReset):
                    AuthCodeView(email: email, reset: isReset, verify: verify, resend: resend,
                                 back: { step = isReset || signUp == nil ? .signIn : .signUp })
                        .transition(Self.forward)
                }
            }
            .animation({{t:swap}}, value: step)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AuthLook.background)
            .sheet(isPresented: $forgot) {
                AuthForgotView(reset: reset,
                               sent: verify == nil ? nil : { email in
                                   forgot = false
                                   step = .code(email: email, reset: true)
                               })
                    .presentationDetents({{t:forgot.detents}})
                    .presentationDragIndicator(.visible)
            }
        }

        /// A screen that goes forward: in from the trailing edge as the old one leaves by the leading edge.
        private static var forward: AnyTransition {
            .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity))
        }

        /// Sign In, coming back: in from the leading edge.
        private static var back: AnyTransition {
            .asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity))
        }

        /// What went wrong, as a person reads it: the error's own description where it has one.
        static func reason(_ error: Error) -> String {
            if let described = (error as? LocalizedError)?.errorDescription { return described }
            // A Swift error of the app's that describes itself (`refused("Invalid login credentials")`) is said as it
            // describes itself; a system error by its localized description.
            if (error as NSError).domain == String(reflecting: type(of: error)) { return String(describing: error) }
            return error.localizedDescription
        }
        //@if signIn.check

        /// Whether `text` reads as an email: a name, an `@`, and a domain with a dot in it.
        static func isEmail(_ text: String) -> Bool {
            text.range(of: #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#, options: .regularExpression) != nil
        }
        //@endif
    }

    #Preview {
        AuthFlow(signIn: { _, _ in }, signUp: { _, _ in }, verify: { _, _ in }, reset: { _ in })
    }
    """##
}
