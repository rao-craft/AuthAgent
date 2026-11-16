//  WHAT: Why one line of a call cannot be read: the field it is in, the line as the call wrote it, and what the field
//        takes instead. Every one a call has is gathered before anything is written.

import Foundation

struct LineRefusal: Error, Sendable, Equatable, CustomStringConvertible {
    /// The field the line is in: `look`, `strings`, `tuning`, `launch`, `mark`.
    let field: String
    let line: String
    let reason: String

    var description: String { "\(field) `\(line)`: \(reason)" }
}
