import Foundation
import GraniteAgents
import XCTest
@testable import AuthAgent

/// The package as an app finds it: by its record, with the schema a model is shown and the guide a host prompts with.
final class AuthAgentTests: XCTestCase {
    func testTheRecordIsFoundWithNothingListed() throws {
        let auth = try XCTUnwrap(GraniteRoster.discovered().package("auth"), "the record is in this test binary")
        XCTAssertEqual(auth.module, "AuthAgent")
        XCTAssertEqual(auth.summary, AuthAgent.summary)
    }

    func testTheSchemaIsWhatAModelIsShown() {
        let auth = AnyAgentPackage(AuthAgent.self)
        XCTAssertEqual(auth.schema, .object([
            .init(name: "into", schema: .string, required: false),
            .init(name: "mark", schema: .string, required: false),
            .init(name: "look", schema: .array(.string), required: false),
            .init(name: "strings", schema: .array(.string), required: false),
            .init(name: "tuning", schema: .array(.string), required: false),
            .init(name: "launch", schema: .array(.string), required: false),
            .init(name: "prefix", schema: .string, required: false),
            .init(name: "imports", schema: .array(.string), required: false),
            .init(name: "directory", schema: .string, required: false),
        ]))
        XCTAssertTrue(auth.takesDirectory)
        XCTAssertEqual(Set(auth.fields.keys), ["into", "mark", "look", "strings", "tuning", "launch", "prefix", "imports"],
                       "a note beside every field the model sees")
        XCTAssertEqual(auth.lanes, 2)
        XCTAssertEqual(AuthAgent.makes.map(\.kind), ["view", "support"])
    }

    func testTheGuideNamesEveryRoleKeyAndState() {
        let guide = AnyAgentPackage(AuthAgent.self).guide
        for word in ["AuthFlow(signIn:", "resend:", "pendingEmail:", "mark", "look", "strings", "tuning", "launch", "prefix",
                     "imports", "#Preview", "signIn", "signUp", "forgot", "code reset", "-> auth"] {
            XCTAssertTrue(guide.contains(word), "the guide says \(word)")
        }
        // Every role, key and state is in the guide, so the model never has to guess one.
        for role in LookRoles.all { XCTAssertTrue(guide.contains(role.name), "the guide names the role \(role.name)") }
        for key in StringKeys.all { XCTAssertTrue(guide.contains(key.key + " ("), "the guide names the key \(key.key)") }
        for key in TuningKeys.all { XCTAssertTrue(guide.contains("\(key.key) \(key.fallback)"), "the guide names \(key.key) with its default") }
        // Two example calls: the least, and an app in its own look.
        XCTAssertEqual(guide.components(separatedBy: "{\"").count - 1, 2, "two example calls")
        for example in guide.matches(#"\{"mark".*?\]\}"#) {
            XCTAssertNoThrow(try JSONSerialization.jsonObject(with: Data(example.utf8)), "an example is JSON a host can send: \(example)")
        }
        XCTAssertFalse(guide.contains("Seer"), "no Seer names to copy")
    }

