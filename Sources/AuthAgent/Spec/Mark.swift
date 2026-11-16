//  WHAT: The app's mark at the head of Sign In and Sign Up: a view the app has, named by the Swift that makes it
//        (`BrandMark()`, `Image("Logo").resizable()`), or an SF Symbol by name (`seal.fill`). The kit sizes it, turns it
//        and shadows it (`mark.size`, `mark.turn`, `mark.shadow`); a call that names none draws `person.crop.circle`.
//  PIN:  THE MARK IS NEVER TINTED. A view the app gives is drawn as it draws itself; only a symbol takes a colour.

import Foundation

enum Mark: Sendable, Equatable {
    case symbol(String)
    case view(String)

    static let fallback = Mark.symbol("person.crop.circle")

    static func read(_ text: String?) throws(LineRefusal) -> Mark {
        guard let raw = text?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return fallback }
        if raw.contains("(") {
            guard raw.first.map({ $0.isLetter || $0 == "_" || $0 == "." }) == true else {
                throw LineRefusal(field: "mark", line: raw, reason: "a mark is the Swift that makes a view, like `BrandMark()`, or an SF Symbol's name, like `seal.fill`")
            }
            return .view(raw)
        }
        let name = raw.hasPrefix("\"") && raw.hasSuffix("\"") && raw.count > 1 ? String(raw.dropFirst().dropLast()) : raw
        guard SwiftName.isSymbolName(name) else {
            throw LineRefusal(field: "mark", line: raw, reason: "a mark is the Swift that makes a view, like `BrandMark()` (with its parentheses), or an SF Symbol's name, like `seal.fill`")
        }
        return .symbol(name)
    }
}
