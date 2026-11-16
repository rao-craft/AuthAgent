import Foundation

/// What a run says as it goes.
public enum AuthFrame: Sendable {
    /// The call was read: how many lines it gave, and how many files it writes.
    case read(lines: Int, files: Int)
    /// The files are written.
    case written(AuthResult)

    public var result: AuthResult? {
        if case .written(let result) = self { return result }
        return nil
    }
}
