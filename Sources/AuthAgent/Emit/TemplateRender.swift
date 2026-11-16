//  WHAT: A template made into the app's file: the blocks the call did not ask for dropped, each `{{…}}` filled with the
//        call's value, the kit's types renamed with the call's prefix. Conditions are comment lines:
//
//            //@if mark.turns || mark.shadow        a flag of the call (`AuthCall.flags`); `!flag` negates
//            //@else
//            //@endif
//
//        and values are `{{s:signIn.title}}` (a word as a Swift literal), `{{e:code.sent}}` (the same without its
//        quotes), `{{t:button.height}}` (a tuning value as SwiftUI spells it) and `{{mark}}`.
//  PIN:  A MARKER IS A LINE OF ITS OWN and never reaches the app; a value the call has no entry for is a fault of the
//        template, caught by the tests before any call is made.

import Foundation

enum TemplateRender {
    enum Failure: Error, Equatable, CustomStringConvertible {
        case unbalanced(String)
        case unknown(String)

        var description: String {
            switch self {
            case .unbalanced(let why): return "a template's blocks do not balance: \(why)"
            case .unknown(let name): return "a template asks for {{\(name)}}, which no call fills"
            }
        }
    }

    /// `source` with every block whose condition is false dropped, the marker lines gone and every value filled.
    static func render(_ source: String, flags: Set<String>, values: [String: String]) throws -> String {
        var output: [Substring] = []
        // Each open block: whether its branch is kept, and whether the block as a whole sits in a kept branch.
        var stack: [(keeping: Bool, parent: Bool)] = []
        var keeping = true
        for line in source.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("//@if ") {
                let condition = holds(String(trimmed.dropFirst(6)), flags: flags)
                stack.append((keeping && condition, keeping))
                keeping = keeping && condition
            } else if trimmed == "//@else" {
                guard let top = stack.popLast() else { throw Failure.unbalanced("//@else without //@if") }
                stack.append((top.parent && !top.keeping, top.parent))
                keeping = top.parent && !top.keeping
            } else if trimmed == "//@endif" {
                guard let top = stack.popLast() else { throw Failure.unbalanced("//@endif without //@if") }
                keeping = top.parent
            } else if keeping {
                output.append(line)
            }
        }
        guard stack.isEmpty else { throw Failure.unbalanced("\(stack.count) //@if without //@endif") }
        return try fill(tidy(output.map(String.init)), values: values)
    }

    /// `text` with each `{{name}}` replaced by its value.
    static func fill(_ text: String, values: [String: String]) throws -> String {
        guard let expression = try? NSRegularExpression(pattern: #"\{\{([a-z]+:)?([A-Za-z0-9.]+)\}\}"#) else { return text }
        var out = ""
        var cursor = text.startIndex
        for match in expression.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
            guard let whole = Range(match.range, in: text) else { continue }
            let name = String(text[whole].dropFirst(2).dropLast(2))
            guard let value = values[name] else { throw Failure.unknown(name) }
            out += text[cursor..<whole.lowerBound]
            out += value
            cursor = whole.upperBound
        }
        out += text[cursor...]
        return out
    }

    /// The lines as a file: no trailing spaces, no run of blank lines and no blank line against a brace (where a
    /// dropped block leaves them), one newline at the end.
    static func tidy(_ lines: [String]) -> String {
        var kept: [String] = []
        for (index, raw) in lines.enumerated() {
            var line = raw
            while line.last == " " || line.last == "\t" { line.removeLast() }
            if line.isEmpty {
                let next = lines[(index + 1)...].first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                let afterOpening = kept.last.map { $0.hasSuffix("{") } ?? true
                let beforeClosing = next.map { $0.trimmingCharacters(in: .whitespaces).hasPrefix("}") } ?? true
                if kept.last?.isEmpty == true || afterOpening || beforeClosing { continue }
            }
            kept.append(line)
        }
        return kept.joined(separator: "\n") + "\n"
    }

    /// `a || b && !c`: `&&` binds tighter than `||`; a name holds when it is in `flags`.
    static func holds(_ condition: String, flags: Set<String>) -> Bool {
        condition.components(separatedBy: "||").contains { any in
            any.components(separatedBy: "&&").allSatisfy { term in
                let word = term.trimmingCharacters(in: .whitespaces)
                return word.hasPrefix("!") ? !flags.contains(String(word.dropFirst())) : flags.contains(word)
            }
        }
    }

    /// `text` with each name in `names` (a whole word) given `prefix`: `AuthFlow` → `KitAuthFlow`.
    static func prefixing(_ text: String, names: [String], prefix: String) -> String {
        guard !prefix.isEmpty, !names.isEmpty else { return text }
        let pattern = "(?<![A-Za-z0-9_])(" + names.sorted { $0.count > $1.count }.map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|") + ")(?![A-Za-z0-9_])"
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return expression.stringByReplacingMatches(in: text, range: range, withTemplate: NSRegularExpression.escapedTemplate(for: prefix) + "$1")
    }
}
