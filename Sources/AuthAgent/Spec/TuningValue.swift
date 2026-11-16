//  WHAT: A tuning value read for its kind and written as SwiftUI spells it:
//
//            52                    → 52
//            spring 0.38 0.88      → .spring(response: 0.38, dampingFraction: 0.88)
//            easeInOut 0.15        → .easeInOut(duration: 0.15)
//            envelope.badge        → "envelope.badge"
//            medium large          → [.medium, .large]
//            0.3 3 1 1             → color: Color.primary.opacity(0.3), radius: 3, x: 1, y: 1
//            light                 → .light
//
//        SwiftUI's own spelling is read too (`.spring(response: 0.38, dampingFraction: 0.88)`, `[.medium, .large]`).
//  PIN:  A VALUE OUT OF ITS BOUNDS IS REFUSED, with the form the key takes and its default as the example.

import Foundation

struct TuningValue: Sendable, Equatable {
    /// What the template writes.
    let swift: String
    /// The number, for a number or a count.
    let number: Double?
    /// Whether it says "nothing": a still mark, no shadow, no tap, no animation.
    let isNone: Bool

    init(swift: String, number: Double? = nil, isNone: Bool = false) {
        self.swift = swift; self.number = number; self.isNone = isNone
    }
}

/// Why a tuning value cannot be read, with the form its key takes.
struct TuningReason: Error, Sendable, Equatable {
    let text: String
    init(_ text: String) { self.text = text }
}

enum TuningValueReader {
    /// `text` read as `key` takes it, or the reason it cannot be.
    static func read(_ text: String, for key: TuningKey) -> Result<TuningValue, TuningReason> {
        let value = text.trimmingCharacters(in: .whitespaces)
        switch key.kind {
        case .number(let low, let high):
            guard let number = Double(value), number.isFinite, number >= low, number <= high else {
                return .failure(TuningReason("`\(key.key)` takes a number from \(SwiftLiteral.number(low)) to \(SwiftLiteral.number(high)), like `\(key.fallback)`"))
            }
            return .success(TuningValue(swift: SwiftLiteral.number(number), number: number, isNone: number == 0))
        case .count(let low, let high):
            guard let count = Int(value), count >= low, count <= high else {
                return .failure(TuningReason("`\(key.key)` takes a whole number from \(low) to \(high), like `\(key.fallback)`"))
            }
            return .success(TuningValue(swift: String(count), number: Double(count)))
        case .animation:
            return animation(value).map { .success($0) }
                ?? .failure(TuningReason("`\(key.key)` takes an animation: `spring <response> <damping>` like `spring 0.38 0.88`, `easeInOut`, `easeIn`, `easeOut` or `linear` with seconds like `easeInOut 0.15`, `smooth`, `snappy`, `bouncy`, or `none`"))
        case .symbol:
            let name = value.hasPrefix("\"") && value.hasSuffix("\"") && value.count > 1 ? String(value.dropFirst().dropLast()) : value
            guard SwiftName.isSymbolName(name) else {
                return .failure(TuningReason("`\(key.key)` takes an SF Symbol's name, like `\(key.fallback)`"))
            }
            return .success(TuningValue(swift: SwiftLiteral.quoted(name)))
        case .detents:
            return detents(value).map { .success($0) }
                ?? .failure(TuningReason("`\(key.key)` takes the heights a sheet rests at, once each: `medium`, `large`, `fraction(0.6)`, `height(320)`, like `medium large`"))
        case .shadow:
            return shadow(value).map { .success($0) }
                ?? .failure(TuningReason("`\(key.key)` takes `opacity radius x y`, like `0.3 3 1 1` (opacity from 0 to 1), or `none`"))
        case .impact:
            let styles = ["light", "medium", "heavy", "soft", "rigid"]
            if value.lowercased() == "none" { return .success(TuningValue(swift: "", isNone: true)) }
            guard let style = styles.first(where: { $0 == value.lowercased() }) else {
                return .failure(TuningReason("`\(key.key)` takes light, medium, heavy, soft, rigid or none"))
            }
            return .success(TuningValue(swift: "." + style))
        }
    }

    // MARK: - Animations

    private static let curves = ["easeInOut", "easeIn", "easeOut", "linear"]

