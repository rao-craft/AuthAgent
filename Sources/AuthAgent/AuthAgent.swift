//  WHAT: A sign-in flow as a Granite agent package. A call gives the app's mark, maps the flow's look roles to the
//        app's own colours and fonts, sets its words, timings, sizes and symbols by key, and names the launch
//        destinations it opens for; the run writes plain SwiftUI into the folder the call names (Sign In, Sign Up, the
//        one-time code, the reset sheet, the underline field, the outlined button, the mark) with the look they read and
//        where they open, and answers the root view's initializer and a page body that calls it.
//  IN:   Input: the folder, the mark, the look, strings, tuning and launch lines, a prefix, the modules the app's names
//        live in.
//  OUT:  AuthResult: the files written, the views, the root's initializer, a page body, the destinations, the notes.
//  PIN:  NO MODEL. Every file is made from the call, the same way every time; a line that is not understood is refused
//        with its reason beside every other, and nothing is written until every problem is fixed and every file parses.
//  PIN:  THE FLOW NEVER ROUTES THE APP. It moves between its own screens and its own sheet, and takes the app's account
//        service as closures; the app's navigation opens the page that shows it, and a control whose closure is nil is
//        not drawn.

import Foundation
import GraniteAgents

public struct AuthAgent: GraniteAgentPackage {
    public struct Input: Codable, Sendable {
        /// The folder the flow goes in, relative to the project; `Components/Auth` when left out.
        public var into: String?
        /// The app's mark: the Swift that makes a view of the app's (`BrandMark()`), or an SF Symbol's name.
        public var mark: String?
        /// One line a look role: `title = Font.brandTitle`, `accent = Color.accent`.
        public var look: [String]?
        /// One line a word: `signIn.title = "Welcome back"`.
        public var strings: [String]?
        /// One line a timing, size or symbol: `swap = spring 0.38 0.88`, `mark.turn = 42`.
        public var tuning: [String]?
        /// One line a launch destination: `auth.signup = signUp`.
        public var launch: [String]?
        /// A prefix for the kit's types, when the app already has names that clash: `Kit` writes `KitAuthFlow`.
        public var prefix: String?
        /// Modules the mark and the look's names live in.
        public var imports: [String]?
        /// The host's folder.
        public var directory: String?

        public init(into: String? = nil, mark: String? = nil, look: [String]? = nil, strings: [String]? = nil,
                    tuning: [String]? = nil, launch: [String]? = nil, prefix: String? = nil, imports: [String]? = nil,
                    directory: String? = nil) {
            self.into = into; self.mark = mark; self.look = look; self.strings = strings; self.tuning = tuning
            self.launch = launch; self.prefix = prefix; self.imports = imports; self.directory = directory
        }
    }

    public typealias Event = AuthFrame
    public typealias Output = AuthResult
    public typealias Compute = Void