    /// The call as a host makes it: JSON in, the host's folder filled, JSON out naming the files.
    func testACallThroughTheRosterWritesTheFilesItNames() async throws {
        let folder = try Fixture.folder()
        let data = try Data(contentsOf: Fixture.package.appendingPathComponent("Schema/examples/seer.json"))
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["directory"] = folder.path
        let input = try JSONSerialization.data(withJSONObject: object)
        let answer = try await AnyAgentPackage(AuthAgent.self).perform(input, host: AgentHost(directory: folder.path, ask: "the sign-in flow"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: answer) as? [String: Any])
        XCTAssertEqual(json["format"] as? String, "granite-answer/1")
        let result = try JSONDecoder().decode(AuthResult.self, from: answer)
        let views = folder.appendingPathComponent("Components/Auth/Views").path
        XCTAssertEqual(result.path, views + "/AuthFlow.swift")
        XCTAssertEqual(result.paths.count, 11)
        for path in result.paths {
            XCTAssertTrue(path.hasPrefix(views + "/"), path)
            XCTAssertTrue(FileManager.default.fileExists(atPath: path), path)
        }
        XCTAssertEqual(result.views, ["AuthFlow", "AuthSignInView", "AuthSignUpView", "AuthCodeView", "AuthForgotView", "AuthField",
                                      "AuthButton", "AuthMark"])
        XCTAssertEqual(result.made.map(\.name), AuthPlan.names)
        XCTAssertEqual(result.made.map(\.state), Array(repeating: .written, count: 11))
        XCTAssertEqual(result.expected.map(\.name), AuthPlan.names)
        XCTAssertEqual(result.destinations, ["auth", "auth.signup", "auth.code", "auth.forgot"])
        XCTAssertEqual(result.initializers.count, 1)
        XCTAssertTrue(result.initializers[0].hasPrefix("AuthFlow(pendingEmail: String? = nil, signIn: "), result.initializers[0])
        XCTAssertEqual(result.body, "AuthFlow(signIn: { try await account.signIn(email: $0, password: $1) }, "
            + "signUp: { try await account.signUp(email: $0, password: $1) }, verify: { try await account.verify(email: $0, code: $1) }, "
            + "reset: { try await account.reset(email: $0) })")
        XCTAssertTrue(result.notes.contains { $0.contains("`auth.signup -> auth`, `auth.code -> auth`, `auth.forgot -> auth`") }, "\(result.notes)")
        XCTAssertTrue(result.notes.contains { $0.contains("`SeerMark()`") }, "\(result.notes)")
        XCTAssertTrue(result.notes.contains { $0.contains("\"Unauthorized: Invalid login credentials\"") }, "\(result.notes)")
    }

    /// A host over the wire may name its folder only in `AgentHost`: every file lands there all the same.
    func testTheHostsFolderIsUsedWhenTheCallNamesNone() async throws {
        let folder = try Fixture.folder()
        let input = try JSONSerialization.data(withJSONObject: ["mark": "lock.shield"])
        let answer = try await AnyAgentPackage(AuthAgent.self).perform(input, host: AgentHost(directory: folder.path))
        let result = try JSONDecoder().decode(AuthResult.self, from: answer)
        XCTAssertEqual(result.path, folder.appendingPathComponent("Components/Auth/AuthFlow.swift").path)
        XCTAssertEqual(result.destinations, [])
    }

    /// A call it cannot read is refused as the call's to fix, every reason at once, and writes nothing.
    func testARefusedCallSaysEveryReasonAndWritesNothing() async throws {
        let folder = try Fixture.folder()
        let input = try JSONSerialization.data(withJSONObject: [
            "look": ["title = Color.accent"], "strings": ["signIn.titel = \"Hi\""], "tuning": ["mark.size = big"],
            "launch": ["auth = home"], "directory": folder.path,
        ])
        do {
            _ = try await AnyAgentPackage(AuthAgent.self).perform(input, host: AgentHost(directory: folder.path))
            XCTFail("the call is refused")
        } catch {
            let refusal = try XCTUnwrap(AgentRefusal.of(error), "\(error)")
            XCTAssertEqual(refusal.kind, .call)
            XCTAssertEqual(refusal.reasons.count, 4, "\(refusal.reasons)")
        }
        let left = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        XCTAssertEqual(left, [], "nothing is written")
    }

    /// A second call with the same lines writes the same bytes, and says each file is unchanged.
    func testTheSameCallAgainWritesTheSameBytes() throws {
        let folder = try Fixture.folder()
        var input = try Fixture.seer()
        input.directory = folder.path
        let first = try AuthAgent.write(input, note: { _ in }, yield: { _ in })
        let texts = try first.paths.map { try String(contentsOfFile: $0, encoding: .utf8) }
        let second = try AuthAgent.write(input, note: { _ in }, yield: { _ in })
        XCTAssertEqual(second.paths, first.paths)
        XCTAssertEqual(try second.paths.map { try String(contentsOfFile: $0, encoding: .utf8) }, texts)
        XCTAssertEqual(Set(second.made.map(\.state)), [.unchanged])
        // A call with other words rewrites what they are in.
        input.strings = (input.strings ?? []) + ["code.resend = \"Send again\""]
        let third = try AuthAgent.write(input, note: { _ in }, yield: { _ in })
        let rewritten = third.made.filter { $0.state == .rewritten }.map(\.name)
        XCTAssertEqual(rewritten, ["AuthCodeView"])
    }
}

extension String {
    /// Every whole match of `pattern`.
    func matches(_ pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: self, range: NSRange(startIndex..., in: self)).compactMap { Range($0.range, in: self).map { String(self[$0]) } }
    }
}
