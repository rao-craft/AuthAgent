//  WHAT: A look line read: the role it names and the Swift that role reads.
//
//            title = Font.brandTitle
//            subtitle = Font.brandNote2.italic()
//            field = Font.system(size: 16, design: .serif)
//            accent = Color.accent
//            accent = accent                      a bare name is read off the role's type: `.accent`
//
//        The right side is Swift, checked by the parse of the file it lands in and by the app's build.
//  PIN:  A LINE THAT IS NOT UNDERSTOOD IS REFUSED WITH THE REASON AND THE ROLES, so the model fixes the line it is
//        told about instead of guessing again.

import Foundation

struct LookAssignment: Sendable, Equatable {
    let role: LookRole
    /// The Swift the role's member returns.
    let expression: String
}

enum LookLine {
    static func parse(_ line: String) throws(LineRefusal) -> LookAssignment {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = KeyLine.split(text) else {
            throw LineRefusal(field: "look", line: line, reason: "a look line is `role = expression`, like `title = Font.brandTitle`")
        }
        guard let role = LookRoles.named(parsed.key) else {
            throw LineRefusal(field: "look", line: line, reason: "`\(parsed.key)` is not a look role; " + Self.rolesInWords)
        }
        var value = parsed.value
        guard !value.isEmpty else {
            throw LineRefusal(field: "look", line: line, reason: "`\(role.name)` has no value: name the app's \(role.kind == .font ? "font, like `\(role.name) = Font.brandTitle`" : "colour, like `\(role.name) = Color.accent`")")
        }
        if value.hasPrefix("\"") {
            throw LineRefusal(field: "look", line: line, reason: "a look value is Swift, not words in quotes: `\(role.name) = \(role.kind == .font ? "Font.brandTitle" : "Color.accent")`")
        }
        if value.hasPrefix("#") {
            throw LineRefusal(field: "look", line: line, reason: "`\(value)` is a hex code; name the app's colour (`\(role.name) = Color.accent`) or write it in Swift (`Color(red: 0.68, green: 0.56, blue: 0.38)`)")
        }
        let fontLike = ["Font.", "Font(", ".system(", "UIFont", "NSFont"].contains { value.hasPrefix($0) }
        let colorLike = ["Color.", "Color(", "UIColor", "NSColor"].contains { value.hasPrefix($0) }
        if role.kind == .font, colorLike {
            throw LineRefusal(field: "look", line: line, reason: "`\(role.name)` is type, and `\(value)` is a colour: give it a font, like `Font.brandTitle` or `Font.system(size: 16, design: .serif)`")
        }
        if role.kind == .color, fontLike {
            throw LineRefusal(field: "look", line: line, reason: "`\(role.name)` is a colour, and `\(value)` is a font: give it a colour, like `Color.accent`")
        }
        if SwiftName.isBareMember(value) { value = "." + value }
        return LookAssignment(role: role, expression: value)
    }

    /// Every role, by kind, for a refusal and the guide.
    static var rolesInWords: String {
        "colours: " + LookRoles.colors.map(\.name).joined(separator: ", ") + "; type: " + LookRoles.fonts.map(\.name).joined(separator: ", ")
    }
}