    static func animation(_ text: String) -> TuningValue? {
        let number = #"([0-9]*\.?[0-9]+)"#
        if let match = groups(text, #"^\.?spring\(\s*response:\s*"# + number + #"\s*,\s*dampingFraction:\s*"# + number + #"\s*\)$"#) {
            return spring(match[0], match[1])
        }
        if let match = groups(text, #"^\.?(easeInOut|easeIn|easeOut|linear)\(\s*duration:\s*"# + number + #"\s*\)$"#) {
            return curve(match[0], match[1])
        }
        let words = text.split(whereSeparator: { $0 == " " || $0 == "," || $0 == "\t" }).map(String.init)
        guard let head = words.first?.lowercased() else { return nil }
        switch (head, words.count) {
        case ("none", 1): return TuningValue(swift: "nil", isNone: true)
        case ("smooth", 1), ("snappy", 1), ("bouncy", 1), ("default", 1): return TuningValue(swift: "." + head)
        case ("spring", 3): return spring(words[1], words[2])
        case (_, 2): return curve(words[0], words[1])
        default: return nil
        }
    }

    private static func spring(_ response: String, _ damping: String) -> TuningValue? {
        guard let r = Double(response), let d = Double(damping), r > 0, r <= 10, d > 0, d <= 2 else { return nil }
        return TuningValue(swift: ".spring(response: \(SwiftLiteral.number(r)), dampingFraction: \(SwiftLiteral.number(d)))")
    }

    private static func curve(_ name: String, _ seconds: String) -> TuningValue? {
        guard let curve = curves.first(where: { $0.lowercased() == name.lowercased() }), let s = Double(seconds), s > 0, s <= 60 else { return nil }
        return TuningValue(swift: ".\(curve)(duration: \(SwiftLiteral.number(s)))")
    }

    // MARK: - Detents

    static func detents(_ text: String) -> TuningValue? {
        var rest = text.trimmingCharacters(in: .whitespaces)
        if rest.hasPrefix("["), rest.hasSuffix("]") { rest = String(rest.dropFirst().dropLast()) }
        let pattern = #"(?i)\.?(medium|large|fraction\s*\(\s*([0-9]*\.?[0-9]+)\s*\)|height\s*\(\s*([0-9]*\.?[0-9]+)\s*\))"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(rest.startIndex..., in: rest)
        var found: [String] = []
        for match in expression.matches(in: rest, range: range) {
            guard let whole = Range(match.range(at: 1), in: rest) else { return nil }
            let word = rest[whole].lowercased()
            if word == "medium" || word == "large" {
                found.append("." + word)
            } else if word.hasPrefix("fraction"), let r = Range(match.range(at: 2), in: rest), let f = Double(rest[r]), f > 0, f <= 1 {
                found.append(".fraction(\(SwiftLiteral.number(f)))")
            } else if word.hasPrefix("height"), let r = Range(match.range(at: 3), in: rest), let h = Double(rest[r]), h >= 40, h <= 2_000 {
                found.append(".height(\(SwiftLiteral.number(h)))")
            } else {
                return nil
            }
        }
        // Nothing but the detents, commas and spaces.
        let leftover = expression.stringByReplacingMatches(in: rest, range: range, withTemplate: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: " ,\t"))
        guard leftover.isEmpty, !found.isEmpty, Set(found).count == found.count else { return nil }
        return TuningValue(swift: "[" + found.joined(separator: ", ") + "]")
    }

    // MARK: - Shadows

    static func shadow(_ text: String) -> TuningValue? {
        let words = text.split(whereSeparator: { $0 == " " || $0 == "," || $0 == "\t" }).map(String.init)
        if words.count == 1, ["none", "0"].contains(words[0].lowercased()) { return TuningValue(swift: "", isNone: true) }
        guard words.count == 4, let opacity = Double(words[0]), let radius = Double(words[1]), let x = Double(words[2]), let y = Double(words[3]),
              opacity >= 0, opacity <= 1, radius >= 0, radius <= 100, abs(x) <= 100, abs(y) <= 100 else { return nil }
        if opacity == 0 { return TuningValue(swift: "", isNone: true) }
        let parts = ["color: Color.primary.opacity(\(SwiftLiteral.number(opacity)))", "radius: \(SwiftLiteral.number(radius))",
                     "x: \(SwiftLiteral.number(x))", "y: \(SwiftLiteral.number(y))"]
        return TuningValue(swift: parts.joined(separator: ", "))
    }

    /// The captures of `pattern` when it matches the whole of `text`.
    private static func groups(_ text: String, _ pattern: String) -> [String]? {
        guard let expression = try? NSRegularExpression(pattern: pattern),
              let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        return (1..<match.numberOfRanges).compactMap { Range(match.range(at: $0), in: text).map { String(text[$0]) } }
    }
}