    public static let word = "auth"
    /// What it makes: the views a page shows, and what they read.
    public static let makes = [
        AgentMake(kind: "view", what: "the sign-in flow as reusable SwiftUI views: AuthFlow, the root a page shows with AuthFlow(signIn:signUp:verify:reset:), and the screens and parts it is built from (Sign In, Sign Up, the one-time code, the reset sheet, the underline field, the outlined button, the mark)",
                  into: ["Components/Auth/*"], never: "a page, the app's navigation, a session or an account service"),
        AgentMake(kind: "support", what: "what the views read: AuthLook (each colour and font, the app's or the system's), AuthLaunch (the screen a -destination opens) and AuthStep",
                  into: ["Components/Auth/*"], never: "the app's design names themselves"),
    ]
    public static let summary = "writes an app's sign-in flow as plain SwiftUI (Sign In, Sign Up, a one-time code sent by email, a reset-password sheet) in the app's own look and words, moving between its screens itself and calling the app's account service through closures."
    public static let fields = [
        "into": "the folder for the flow, relative to the project; Components/Auth when left out",
        "mark": "the app's mark at the head of Sign In and Sign Up: the Swift that makes a view the app has (`BrandMark()`), or an SF Symbol's name (`seal.fill`); person.crop.circle when left out",
        "look": "one line a look role, `role = Swift` naming the app's own colour or font: `accent = Color.accent`, `title = Font.brandTitle`; a role left out reads the system's",
        "strings": "one line a word on the screens, `key = \"words\"`: `signIn.title = \"Welcome back\"`; a key left out says its English default",
        "tuning": "one line a timing, size or symbol, `key = value`: `swap = spring 0.38 0.88`, `mark.turn = 42`, `forgot.detents = medium large`; a key left out keeps its default",
        "launch": "one line a `-destination` the flow opens for, `name = state`: signIn, signUp, forgot (Sign In with the reset sheet up), or code with an email (`auth.code = code \"name@example.com\"`)",
        "prefix": "a prefix for the kit's types when the app already has names that clash: `Kit` writes KitAuthFlow",
        "imports": "modules the mark and the look's names live in, when the app's own target does not declare them",
    ]
    public static let guide: String = {
        let colors = LookRoles.colors.map(\.name).joined(separator: ", ")
        let fonts = LookRoles.fonts.map(\.name).joined(separator: ", ")
        let words = StringKeys.all.map { $0.english.isEmpty ? "\($0.key) (none)" : "\($0.key) (\"\($0.english)\")" }.joined(separator: ", ")
        let tuning = TuningKeys.all.map { "\($0.key) \($0.fallback)" }.joined(separator: ", ")
        return """
            Tag auth for an app's sign-in flow: Sign In, Sign Up, a one-time code sent by email, and a sheet to reset a \
            password, in the app's own look and words. It writes plain SwiftUI (iOS 17 and macOS 14) into `into` \
            (Components/Auth): AuthFlow, the root view a page shows, and the screens and parts it is built from \
            (AuthSignInView, AuthSignUpView, AuthCodeView, AuthForgotView, AuthField, AuthButton, AuthMark), with AuthLook, \
            AuthLaunch and AuthStep; every view has a #Preview. AuthFlow moves between its own screens and takes the \
            app's account service as closures, each async throws and each optional, so one left out leaves its control \
            out: `AuthFlow(signIn: { try await account.signIn(email: $0, password: $1) }, signUp: { try await \
            account.signUp(email: $0, password: $1) }, verify: { try await account.verify(email: $0, code: $1) }, reset: \
            { try await account.reset(email: $0) })`; `resend: { try await account.resend(email: $0) }` adds a resend \
            link, and `pendingEmail:` opens on the code screen for an email still waiting for its code. What a closure \
            throws shows under the fields. Once signUp returns, the code screen asks for the code sent to that email; once \
            reset returns, the sheet closes and the code screen asks for it in its reset form; "Use a different email" \
            goes back. `mark` is the app's mark at the head of Sign In and Sign Up: the Swift that makes a view the app \
            has (`BrandMark()`), or an SF Symbol's name; person.crop.circle when left out. Each `look` line maps a role \
            to the app's own Swift, `role = Swift` (`accent = Color.accent`, `title = Font.brandTitle`, `field = \
            Font.system(size: 16, design: .serif)`); a role left out reads the system's. Colour roles: \(colors). Font \
            roles: \(fonts). Each `strings` line sets the words of a key, `key = "words"` (in quotes, \\" and \\n inside); \
            the keys and their defaults: \(words). signIn.refused is put before the reason a refused sign-in gives \
            (`"Unauthorized: "`); with signIn.invalid set, Sign In refuses an email that is not one, or a password \
            shorter than password.minimum, itself, saying the two together, before signIn is asked. Each `tuning` line \
            sets a timing, size or symbol, `key = value`; the keys and their defaults: \(tuning). An animation is \
            `spring <response> <damping>`, `easeInOut <seconds>` (easeIn, easeOut, linear), smooth, snappy, bouncy or \
            none; mark.turn is the seconds one turn takes (0 keeps the mark still); a symbol is an SF Symbol's name; \
            detents are medium, large, fraction(0.6) or height(320); a shadow is `opacity radius x y` in the primary \
            colour, or none; haptic is light, medium, heavy, soft, rigid or none. Each `launch` line names a \
            `-destination` the flow opens for and the state it opens in, `name = state`: signIn, signUp, forgot (Sign In \
            with the reset sheet up), or code with the email in quotes (`code "name@example.com"`, `code reset \
            "name@example.com"` for the reset form; with none, pendingEmail). The app's navigation opens the page that \
            shows AuthFlow for each of those names (alias the others to its destination, like `auth.signup -> auth`); \
            AuthFlow opens as the line says. `prefix` renames the kit's types when the app has names that clash (`Kit` \
            writes KitAuthFlow); `imports` names the modules the mark and the look's names live in. Examples. The \
            least, a symbol for a mark and the system's look: {"mark": "lock.shield", "strings": ["signIn.title = \
            \\"Welcome back\\""]}. A reading app in its own look, the mark turning slowly, a code of four digits, with \
            screenshots of each screen: {"mark": "Image(\\"Logo\\").resizable()", "look": ["accent = Color.brand", \
            "title = Font.custom(\\"Lora\\", size: 26)"], "strings": ["signIn.title = \\"Welcome to Shelf\\"", \
            "signUp.subtitle = \\"Your books, everywhere\\"", "signIn.refused = \\"Couldn't sign in: \\""], "tuning": \
            ["mark.size = 72", "mark.turn = 60", "code.length = 4", "swap = snappy"], "launch": ["login = signIn", \
            "login.join = signUp", "login.code = code \\"reader@example.com\\"", "login.reset = forgot"]}. A line it \
            cannot read is refused with the reason, beside every other, and nothing is written: fix them and call \
            again. Not for the app's session, its services or its navigation.
            """
    }()

