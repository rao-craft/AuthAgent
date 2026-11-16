//  WHAT: AuthLaunch.swift: where the flow opens, read once when it first appears. A launch with `-destination <name>`
//        (how UI tests and screenshots reach a screen with no tap) opens the state its launch line names, the reset
//        sheet already up where it says `forgot`; any other launch opens on the code screen for an email still waiting
//        for its code, else on Sign In.
//  PIN:  THE APP'S NAVIGATION OPENS THE PAGE. These names only say what the flow shows once its page is up.

import Foundation

enum LaunchEmitter {
    static func emit(_ call: AuthCall) -> String {
        var lines = [
            "import Foundation",
            "",
            "/// Where the sign-in flow opens. A launch with `-destination <name>` opens the screen its name maps to, as if the",
            "/// person had gone there, the way UI tests and screenshots reach a screen with no tap.",
            "enum \(call.prefix)AuthLaunch {",
            "    /// The launch's destination: `-destination \(call.launch.first?.destination ?? "auth")` on the launch line.",
            "    static var destination: String? { UserDefaults.standard.string(forKey: \"destination\") }",
            "",
        ]
        if call.launch.isEmpty {
            lines += [
                "    /// Where the flow opens: on the code screen for `pendingEmail`, else on Sign In.",
                "    static func opening(pendingEmail: String? = nil) -> (step: \(call.prefix)AuthStep, forgot: Bool) {",
            ]
        } else {
            let names = call.launch.map(\.destination).joined(separator: ", ")
            lines += [
                "    /// Where the flow opens: as the launch's destination says when it is one of the flow's (\(names)), else on the",
                "    /// code screen for `pendingEmail`, else on Sign In. The reset sheet is up when the second value says so.",
                "    static func opening(pendingEmail: String? = nil) -> (step: \(call.prefix)AuthStep, forgot: Bool) {",
                "        switch destination {",
            ]
            for state in call.launch {
                lines.append("        case \(SwiftLiteral.quoted(state.destination)): return \(opening(state.step))")
            }
            lines += ["        default: break", "        }"]
        }
        lines += [
            "        if let pendingEmail { return (.code(email: pendingEmail, reset: false), false) }",
            "        return (.signIn, false)",
            "    }",
            "}",
        ]
        return lines.joined(separator: "\n") + "\n"
    }

    /// The tuple a launch state opens with.
    static func opening(_ step: LaunchState.Step) -> String {
        switch step {
        case .signIn: return "(.signIn, false)"
        case .signUp: return "(.signUp, false)"
        case .forgot: return "(.signIn, true)"
        case .code(let email, let reset):
            let address = email.map(SwiftLiteral.quoted) ?? "pendingEmail ?? \"\""
            return "(.code(email: \(address), reset: \(reset)), false)"
        }
    }
}
