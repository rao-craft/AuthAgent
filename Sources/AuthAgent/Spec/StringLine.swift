//  WHAT: A strings line read: the key it sets and the words, exactly as the call gave them.
//
//            signIn.title = "Welcome to Seer"
//            code.sent = "We sent a 6-digit code to"
//            signIn.refused = "Unauthorized: "          the space inside the quotes is kept
//            signIn.footerLink = Create one.            unquoted words are taken as they stand, trimmed
//
//        In quotes, `\"` is a quote, `\\` a backslash and `\n` a line break.

import Foundation

struct StringAssignment: Sendable, Equatable {
    let key: StringKey
    let words: String
}

enum StringLine {
    static func parse(_ line: String) throws(LineRefusal) -> StringAssignment {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = KeyLine.split(text) else {
            throw LineRefusal(field: "strings", line: line, reason: "a strings line is `key = \"words\"`, like `signIn.title = \"Welcome back\"`")
        }
        guard let key = StringKeys.named(parsed.key) else {
            throw LineRefusal(field: "strings", line: line, reason: "`\(parsed.key)` is not a key; the keys are " + StringKeys.neighbours(of: parsed.key).joined(separator: ", "))
        }
        guard let words = KeyLine.unquote(parsed.value) else {
            throw LineRefusal(field: "strings", line: line, reason: "the words are not closed: one pair of quotes around them, `\(key.key) = \"\(key.english.isEmpty ? "…" : key.english)\"`, with `\\\"` for a quote inside")
        }
        return StringAssignment(key: key, words: words)
    }
}
