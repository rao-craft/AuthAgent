//  WHAT: Every timing, size and symbol the flow's views are drawn with, by key, with its default. A `tuning` line sets
//        one (`mark.turn = 42`); a key no line sets keeps its default. The defaults are the spacing of a sign-in flow
//        drawn by hand (heads at 8, fields inset 42, the button inset 50 and 52 tall); the mark stands still and casts
//        no shadow until a line says otherwise.
//  PIN:  WRITTEN AS A PERSON WRITES IT. Each value lands in the view as SwiftUI spells it (`.tracking(12)`,
//        `.spring(response: 0.38, dampingFraction: 0.88)`, `.presentationDetents([.medium, .large])`), never behind
//        a constant, so the code reads as written by hand.

import Foundation

struct TuningKey: Sendable, Equatable {
    enum Kind: Sendable, Equatable {
        /// Points, seconds or a scale, between the bounds.
        case number(Double, Double)
        /// A whole number between the bounds.
        case count(Int, Int)
        /// `spring 0.38 0.88`, `easeInOut 0.15`, `linear 0.3`, `smooth`, `snappy`, `bouncy`, `none`, or SwiftUI's spelling.
        case animation
        /// An SF Symbol's name.
        case symbol
        /// The heights a sheet rests at: `medium large`, `fraction(0.6)`, `height(320)`.
        case detents
        /// `opacity radius x y`, in the foreground colour, or `none`.
        case shadow
        /// The tap felt under the finger: light, medium, heavy, soft, rigid or none.
        case impact
    }

    let key: String
    let kind: Kind
    /// The default, as a tuning line would write it.
    let fallback: String
    /// One sentence: what it sets.
    let doc: String

    init(_ key: String, _ kind: Kind, _ fallback: String, _ doc: String) {
        self.key = key; self.kind = kind; self.fallback = fallback; self.doc = doc
    }
}

enum TuningKeys {
    static let points = TuningKey.Kind.number(0, 400)
    static let seconds = TuningKey.Kind.number(0, 3_600)

    static let all: [TuningKey] = [
        // Motion and feel.
        .init("swap", .animation, "spring 0.38 0.88", "How one screen gives way to the next: the new one slides in from the trailing edge, Sign In from the leading edge."),
        .init("press", .animation, "easeInOut 0.15", "How the button eases between enabled, disabled and busy."),
        .init("haptic", .impact, "light", "The tap felt on the button and on the footer's link."),
        // The mark.
        .init("mark.size", points, "100", "The mark's width and height."),
        .init("mark.turn", seconds, "0", "Seconds the mark takes to turn once, linear and never reversing; 0 keeps it still."),
        .init("mark.shadow", .shadow, "none", "The mark's shadow in the primary colour: `opacity radius x y`, like `0.3 3 1 1`."),
        .init("mark.padding", points, "24", "Space above and below the mark, inside the head."),
        .init("mark.below", points, "8", "More space under the mark, before the title."),
        // Sign In and Sign Up.
        .init("header.spacing", points, "8", "Space between the parts of every head: the mark or glyph, the title and the line under it."),
        .init("header.below", points, "42", "Space from Sign In's and Sign Up's head to the first field."),
        .init("fields.gap", points, "12", "Space between fields."),
        .init("fields.inset", points, "42", "The inset from each side of the fields, the link and the messages, and of the reset sheet's head and field."),
        .init("field.horizontal", points, "16", "A field's padding at each side."),
        .init("field.vertical", points, "12", "A field's padding above and below."),
        .init("field.line", points, "1", "The thickness of the line under a field."),
        .init("field.lineInset", points, "8", "The line's inset from each side of its field."),
        .init("link.above", points, "8", "Space from the last field to \"Forgot password?\"."),
        .init("message.above", points, "12", "Space above what went wrong."),
        .init("hint.above", points, "6", "Space from the confirmation to the mismatch hint."),
        .init("button.above", points, "28", "Space above the button, on every screen."),
        .init("button.inset", points, "50", "The button's inset from each side on Sign In, Sign Up and the reset sheet."),
        .init("button.height", points, "52", "The button's height."),
        .init("button.radius", points, "4", "The corner radius of the button's border."),
        .init("button.border", points, "1", "The width of the button's border."),
        .init("button.spinner", .number(0.1, 4), "0.85", "The scale of the spinner that stands in for the label while busy."),
        .init("footer.gap", points, "4", "Space between the footer's question and its link."),
        .init("footer.below", points, "32", "Space under the footer."),
        .init("password.minimum", .count(1, 128), "6", "The fewest characters Sign Up takes for a password."),
        // The one-time code.
        .init("code.length", .count(4, 10), "6", "How many digits the code has; the last one sends it."),
        .init("code.tracking", .number(0, 60), "12", "Space between the code's digits."),
        .init("code.glyph", .symbol, "envelope.badge", "The symbol at the head of the code screen."),
        .init("code.glyphBelow", points, "12", "More space under the code screen's glyph, before its title."),
        .init("code.lineSpacing", .number(0, 40), "3", "Space between the lines of where the code went."),
        .init("code.headerBelow", points, "40", "Space from the code screen's head to the code field."),
        .init("code.inset", points, "24", "The inset from each side of the code screen's head, field, message and button."),
        .init("code.fieldPadding", points, "16", "The code field's padding above and below."),
        .init("code.fieldRadius", points, "12", "The corner radius of the code field's fill."),
        .init("code.gap", points, "16", "Space from the code field to its caption."),
        .init("code.backAbove", points, "16", "Space above \"Use a different email\"."),
        // The reset sheet.
        .init("forgot.glyph", .symbol, "lock.rotation", "The symbol at the head of the reset sheet."),
        .init("forgot.glyphBelow", points, "8", "More space under the reset sheet's glyph, before its instruction."),
        .init("forgot.lineSpacing", .number(0, 40), "3", "Space between the lines of the instruction."),
        .init("forgot.headerBelow", points, "40", "Space from the reset sheet's head to its field."),
        .init("forgot.closeGlyph", .symbol, "xmark", "The symbol of the sheet's close button."),
        .init("forgot.detents", .detents, "medium large", "The heights the reset sheet rests at."),
    ]

    /// The key a tuning line names, in any case.
    static func named(_ word: String) -> TuningKey? {
        let lower = word.lowercased()
        return all.first { $0.key.lowercased() == lower }
    }

    /// The keys of the part `key` would be in, for a refusal.
    static func neighbours(of key: String) -> [String] {
        let head = (key.split(separator: ".").first.map(String.init) ?? key).lowercased()
        let same = all.filter { ($0.key.split(separator: ".").first.map(String.init) ?? $0.key).lowercased() == head }
        return (same.isEmpty ? all : same).map(\.key)
    }
}
