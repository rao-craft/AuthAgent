import Foundation
import GraniteAgents
import XCTest
@testable import AuthAgent

/// The output built as apps build it, only with `AUTH_BUILD=1` (a few minutes): the Seer call, the least call and
/// another app's call (a prefix and a design module) written by the agent into one package beside stand-ins for what
/// the rest of each app writes (DesignAgent's names, the mark, an account service, the page with the answer's body).
/// The package builds for the Mac with no warning in any of its files, its `Check` opens every launch destination and
/// draws each, and it builds for `generic/platform=iOS Simulator`. The Seer call is built twice: in Swift 6, as a
/// package would, and in Swift 5, as the generated apps are. Nothing boots a simulator.
final class AuthBuildTests: XCTestCase {
    func testTheOutputBuildsForTheMacAndTheIOSSimulator() async throws {
        guard ProcessInfo.processInfo.environment["AUTH_BUILD"] == "1" else { throw XCTSkip("AUTH_BUILD=1 builds the output") }
        // Inside the package's own build folder: ignored by git, and the build products stay between runs.
        let root = Fixture.package.appendingPathComponent(".build/auth-apps", isDirectory: true)
        let sources = root.appendingPathComponent("Sources", isDirectory: true)
        try? FileManager.default.removeItem(at: sources)
        try FileManager.default.createDirectory(at: sources, withIntermediateDirectories: true)
        try BuildApps.package.write(to: root.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)

        // Each app's kit, written by the agent itself (Seer's through the roster, as a host calls it, its answer kept
        // beside the package), and the rest of the app beside it.
        let seerFolder = sources.appendingPathComponent("Seer").path
        var call = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: Fixture.package
            .appendingPathComponent("Schema/examples/seer.json"))) as? [String: Any])
        call["directory"] = seerFolder
        let data = try await AnyAgentPackage(AuthAgent.self).perform(JSONSerialization.data(withJSONObject: call),
                                                                      host: AgentHost(directory: seerFolder, ask: "the sign-in flow"))
        try data.write(to: root.appendingPathComponent("seer.answer.json"))
        let answer = try JSONDecoder().decode(AuthResult.self, from: data)
        var seerFive = try Fixture.seer()
        seerFive.directory = sources.appendingPathComponent("SeerFive").path
        _ = try AuthAgent.write(seerFive, note: { _ in }, yield: { _ in })
        let least = AuthAgent.Input(directory: sources.appendingPathComponent("Least").path)
        _ = try AuthAgent.write(least, note: { _ in }, yield: { _ in })
        var shelf = try Fixture.shelf()
        shelf.directory = sources.appendingPathComponent("Shelf").path
        _ = try AuthAgent.write(shelf, note: { _ in }, yield: { _ in })
        let apps: [(String, String)] = [
            ("Seer/App.swift", BuildApps.seer(body: answer.body, sendable: true, check: "SeerCheck")),
            ("SeerFive/App.swift", BuildApps.seer(body: answer.body, sendable: false, check: "SeerFiveCheck")),
            ("Least/App.swift", BuildApps.least),
            ("Shelf/App.swift", BuildApps.shelf),
            ("ShelfDesign/Design.swift", BuildApps.shelfDesign),
            ("Check/main.swift", BuildApps.check),
        ]
        for (path, text) in apps {
            let url = sources.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try text.write(to: url, atomically: true, encoding: .utf8)
        }

        // The Mac: builds, with no warning in any file of the package's (the kits' or the stand-ins').
        let mac = try BuildApps.run(["swift", "build", "--package-path", root.path], in: root)
        XCTAssertEqual(mac.status, 0, mac.tail)
        XCTAssertEqual(mac.warnings(under: sources.path), [], "no warning in the apps' files")
        // Every destination opens where its launch line says, and every screen draws.
        let check = try BuildApps.run(["swift", "run", "--package-path", root.path, "Check"], in: root)
        XCTAssertEqual(check.status, 0, check.tail)
        XCTAssertTrue(check.output.contains("CHECK PASSED"), check.tail)
        // The iOS Simulator, as the generated apps build: generic, so no simulator is booted.
        let iOS = try BuildApps.run(["xcodebuild", "-scheme", "AuthApps", "-destination", "generic/platform=iOS Simulator",
                                     "-derivedDataPath", root.appendingPathComponent("dd").path,
                                     "-skipPackagePluginValidation", "-skipMacroValidation", "build"], in: root)
        XCTAssertEqual(iOS.status, 0, iOS.tail)
        XCTAssertTrue(iOS.output.contains("** BUILD SUCCEEDED **"), iOS.tail)
        XCTAssertEqual(iOS.warnings(under: sources.path), [], "no warning in the apps' files on iOS")
    }
}

