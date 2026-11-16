//  WHAT: The template of `AuthStep.swift`: which screen the flow shows.

extension Template {
    static let authStep = ##"""
    /// Which screen the sign-in flow shows; the reset sheet is held apart, over Sign In.
    enum AuthStep: Hashable, Sendable {
        /// Sign In.
        case signIn
        /// Sign Up.
        case signUp
        /// The one-time code sent to `email`; `reset` when it confirms a reset rather than a new account.
        case code(email: String, reset: Bool)
    }
    """##
}
