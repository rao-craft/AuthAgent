import Foundation
import XCTest
@testable import AuthAgent

/// The Seer call against the measure's scorecard: every `code` item of area `auth` (and the design and data items the
/// flow carries), with the scorecard's own patterns, over the Swift the call writes; and every quoted string of the
/// original's four screens, word for word. The patterns are copied here from `task/seer/scorecard.json`, so the suite
/// needs nothing outside this repository.
final class SeerConformanceTests: XCTestCase {
    /// An item's check: each of `all` matches, and one of `any` when there are any.
    struct Item {
        let id: String
        let all: [String]
        var any: [String] = []
    }

    static let items: [Item] = [
        Item(id: "B-design-2", all: [], any: [#"design:\s*\.serif"#, #"fontDesign\(\.serif\)"#]),
        Item(id: "B-design-3", all: [#"\.linear\(duration:\s*42(\.0)?\)"#, #"repeatForever\(autoreverses:\s*false\)"#]),
        Item(id: "B-auth-3", all: [#"Forgot password\?"#, #"Don.t have an account\?"#, #"Create one\."#]),
        Item(id: "B-auth-4", all: [#"response:\s*0\.38,\s*dampingFraction:\s*0\.88"#]),
        Item(id: "B-auth-5", all: ["Unauthorized: ", "SecureField"]),
        Item(id: "B-auth-8", all: [#"Password \(min 6 characters\)"#, "Confirm password", "Passwords do not match"]),
        Item(id: "B-auth-9", all: ["Create Account", #"Already have an account\?"#, #"Sign in\."#]),
        Item(id: "B-auth-13", all: [#"\.numberPad"#, #"(tracking|kerning)\(12(\.0)?\)"#]),
        Item(id: "B-auth-14", all: [#"Didn.t receive it\? Check your spam folder\."#, "Use a different email", "Check your email", "Verify & Reset"]),
        Item(id: "B-auth-15", all: [#"envelope\.badge"#]),
        Item(id: "B-auth-18", all: [#"lock\.rotation"#, #"Enter your email and we.ll send you a reset code\."#, "Send Reset Code"]),
        Item(id: "B-auth-19", all: [#"presentationDetents\(\[\s*\.(medium,\s*\.large|large,\s*\.medium)\s*\]\)"#]),
        Item(id: "B-data-1", all: ["UserDefaults", "\"destination\""]),
        Item(id: "B-data-4", all: ["Unauthorized: Invalid login credentials"]),
    ]

    /// Every string in quotes on the original's Sign In, Sign Up, code and reset screens (asset and symbol names aside).
    static let quoted = [
        "Welcome to Seer", "Sign in to continue", "Email", "Password", "Forgot password?", "Sign In", "Don't have an account?",
        "Create one.", "Create account", "Start your journey", "Password (min 6 characters)", "Confirm password",
        "Passwords do not match", "Create Account", "Already have an account?", "Sign in.", "Check your email",
        "Verify your email", "We sent a 6-digit code to", "Verify & Reset", "Verify Email", "code",
        "Didn't receive it? Check your spam folder.", "Use a different email",
        "Enter your email and we'll send you a reset code.", "Send Reset Code", "Reset Password",
        // What the screens read once launched, and what a refused sign-in says.
        "ada@seer.social", "Unauthorized: Invalid login credentials",
    ]

    func testEveryCodeItemOfTheScorecardHolds() throws {
        let code = try Fixture.code(Fixture.seer())
        for item in Self.items {
            for pattern in item.all {
                XCTAssertNotNil(code.range(of: pattern, options: .regularExpression), "\(item.id): \(pattern)")
            }
            if !item.any.isEmpty {
                XCTAssertTrue(item.any.contains { code.range(of: $0, options: .regularExpression) != nil }, "\(item.id): one of \(item.any)")
            }
        }
    }

    func testEveryQuotedStringOfTheFourScreensIsWritten() throws {
        let code = try Fixture.code(Fixture.seer())
        for words in Self.quoted { XCTAssertTrue(code.contains("\"" + words) || code.contains(words), "\(words)") }
        // As Swift spells them in a literal: the screen shows exactly these, quotes and all.
        for literal in [#""Don't have an account?""#, #""We sent a 6-digit code to\n\(email)""#, #""Unauthorized: Invalid login credentials""#,
                        #""Enter your email and we'll send you a reset code.""#, #""Verify & Reset""#] {
            XCTAssertTrue(code.contains(literal), literal)
        }
    }
}
