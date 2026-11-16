//  WHAT: The one form every list field takes (`look`, `strings`, `tuning`, `launch`): a key, `=`, a value.
//
//            title = Font.brandTitle
//            signIn.title = "Welcome to Seer"
//            swap = spring 0.38 0.88
//            auth.code = code "ada@seer.social"
//
//        The key is cut at the first `=` that stands outside quotes and brackets and is not part of `==`, `!=`,
//        `<=` or `>=`; both sides are trimmed.
//  PIN:  A LINE WITHOUT A KEY IS REFUSED WITH THE FORM IT TAKES, never guessed at.

import Foundation

enum KeyLine {
    struct Parsed: Sendable, Equatable {
        let key: String
        let value: String
    }

    /// `line` cut at its first top-level `=`; nil when it has none, or nothing before it.
    static func split(_ line: String) -> Parsed? {
        let characters = Array(line)
        var depth = 0, quoted = false, escaped = false
        for index in characters.indices {
            let character = characters[index]
            if quoted {
                if escaped { escaped = false } else if character == "\\" { escaped = true } else if character == "\"" { quoted = false }
                continue
            }
            switch character {
            case "\"": quoted = true
            case "[", "(", "{": depth += 1
            case "]", ")", "}": depth = max(0, depth - 1)
            case "=" where depth == 0:
                let before = index > 0 ? characters[index - 1] : " "
                let after = index + 1 < characters.count ? characters[index + 1] : " "
                if "=!<>".contains(before) || after == "=" { continue }
                let key = String(characters[..<index]).trimmingCharacters(in: .whitespaces)
                let value = String(characters[(index + 1)...]).trimmingCharacters(in: .whitespaces)
                return key.isEmpty ? nil : Parsed(key: key, value: value)
            default: break
            }
        }
        return nil
    }

    /// Whether `key` is a dotted name, as every key is: `title`, `signIn.title`, `auth.signup`.
    static func isKey(_ key: String) -> Bool {
        key.range(of: #"^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_-]+)*$"#, options: .regularExpression) != nil
    }

    /// The text inside a quoted value with its escapes read (`\"`, `\\`, `\n`, `\t`), or the value as it stands when it
    /// is not quoted. Nil when a quote is opened and never closed, or when text follows the closing quote.
    static func unquote(_ value: String) -> String? {
        guard value.hasPrefix("\"") else { return value }
        var text = "", escaped = false, closed = false
        for character in value.dropFirst() {
            if closed {
                if character.isWhitespace { continue }
                return nil
            }
            if escaped {
                switch character {
                case "n": text.append("\n")
                case "t": text.append("\t")
                default: text.append(character)
                }
                escaped = false
            } else if character == "\\" {
                escaped = true
            } else if character == "\"" {
                closed = true
            } else {
                text.append(character)
            }
        }
        return closed ? text : nil
    }
}