/// The package the build test writes, and the parts of each app that are not the kit's.
enum BuildApps {
    static let package = """
        // swift-tools-version:6.0
        import PackageDescription

        let package = Package(
            name: "AuthApps",
            platforms: [.iOS(.v17), .macOS(.v14)],
            products: [.library(name: "AuthApps", targets: ["Seer", "SeerFive", "Least", "Shelf"])],
            targets: [
                .target(name: "Seer", swiftSettings: [.swiftLanguageMode(.v6)]),
                .target(name: "SeerFive", swiftSettings: [.swiftLanguageMode(.v5)]),
                .target(name: "Least", swiftSettings: [.swiftLanguageMode(.v6)]),
                .target(name: "ShelfDesign", swiftSettings: [.swiftLanguageMode(.v6)]),
                .target(name: "Shelf", dependencies: ["ShelfDesign"], swiftSettings: [.swiftLanguageMode(.v6)]),
                .executableTarget(name: "Check", dependencies: ["Seer", "SeerFive", "Least", "Shelf"],
                                  swiftSettings: [.swiftLanguageMode(.v6)]),
            ]
        )

        """

    /// Seer's side: DesignAgent's names and the mark as stand-ins, the account service as GraniteAgent writes its events
    /// (a Sendable type in Swift 6, a plain class in Swift 5), the page with the answer's `body`, and its check.
    static func seer(body: String, sendable: Bool, check: String) -> String {
        """
        import SwiftUI

        // What DesignAgent and AssetsAgent write in the app.
        extension Color {
            static var accent: Color { Color(red: 0xAE / 255, green: 0x90 / 255, blue: 0x60 / 255) }
        }

        extension Font {
            static var brandTitle: Font { .system(size: 24, weight: .regular, design: .serif) }
            static var brandNote2: Font { .system(size: 16, weight: .light, design: .serif) }
        }

        struct SeerMark: View {
            var body: some View { Circle().fill(Color.gray) }
        }

        /// The account service's events, as GraniteAgent writes them.
        final class AccountService\(sendable ? ": Sendable" : "") {
            func signIn(email: String, password: String) async throws {}
            func signUp(email: String, password: String) async throws {}
            func verify(email: String, code: String) async throws {}
            func reset(email: String) async throws {}
        }

        /// The page that shows the flow, with the answer's body word for word.
        struct AuthPage: View {
            let account = AccountService()

            var body: some View {
                \(body)
            }
        }

        public enum \(check) {
            /// Each destination opens where its launch line says, and the page draws in each.
            @MainActor public static func run() -> [String] {
                var failures: [String] = []
                let expected: [(String, AuthStep, Bool)] = [
                    ("auth", .signIn, false), ("auth.signup", .signUp, false),
                    ("auth.code", .code(email: "ada@seer.social", reset: false), false), ("auth.forgot", .signIn, true),
                ]
                for (name, step, forgot) in expected {
                    UserDefaults.standard.register(defaults: ["destination": name])
                    let opening = AuthLaunch.opening()
                    if opening.step != step || opening.forgot != forgot { failures.append("\(check) \\(name) opens \\(opening)") }
                    // As the app's gate shows it: the page in a NavigationStack with a title, which the flow's bar hides.
                    let gate = NavigationStack { AuthPage().navigationTitle("Sign In") }
                    if ImageRenderer(content: gate.frame(width: 393, height: 852)).cgImage == nil {
                        failures.append("\(check) \\(name) does not draw")
                    }
                }
                return failures
            }
        }

        """
    }

    /// The least call's side: nothing of the app's at all, and a page with no service.
    static let least = """
        import SwiftUI

        public enum LeastCheck {
            /// Opens on Sign In, or on the code screen for an email still waiting; draws either way.
            @MainActor public static func run() -> [String] {
                var failures: [String] = []
                if AuthLaunch.opening().step != .signIn { failures.append("Least opens \\(AuthLaunch.opening())") }
                if AuthLaunch.opening(pendingEmail: "name@example.com").step != .code(email: "name@example.com", reset: false) {
                    failures.append("Least does not open on the pending email")
                }
                for flow in [AuthFlow(), AuthFlow(pendingEmail: "name@example.com")] {
                    if ImageRenderer(content: flow.frame(width: 393, height: 852)).cgImage == nil { failures.append("Least does not draw") }
                }
                return failures
            }
        }

        """

