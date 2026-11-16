import Foundation
import GraniteAgents

/// What a call can say instead of writing.
public enum AuthError: Error, Equatable, CustomStringConvertible, AgentRefusing {
    /// Every one of them is the call's to fix.
    public var refusal: AgentRefusal {
        switch self {
        case .problems(let reasons): return AgentRefusal(.call, reasons)
        }
    }

    /// Every problem with the call at once, each naming its field, its line and what the field takes: nothing was
    /// written.
    case problems([String])

    public var description: String {
        switch self {
        case .problems(let reasons):
            let count = reasons.count == 1 ? "1 problem" : "\(reasons.count) problems"
            return "\(count) with the call, so nothing was written:\n" + reasons.map { "- \($0)" }.joined(separator: "\n")
        }
    }
}
