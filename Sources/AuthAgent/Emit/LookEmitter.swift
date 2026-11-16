//  WHAT: AuthLook.swift: one enum of static members the flow's views read for every colour and font, each the app's own
//        name where a look line mapped it and the system's where none did, and the tap they give under the finger.
//  PIN:  THE APP'S SWIFT AS WRITTEN. The kit's names carry the call's prefix here, never by a rename after: a mapped
//        name is the app's and stays as the line wrote it.
//  PIN:  COMPUTED, NEVER STORED. Every member is a computed `static var`, so the file holds no state and builds in Swift 5
//        and Swift 6 language modes alike, whatever the app's names are.

import Foundation

enum LookEmitter {
    static func emit(_ call: AuthCall) -> String {
        let haptic = call.tuning["haptic"].flatMap { $0.isNone ? nil : $0.swift }
        var lines = ["import SwiftUI"]
        if haptic != nil { lines += ["#if os(iOS)", "import UIKit", "#endif"] }
        lines += call.imports.map { "import \($0)" }
        lines += [
            "",
            "/// The look of the sign-in flow: each role reads the app's own name where the call gave one, and the system's where",
            "/// it gave none, so the views build in any app.",
            "enum \(call.prefix)AuthLook {",
            "    // MARK: Colours",
            "",
        ]
        for role in LookRoles.colors { lines += member(role, mapped: call.look[role.name]) + [""] }
        lines += ["    // MARK: Type", ""]
        for role in LookRoles.fonts { lines += member(role, mapped: call.look[role.name]) + [""] }
        lines += ["    // MARK: Feel", ""]
        if let haptic {
            lines += [
                "    /// The tap felt on the button and the footer's link.",
                "    @MainActor",
                "    static func impact() {",
                "        #if os(iOS)",
                "        UIImpactFeedbackGenerator(style: \(haptic)).impactOccurred()",
                "        #endif",
                "    }",
            ]
        } else {
            lines += [
                "    /// The tap felt on the button and the footer's link: none, as the call asked.",
                "    @MainActor",
                "    static func impact() {}",
            ]
        }
        lines.append("}")
        return lines.joined(separator: "\n") + "\n"
    }

    /// One member: the role's sentence, then the call's Swift or the system's value.
    static func member(_ role: LookRole, mapped: String?) -> [String] {
        let type = role.kind.swiftType
        if let mapped {
            return ["    /// \(role.doc) The call's `\(mapped)`.", "    static var \(role.name): \(type) { \(mapped) }"]
        }
        if role.fallback.count == 1 {
            return ["    /// \(role.doc)", "    static var \(role.name): \(type) { \(role.fallback[0]) }"]
        }
        return ["    /// \(role.doc)", "    static var \(role.name): \(type) {"] + role.fallback.map { "        " + $0 } + ["    }"]
    }
}
