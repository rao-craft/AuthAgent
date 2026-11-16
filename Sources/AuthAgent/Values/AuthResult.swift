import Foundation
import GraniteAgents

/// What a call answers, as `granite-answer/1`: the files written, as absolute paths, the root view's initializer and a
/// page body that calls it, the destinations the flow opens for, and what the call made of what it was asked for.
public struct AuthResult: AgentAnswer, Equatable {
    /// The root view's file.
    public var path: String?
    /// Every file written.
    public var paths: [String]
    /// The views written, by type name, the root first.
    public var views: [String]
    /// Each root view's initializer as a line, so the host can write the page body that calls it.
    public var initializers: [String]
    /// A page body that shows the flow, for an account service reached as `account` with the events signIn, signUp,
    /// verify and reset.
    public var body: String
    /// The `-destination` names the flow opens for, by its launch lines: the app's navigation opens the flow's page
    /// for each.
    public var destinations: [String]
    /// One sentence each: what the app has to provide or do, and why.
    public var notes: [String]
    /// Each file written: the views and their support.
    public var made: [AgentMade]
    /// Every part of the flow a call writes.
    public var expected: [AgentExpected]
    /// Nothing is done in part: a call writes the whole flow or nothing.
    public var problems: [AgentProblem]

    public init(path: String?, paths: [String], views: [String], initializers: [String], body: String, destinations: [String],
                notes: [String], made: [AgentMade] = [], expected: [AgentExpected] = [], problems: [AgentProblem] = []) {
        self.path = path; self.paths = paths; self.views = views; self.initializers = initializers; self.body = body
        self.destinations = destinations; self.notes = notes; self.made = made; self.expected = expected; self.problems = problems
    }
}
