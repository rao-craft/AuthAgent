//  WHAT: A launch line read: the destination a launch names (`-destination auth.signup`) and the state the flow opens
//        in for it, as if the person had gone there.
//
//            auth = signIn
//            auth.signup = signUp
//            auth.code = code "name@example.com"         the code screen for that email, after Sign Up
//            auth.reset = code reset "name@example.com"  the code screen after a reset was asked for
//            auth.forgot = forgot                       Sign In with the reset sheet up
//
//  PIN:  THE FLOW ONLY. The app's navigation opens the page that shows the flow for these destinations; the line
//        says what the flow itself shows once it is up.

import Foundation

struct LaunchState: Sendable, Equatable {
    enum Step: Sendable, Equatable {
        case signIn, signUp, forgot
        /// The code screen for `email` (none: the flow's `pendingEmail`, or empty); `reset` for its reset form.
        case code(email: String?, reset: Bool)
    }

    let destination: String
    let step: Step
}

enum LaunchLine {
    static let states = "signIn, signUp, forgot, or code with an email (`code \"name@example.com\"`, `code reset \"name@example.com\"`)"

    static func parse(_ line: String) throws(LineRefusal) -> LaunchState {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = KeyLine.split(text) else {
            throw LineRefusal(field: "launch", line: line, reason: "a launch line is `destination = state`, like `auth.signup = signUp`")
        }
        let destination = parsed.key
        guard destination.range(of: #"^[A-Za-z0-9_][A-Za-z0-9_.-]*$"#, options: .regularExpression) != nil else {
            throw LineRefusal(field: "launch", line: line, reason: "`\(destination)` is not a destination name: letters, digits, dots and dashes, as `-destination auth.signup` gives it")
        }
        let value = parsed.value
        let head = value.prefix { !$0.isWhitespace && $0 != "\"" }
        var rest = value.dropFirst(head.count).trimmingCharacters(in: .whitespaces)
        switch head.lowercased() {
        case "signin", "sign-in":
            guard rest.isEmpty else { throw LineRefusal(field: "launch", line: line, reason: "signIn takes nothing after it") }
            return LaunchState(destination: destination, step: .signIn)
        case "signup", "sign-up":
            guard rest.isEmpty else { throw LineRefusal(field: "launch", line: line, reason: "signUp takes nothing after it") }
            return LaunchState(destination: destination, step: .signUp)
        case "forgot":
            guard rest.isEmpty else { throw LineRefusal(field: "launch", line: line, reason: "forgot takes nothing after it: it opens Sign In with the reset sheet up") }
            return LaunchState(destination: destination, step: .forgot)
        case "code":
            var reset = false
            if rest.lowercased().hasPrefix("reset") {
                reset = true
                rest = String(rest.dropFirst("reset".count)).trimmingCharacters(in: .whitespaces)
            }
            if rest.isEmpty { return LaunchState(destination: destination, step: .code(email: nil, reset: reset)) }
            guard rest.hasPrefix("\""), let email = KeyLine.unquote(rest) else {
                throw LineRefusal(field: "launch", line: line, reason: "code takes the email in quotes, like `code \"name@example.com\"`, and `reset` before it for the reset form")
            }
            guard !email.isEmpty, !email.contains(where: \.isNewline) else {
                throw LineRefusal(field: "launch", line: line, reason: "the email is empty: `code \"name@example.com\"`")
            }
            return LaunchState(destination: destination, step: .code(email: email, reset: reset))
        default:
            throw LineRefusal(field: "launch", line: line, reason: "`\(head.isEmpty ? value : String(head))` is not a state; a launch opens " + states)
        }
    }
}
