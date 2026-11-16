//  WHAT: Every word the flow shows, by key, with its English default and the screen it is on. A `strings` line sets one
//        (`signIn.title = "Welcome to Seer"`); a key no line sets says its default. The one source of the words the
//        templates write, of what a strings line may name, and of the guide's and the reference's key lists.
//  PIN:  NATURAL ENGLISH BY DEFAULT. A call that sets no words still writes screens a person can read; two keys are
//        empty by default and say so: `signIn.refused` (no prefix on a refused sign-in) and `signIn.invalid` (no check
//        on the screen before `signIn` is asked).

import Foundation

struct StringKey: Sendable, Equatable {
    /// The key on a strings line: `signIn.title`.
    let key: String
    /// What the screen says when no line sets it.
    let english: String
    /// One sentence: where it shows.
    let doc: String

    init(_ key: String, _ english: String, _ doc: String) {
        self.key = key; self.english = english; self.doc = doc
    }

    /// The screen it is on, for the reference: the part of the key before its dot.
    var screen: String {
        switch key.split(separator: ".").first.map(String.init) ?? key {
        case "signIn": return "Sign In"
        case "signUp": return "Sign Up"
        case "code": return "One-time code"
        case "forgot": return "Reset Password"
        default: return "Every screen"
        }
    }
}

enum StringKeys {
    static let all: [StringKey] = [
        .init("email", "Email", "The email field's placeholder, on every screen that asks for it."),
        .init("signIn.title", "Welcome back", "Sign In's title, under the mark."),
        .init("signIn.subtitle", "Sign in to continue", "The line under Sign In's title."),
        .init("signIn.password", "Password", "Sign In's password field."),
        .init("signIn.forgot", "Forgot password?", "The link under the fields that opens the reset sheet."),
        .init("signIn.button", "Sign In", "Sign In's button."),
        .init("signIn.footer", "Don't have an account?", "The footer's question on Sign In."),
        .init("signIn.footerLink", "Create one", "The footer's link to Sign Up."),
        .init("signIn.refused", "", "Put before the reason a sign-in was refused: `Unauthorized: ` reads \"Unauthorized: Invalid login credentials\"; never written twice."),
        .init("signIn.invalid", "", "With words here, a malformed email or a password shorter than `password.minimum` is refused on the screen with them, after `signIn.refused`, and `signIn` is not asked."),
        .init("signUp.title", "Create account", "Sign Up's title, under the mark."),
        .init("signUp.subtitle", "It only takes a minute", "The line under Sign Up's title."),
        .init("signUp.password", "Password", "Sign Up's password field."),
        .init("signUp.confirm", "Confirm password", "Sign Up's field that repeats the password."),
        .init("signUp.mismatch", "Passwords do not match", "Under the fields while the confirmation differs."),
        .init("signUp.button", "Create Account", "Sign Up's button."),
        .init("signUp.footer", "Already have an account?", "The footer's question on Sign Up."),
        .init("signUp.footerLink", "Sign in", "The footer's link back to Sign In."),
        .init("code.title", "Verify your email", "The code screen's title after Sign Up."),
        .init("code.resetTitle", "Check your email", "The code screen's title after a reset was asked for."),
        .init("code.sent", "We sent a code to", "Where the code went; the email follows on the next line."),
        .init("code.placeholder", "Code", "The code field's placeholder."),
        .init("code.hint", "Didn't receive it? Check your spam folder.", "The caption under the code field."),
        .init("code.button", "Verify", "The code screen's button after Sign Up."),
        .init("code.resetButton", "Verify & Reset", "The code screen's button after a reset was asked for."),
        .init("code.back", "Use a different email", "The link back to the screen the code came from."),
        .init("code.resend", "Resend code", "The link that sends the code again, drawn when the flow has `resend`."),
        .init("forgot.title", "Reset Password", "The reset sheet's title, in its bar."),
        .init("forgot.instruction", "Enter your email and we'll send you a reset code.", "The reset sheet's instruction."),
        .init("forgot.button", "Send Reset Code", "The reset sheet's button."),
        .init("forgot.sent", "Check your email for a reset link.", "Said in the sheet once the reset is sent, when the flow has no code screen to go to."),
        .init("forgot.close", "Close", "What VoiceOver says for the sheet's close button."),
    ]

    /// The key a strings line names, in any case.
    static func named(_ word: String) -> StringKey? {
        let lower = word.lowercased()
        return all.first { $0.key.lowercased() == lower }
    }

    /// The keys of the screen `key` would be on, for a refusal.
    static func neighbours(of key: String) -> [String] {
        let head = (key.split(separator: ".").first.map(String.init) ?? key).lowercased()
        let same = all.filter { ($0.key.split(separator: ".").first.map(String.init) ?? $0.key).lowercased() == head }
        return (same.isEmpty ? all : same).map(\.key)
    }
}
