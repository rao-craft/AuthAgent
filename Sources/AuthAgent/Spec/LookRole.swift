//  WHAT: The look roles the flow's views read (its colours and its type) and what each is for. A `look` line maps a
//        role to the app's own name (`title = Font.brandTitle`); a role no line maps reads the system's value, so
//        the output builds in any app. The one source of `AuthLook`, of what a look line may name, and of the guide's
//        and the reference's role lists.
//  PIN:  ONE TABLE. The emitter, the parser, the guide and the tests all read it, so a role added here is a member of
//        `AuthLook`, a word a line may use and a documented default at once.

import Foundation

struct LookRole: Sendable, Equatable {
    enum Kind: String, Sendable, Equatable {
        case color, font

        /// The member's type in `AuthLook`.
        var swiftType: String { self == .color ? "Color" : "Font" }
    }

    /// The word on a look line and the member of `AuthLook`: `title`, `accent`.
    let name: String
    let kind: Kind
    /// One sentence: what it paints.
    let doc: String
    /// What it reads when no line maps it: one expression, or the lines of a body that returns one.
    let fallback: [String]

    init(_ name: String, _ kind: Kind, _ doc: String, _ fallback: String...) {
        self.name = name; self.kind = kind; self.doc = doc; self.fallback = fallback
    }
}

enum LookRoles {
    static let all: [LookRole] = [
        // Colours.
        .init("background", .color, "Behind the flow, edge to edge; the reset sheet keeps the system's sheet background.",
              "#if os(macOS)", "return Color(nsColor: .windowBackgroundColor)", "#else", "return Color(uiColor: .systemBackground)", "#endif"),
        .init("titleColor", .color, "Sign In's and Sign Up's titles, and the reset sheet's title in its bar.", "Color.primary"),
        .init("subtitleColor", .color, "The line under Sign In's and Sign Up's titles.", "Color.secondary"),
        .init("foreground", .color, "The code screen's title.", "Color.primary"),
        .init("secondaryForeground", .color, "The footer's question, the glyphs, where the code went and the reset sheet's instruction.", "Color.secondary"),
        .init("tertiaryForeground", .color, "The caption under the code field.",
              "#if os(macOS)", "return Color(nsColor: .tertiaryLabelColor)", "#else", "return Color(uiColor: .tertiaryLabel)", "#endif"),
        .init("accent", .color, "\"Forgot password?\", the footer's link and the reset sheet's close button.", "Color.accentColor"),
        .init("danger", .color, "What went wrong, and the mismatch hint.", "Color.red.opacity(0.85)"),
        .init("line", .color, "The line under a field.", "Color.primary.opacity(0.2)"),
        .init("lineError", .color, "The line under a field that is wrong: a confirmation that does not match.", "Color.red.opacity(0.4)"),
        .init("control", .color, "The outlined button's label and border while it can act.", "Color.primary"),
        .init("controlFaint", .color, "The outlined button's label and border while it cannot act or is busy.", "Color.primary.opacity(0.3)"),
        .init("spinner", .color, "The spinner that stands in for the button's label while busy.", "Color.primary"),
        .init("codeFill", .color, "The rounded fill behind the code field.", "Color.secondary.opacity(0.08)"),
        // Type.
        .init("title", .font, "Sign In's and Sign Up's titles.", ".title2"),
        .init("subtitle", .font, "The line under Sign In's and Sign Up's titles; `.italic()` on the font slants it.", ".subheadline"),
        .init("field", .font, "What is typed into a field, and its placeholder.", ".body"),
        .init("link", .font, "\"Forgot password?\" and \"Use a different email\".", ".footnote.weight(.medium)"),
        .init("message", .font, "What went wrong on Sign In, Sign Up and the code screen, and the mismatch hint.", ".footnote"),
        .init("button", .font, "The outlined button's label.", ".headline"),
        .init("footer", .font, "The footer's question: \"Don't have an account?\".", ".subheadline"),
        .init("footerLink", .font, "The footer's link: \"Create one\", \"Sign in\".", ".subheadline.weight(.semibold)"),
        .init("glyph", .font, "The symbol at the head of the code screen and the reset sheet.", ".system(size: 44, weight: .light)"),
        .init("codeTitle", .font, "The code screen's title.", ".system(size: 28, weight: .semibold)"),
        .init("codeBody", .font, "Where the code went, under the code screen's title.", ".system(size: 15, weight: .regular)"),
        .init("codeField", .font, "The digits of the code as they are typed, and its placeholder.", ".system(size: 32, weight: .semibold, design: .monospaced)"),
        .init("caption", .font, "The caption under the code field.", ".system(size: 12)"),
        .init("sheetTitle", .font, "The reset sheet's title, centred in its bar.", ".headline"),
        .init("instruction", .font, "The reset sheet's instruction.", ".body"),
        .init("sheetMessage", .font, "What went wrong in the reset sheet.", ".footnote"),
    ]

    static var colors: [LookRole] { all.filter { $0.kind == .color } }
    static var fonts: [LookRole] { all.filter { $0.kind == .font } }

    /// The role a look line's key names, in any case.
    static func named(_ word: String) -> LookRole? {
        let lower = word.lowercased()
        return all.first { $0.name.lowercased() == lower }
    }
}