    public static func output(from events: [AuthFrame]) -> AuthResult? { events.compactMap(\.result).last }

    public init() {}

    public func run(_ input: Input, context: Context) -> AsyncThrowingStream<AuthFrame, Error> {
        // The folder is the call's, else the host's (a host over the wire may give it only there), else the
        // process's: never the runner's working folder while the host named one.
        var resolved = input
        if resolved.directory == nil { resolved.directory = context.host.directory }
        let call = resolved
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let result = try Self.write(call, note: context.host.note) { continuation.yield($0) }
                    continuation.yield(.written(result))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// The whole call: the lines read, every file made, staged, checked and written.
    static func write(_ input: Input, note: @Sendable (String) -> Void, yield: (AuthFrame) -> Void) throws -> AuthResult {
        let call = try AuthCall.read(input)
        let files = AgentFiles(directory: input.directory)
        let folder = files.resolve(call.into)
        let made = try AuthPlan.files(for: call)
        let lines = [input.look, input.strings, input.tuning, input.launch].reduce(0) { $0 + ($1?.count ?? 0) }
        yield(.read(lines: lines, files: made.count))
        note("writing the sign-in flow, \(made.count) files, into \(files.relative(folder))")

        let planned = made.map { (url: folder.appendingPathComponent($0.file), text: $0.text) }
        // What each file held before: a file written again to the same text is made and unchanged.
        var before: [String: String] = [:]
        for file in planned {
            if let text = try? String(contentsOf: file.url, encoding: .utf8) { before[file.url.path] = text }
        }
        let written = try files.write(planned)
        note("wrote \(written.count) files")

        var items: [AgentMade] = []
        for (file, path) in zip(made, written) {
            let state: AgentMade.State = before[path].map { $0 == file.text ? .unchanged : .rewritten } ?? .written
            items.append(AgentMade(kind: file.kind.rawValue, name: file.name, path: path, state: state))
        }
        let root = call.prefix + AuthPlan.root
        return AuthResult(path: written.first, paths: written, views: made.filter { $0.kind == .view }.map(\.name),
                          initializers: [initializer(root)], body: body(root), destinations: call.launch.map(\.destination),
                          notes: notes(call, root: root), made: items,
                          expected: made.map { AgentExpected(kind: $0.kind.rawValue, name: $0.name) })
    }

    /// The root view's initializer, as a line.
    static func initializer(_ root: String) -> String {
        "\(root)(pendingEmail: String? = nil, "
            + "signIn: (@MainActor (_ email: String, _ password: String) async throws -> Void)? = nil, "
            + "signUp: (@MainActor (_ email: String, _ password: String) async throws -> Void)? = nil, "
            + "verify: (@MainActor (_ email: String, _ code: String) async throws -> Void)? = nil, "
            + "resend: (@MainActor (_ email: String) async throws -> Void)? = nil, "
            + "reset: (@MainActor (_ email: String) async throws -> Void)? = nil)"
    }

    /// A page body that shows the flow, for an account service reached as `account`.
    static func body(_ root: String) -> String {
        "\(root)(signIn: { try await account.signIn(email: $0, password: $1) }, "
            + "signUp: { try await account.signUp(email: $0, password: $1) }, "
            + "verify: { try await account.verify(email: $0, code: $1) }, "
            + "reset: { try await account.reset(email: $0) })"
    }

    /// What the app has to provide or do for what this call wrote, one sentence each.
    static func notes(_ call: AuthCall, root: String) -> [String] {
        var notes = ["Show the flow from a page with `body`: the account service's signIn, signUp, verify and reset events "
            + "(add `resend:` for a resend link); a closure left out leaves its control out, and what one throws shows under the fields."]
        if let first = call.launch.first {
            let names = call.launch.map { "`\($0.destination)`" }.joined(separator: ", ")
            let aliases = call.launch.dropFirst().map { "`\($0.destination) -> \(first.destination)`" }
            notes.append("The app's navigation opens the page that shows \(root) for \(names)"
                + (aliases.isEmpty ? "" : ", by the launch aliases \(aliases.joined(separator: ", "))")
                + "; \(root) opens each as its launch line says, the reset sheet already up for `forgot`.")
        }
        var mapped: [String] = []
        for role in LookRoles.all {
            guard let expression = call.look[role.name], !isSwiftUIs(expression), !mapped.contains(expression) else { continue }
            mapped.append(expression)
        }
        if !mapped.isEmpty {
            let place = call.imports.isEmpty ? "the app" : "the app or \(call.imports.joined(separator: ", "))"
            notes.append("\(call.prefix)AuthLook reads the app's own \(mapped.map { "`\($0)`" }.joined(separator: ", ")): each must exist in \(place).")
        }
        if case .view(let expression) = call.mark {
            notes.append("\(call.prefix)AuthMark draws the app's `\(expression)`, which must exist; the kit sizes it, and turns it and shadows it as `tuning` says.")
        }
        if call.flags.contains("signIn.check") {
            let words = (call.words["signIn.refused"] ?? "") + (call.words["signIn.invalid"] ?? "")
            let minimum = call.tuning["password.minimum"]?.swift ?? "6"
            notes.append("Sign In refuses an email that is not one, or a password shorter than \(minimum), itself with \"\(words)\", before signIn is asked.")
        }
        return notes
    }

    /// SwiftUI's own colours and fonts: a look line that names only these needs nothing of the app's.
    static let swiftUIs: Set<String> = [
        "Color.primary", "Color.secondary", "Color.accentColor", "Color.white", "Color.black", "Color.clear", "Color.gray",
        "Color.red", "Color.orange", "Color.yellow", "Color.green", "Color.mint", "Color.teal", "Color.cyan", "Color.blue",
        "Color.indigo", "Color.purple", "Color.pink", "Color.brown",
        "Font.system", "Font.custom", "Font.largeTitle", "Font.title", "Font.title2", "Font.title3", "Font.headline",
        "Font.subheadline", "Font.body", "Font.callout", "Font.footnote", "Font.caption", "Font.caption2",
    ]

    /// Whether a look line's Swift names nothing but SwiftUI's colours and fonts (`Color.primary.opacity(0.75)`,
    /// `Font.system(size: 13)`), so the app need declare nothing for it.
    static func isSwiftUIs(_ expression: String) -> Bool {
        guard expression.hasPrefix("Color.") || expression.hasPrefix("Font.") else { return false }
        guard let pattern = try? NSRegularExpression(pattern: #"\b(?:Color|Font)\.[A-Za-z0-9_]+"#) else { return false }
        let names = pattern.matches(in: expression, range: NSRange(expression.startIndex..., in: expression))
            .compactMap { Range($0.range, in: expression).map { String(expression[$0]) } }
        return !names.isEmpty && names.allSatisfy(swiftUIs.contains)
    }
}
