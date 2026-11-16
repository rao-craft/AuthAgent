import Foundation
@testable import AuthAgent

enum Fixture {
    /// A folder of its own for one test, removed with the process's temporary files.
    static func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("auth-\(UUID().uuidString.prefix(8))", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// The package's folder, read from this file's place in it (`Tests/AuthAgentTests/Support/Fixture.swift`).
    static let package = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()

    /// An example call in `Schema/examples`, as a host sends it.
    static func example(_ name: String) throws -> AuthAgent.Input {
        let data = try Data(contentsOf: package.appendingPathComponent("Schema/examples/\(name).json"))
        return try JSONDecoder().decode(AuthAgent.Input.self, from: data)
    }

    /// The call that reproduces Seer's sign-in flow: `Schema/examples/seer.json`, the one the one-shot prompt copies.
    static func seer() throws -> AuthAgent.Input { try example("seer") }

    /// The call for another app: `Schema/examples/shelf.json`.
    static func shelf() throws -> AuthAgent.Input { try example("shelf") }

    /// Every file a call writes, by file name, made without the disk.
    static func emitted(_ input: AuthAgent.Input) throws -> [String: String] {
        let files = try AuthPlan.files(for: AuthCall.read(input))
        return Dictionary(uniqueKeysWithValues: files.map { ($0.file, $0.text) })
    }

    /// Every file a call writes, joined: what a check over the app's Swift reads.
    static func code(_ input: AuthAgent.Input) throws -> String {
        try emitted(input).sorted { $0.key < $1.key }.map(\.value).joined(separator: "\n")
    }

    /// The text of the file `name` among `paths`.
    static func text(_ paths: [String], _ name: String) throws -> String {
        guard let path = paths.first(where: { $0.hasSuffix("/" + name) }) else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: name])
        }
        return try String(contentsOfFile: path, encoding: .utf8)
    }

    /// The reasons a call is refused with, or none when it is read.
    static func refusals(_ input: AuthAgent.Input) -> [String] {
        do {
            _ = try AuthCall.read(input)
            return []
        } catch {
            if case .problems(let reasons) = error { return reasons }
            return []
        }
    }
}