    /// Another app: its design module, its account service with a resend, and a page with every closure.
    static let shelf = """
        import SwiftUI
        import ShelfDesign

        final class Library: Sendable {
            func signIn(email: String, password: String) async throws {}
            func signUp(email: String, password: String) async throws {}
            func verify(email: String, code: String) async throws {}
            func resend(email: String) async throws {}
            func reset(email: String) async throws {}
        }

        struct LoginPage: View {
            let library = Library()
            var pendingEmail: String?

            var body: some View {
                KitAuthFlow(pendingEmail: pendingEmail,
                            signIn: { try await library.signIn(email: $0, password: $1) },
                            signUp: { try await library.signUp(email: $0, password: $1) },
                            verify: { try await library.verify(email: $0, code: $1) },
                            resend: { try await library.resend(email: $0) },
                            reset: { try await library.reset(email: $0) })
            }
        }

        public enum ShelfCheck {
            @MainActor public static func run() -> [String] {
                var failures: [String] = []
                let expected: [(String, KitAuthStep, Bool)] = [
                    ("login", .signIn, false), ("login.join", .signUp, false),
                    ("login.code", .code(email: "reader@example.com", reset: false), false),
                    ("login.reset", .code(email: "reader@example.com", reset: true), false), ("login.forgot", .signIn, true),
                ]
                for (name, step, forgot) in expected {
                    UserDefaults.standard.register(defaults: ["destination": name])
                    let opening = KitAuthLaunch.opening(pendingEmail: "reader@example.com")
                    if opening.step != step || opening.forgot != forgot { failures.append("Shelf \\(name) opens \\(opening)") }
                    let page = LoginPage(pendingEmail: "reader@example.com")
                    if ImageRenderer(content: page.frame(width: 393, height: 852)).cgImage == nil { failures.append("Shelf \\(name) does not draw") }
                }
                return failures
            }
        }

        """

    static let shelfDesign = """
        import SwiftUI

        public extension Color {
            static var brand: Color { Color(red: 0.16, green: 0.36, blue: 0.3) }
        }

        """

    static let check = """
        import Foundation
        import Least
        import Seer
        import SeerFive
        import Shelf

        let failures = SeerCheck.run() + SeerFiveCheck.run() + LeastCheck.run() + ShelfCheck.run()
        for failure in failures { print("FAIL " + failure) }
        print(failures.isEmpty ? "CHECK PASSED" : "CHECK FAILED: \\(failures.count)")
        exit(failures.isEmpty ? 0 : 1)

        """

    /// What a tool printed and how it ended.
    struct Outcome {
        let status: Int32
        let output: String

        /// The last lines, for a failure's message.
        var tail: String { output.split(separator: "\n").suffix(40).joined(separator: "\n") }

        /// Every warning the compiler gave in a file under `folder`.
        func warnings(under folder: String) -> [String] {
            let plain = output.replacingOccurrences(of: "\u{1B}\\[[0-9;]*m", with: "", options: .regularExpression)
            return Array(Set(plain.split(separator: "\n").map(String.init).filter { $0.contains("warning:") && $0.contains(folder) })).sorted()
        }
    }

    /// Runs `arguments` through `xcrun` in `folder`, with the environment a person's shell gives (none of the test
    /// runner's), and gathers what it prints.
    static func run(_ arguments: [String], in folder: URL) throws -> Outcome {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = arguments
        process.currentDirectoryURL = folder
        let keep = ["PATH", "HOME", "TMPDIR", "USER", "LOGNAME", "LANG", "DEVELOPER_DIR", "SHELL"]
        process.environment = ProcessInfo.processInfo.environment.filter { keep.contains($0.key) }
        let log = folder.appendingPathComponent("\(arguments[0])-\(arguments.count).log")
        FileManager.default.createFile(atPath: log.path, contents: nil)
        let handle = try FileHandle(forWritingTo: log)
        process.standardOutput = handle
        process.standardError = handle
        process.standardInput = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        try handle.close()
        return Outcome(status: process.terminationStatus, output: (try? String(contentsOf: log, encoding: .utf8)) ?? "")
    }
}
