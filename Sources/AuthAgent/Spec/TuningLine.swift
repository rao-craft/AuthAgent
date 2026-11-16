//  WHAT: A tuning line read: the key it sets and its value, as SwiftUI spells it.
//
//            swap = spring 0.38 0.88
//            mark.turn = 42
//            code.tracking = 12
//            forgot.detents = medium large

import Foundation

struct TuningAssignment: Sendable, Equatable {
    let key: TuningKey
    let value: TuningValue
}

enum TuningLine {
    static func parse(_ line: String) throws(LineRefusal) -> TuningAssignment {
        let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = KeyLine.split(text) else {
            throw LineRefusal(field: "tuning", line: line, reason: "a tuning line is `key = value`, like `mark.turn = 42` or `swap = spring 0.38 0.88`")
        }
        guard let key = TuningKeys.named(parsed.key) else {
            throw LineRefusal(field: "tuning", line: line, reason: "`\(parsed.key)` is not a key; the keys are " + TuningKeys.neighbours(of: parsed.key).joined(separator: ", "))
        }
        switch TuningValueReader.read(parsed.value, for: key) {
        case .success(let value): return TuningAssignment(key: key, value: value)
        case .failure(let reason): throw LineRefusal(field: "tuning", line: line, reason: reason.text)
        }
    }
}
