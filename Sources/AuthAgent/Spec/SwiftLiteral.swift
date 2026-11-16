//  WHAT: Text written into the app as Swift: a string literal with every character that would end it or start an
//        interpolation escaped, and a number in the shortest form a person would write it.
//  PIN:  A CALL'S WORDS NEVER BECOME CODE. A backslash is escaped first, so `\(` in a string is two characters on the
//        screen and never an interpolation.

import Foundation

enum SwiftLiteral {
    /// `text` as the inside of a Swift string literal: `Don't` stays, `"` and `\` are escaped, a line break is `\n`.
    static func escaped(_ text: String) -> String {
        var out = ""
        for scalar in text.unicodeScalars {
            switch scalar {
            case "\\": out += "\\\\"
            case "\"": out += "\\\""
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default:
                if scalar.value < 0x20 || scalar.value == 0x7F {
                    out += "\\u{\(String(scalar.value, radix: 16))}"
                } else {
                    out.unicodeScalars.append(scalar)
                }
            }
        }
        return out
    }

    /// `text` as a Swift string literal, quotes and all.
    static func quoted(_ text: String) -> String { "\"" + escaped(text) + "\"" }

    /// `value` as a person writes it in Swift: `52`, not `52.0`; `0.3`, not `0.30`.
    static func number(_ value: Double) -> String {
        if value == value.rounded(), abs(value) < 1_000_000_000 { return String(Int(value)) }
        return String(describing: value)
    }
}
