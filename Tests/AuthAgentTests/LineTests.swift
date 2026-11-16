import Foundation
import XCTest
@testable import AuthAgent

/// Every line a call gives, read: each form a field takes, and each way a line is refused, with the reason the model
/// is told.
final class LineTests: XCTestCase {
    func testAKeyLineIsCutAtItsFirstTopLevelEquals() {
        let cases: [(String, KeyLine.Parsed?)] = [
            ("title = Font.brandTitle", .init(key: "title", value: "Font.brandTitle")),
            ("signIn.title = \"a = b\"", .init(key: "signIn.title", value: "\"a = b\"")),
            ("x = y == z", .init(key: "x", value: "y == z")),
            ("f(a = 1) = 2", .init(key: "f(a = 1)", value: "2")),
            ("title =", .init(key: "title", value: "")),
            ("a == b", nil),
            ("= b", nil),
            ("title", nil),
        ]
        for (line, expected) in cases { XCTAssertEqual(KeyLine.split(line), expected, line) }
    }

    func testQuotedWordsAreReadWithTheirEscapes() {
        let cases: [(String, String?)] = [
            ("\"Welcome\"", "Welcome"),
            ("\"Unauthorized: \"", "Unauthorized: "),
            ("\"Say \\\"hi\\\"\"", "Say \"hi\""),
            ("\"one\\ntwo\"", "one\ntwo"),
            ("\"a \\\\ b\"", "a \\ b"),
            ("\"closed\"   ", "closed"),
            ("Create one.", "Create one."),
            ("\"open", nil),
            ("\"closed\" and more", nil),
        ]
        for (value, expected) in cases { XCTAssertEqual(KeyLine.unquote(value), expected, value) }
    }

    func testSwiftIsWrittenAsAPersonWritesIt() {
        XCTAssertEqual(SwiftLiteral.quoted("Don't \"stop\" \\ now\nplease"), #""Don't \"stop\" \\ now\nplease""#)
        XCTAssertEqual(SwiftLiteral.number(52), "52")
        XCTAssertEqual(SwiftLiteral.number(0.38), "0.38")
        XCTAssertEqual(SwiftLiteral.number(0.85), "0.85")
        XCTAssertEqual(SwiftLiteral.number(42), "42")
    }

    // MARK: - mark

    func testAMarkIsAViewOfTheAppsOrASymbol() throws {
        let cases: [(String?, Mark)] = [
            (nil, .symbol("person.crop.circle")),
            ("  ", .symbol("person.crop.circle")),
            ("seal.fill", .symbol("seal.fill")),
            ("\"lock.shield\"", .symbol("lock.shield")),
            ("SeerMark()", .view("SeerMark()")),
            ("Image(\"Logo\").resizable()", .view("Image(\"Logo\").resizable()")),
        ]
        for (text, expected) in cases { XCTAssertEqual(try Mark.read(text), expected, text ?? "nil") }
        for text in ["Brand Mark", "BrandMark", "(BrandMark)", "seal.Fill"] {
            XCTAssertThrowsError(try Mark.read(text), text) { error in
                XCTAssertTrue("\(error)".hasPrefix("mark `\(text)`: a mark is the Swift that makes a view, like `BrandMark()`"), "\(error)")
            }
        }
    }

    // MARK: - look

    func testALookLineMapsARoleToTheAppsSwift() throws {
        let cases: [(String, String, String)] = [
            ("title = Font.brandTitle", "title", "Font.brandTitle"),
            ("subtitle = Font.brandNote2.italic()", "subtitle", "Font.brandNote2.italic()"),
            ("field = Font.system(size: 16, design: .serif)", "field", "Font.system(size: 16, design: .serif)"),
            ("accent = Color.accent", "accent", "Color.accent"),
            ("titleColor = Color.primary.opacity(0.75)", "titleColor", "Color.primary.opacity(0.75)"),
            ("sheetMessage = Font.system(size: 13)", "sheetMessage", "Font.system(size: 13)"),
            ("accent = accent", "accent", ".accent"),
            ("ACCENT = Color.accent", "accent", "Color.accent"),
            ("danger = Color(red: 0.9, green: 0.2, blue: 0.2)", "danger", "Color(red: 0.9, green: 0.2, blue: 0.2)"),
            ("codeField = .system(size: 30, design: .monospaced)", "codeField", ".system(size: 30, design: .monospaced)"),
        ]
        for (line, role, expression) in cases {
            let assignment = try LookLine.parse(line)
            XCTAssertEqual(assignment.role.name, role, line)
            XCTAssertEqual(assignment.expression, expression, line)
        }
    }

    func testALookLineItCannotReadIsRefusedWithWhatItTakes() {
        let cases: [(String, String)] = [
            ("title Font.brandTitle", "a look line is `role = expression`, like `title = Font.brandTitle`"),
            ("heading = Font.brandTitle", "`heading` is not a look role; colours: background, titleColor"),
            ("title =", "`title` has no value: name the app's font, like `title = Font.brandTitle`"),
            ("accent = \"bronze\"", "a look value is Swift, not words in quotes: `accent = Color.accent`"),
            ("accent = #AE9060", "`#AE9060` is a hex code; name the app's colour"),
            ("title = Color.accent", "`title` is type, and `Color.accent` is a colour"),
            ("accent = Font.brandTitle", "`accent` is a colour, and `Font.brandTitle` is a font"),
        ]
        for (line, reason) in cases {
            XCTAssertThrowsError(try LookLine.parse(line), line) { error in
                XCTAssertTrue("\(error)".hasPrefix("look `\(line)`: \(reason)"), "\(error)")
            }
        }
    }

    // MARK: - strings

    func testAStringsLineSetsTheWordsOfAKey() throws {
        let cases: [(String, String, String)] = [
            ("signIn.title = \"Welcome to Seer\"", "signIn.title", "Welcome to Seer"),
            ("signIn.refused = \"Unauthorized: \"", "signIn.refused", "Unauthorized: "),
            ("signIn.footerLink = Create one.", "signIn.footerLink", "Create one."),
            ("code.sent = \"We sent a code to\\nyou\"", "code.sent", "We sent a code to\nyou"),
            ("forgot.instruction = \"Enter your email and we'll send you a reset code.\"", "forgot.instruction",
             "Enter your email and we'll send you a reset code."),
            ("signIn.footer = \"Say \\\"hi\\\"\"", "signIn.footer", "Say \"hi\""),
            ("SIGNIN.TITLE = \"Hi\"", "signIn.title", "Hi"),
            ("signIn.invalid = \"\"", "signIn.invalid", ""),
        ]
        for (line, key, words) in cases {
            let assignment = try StringLine.parse(line)
            XCTAssertEqual(assignment.key.key, key, line)
            XCTAssertEqual(assignment.words, words, line)
        }
    }

    func testAStringsLineItCannotReadIsRefusedWithWhatItTakes() {
        let cases: [(String, String)] = [
            ("signIn.title \"Hi\"", "a strings line is `key = \"words\"`, like `signIn.title = \"Welcome back\"`"),
            ("signIn.titel = \"Hi\"", "`signIn.titel` is not a key; the keys are signIn.title, signIn.subtitle"),
            ("welcome = \"Hi\"", "`welcome` is not a key; the keys are email, signIn.title"),
            ("signIn.title = \"Hi", "the words are not closed: one pair of quotes around them, `signIn.title = \"Welcome back\"`"),
            ("signIn.title = \"Hi\" there", "the words are not closed"),
        ]
        for (line, reason) in cases {
            XCTAssertThrowsError(try StringLine.parse(line), line) { error in
                XCTAssertTrue("\(error)".hasPrefix("strings `\(line)`: \(reason)"), "\(error)")
            }
        }
    }

    // MARK: - tuning

    func testATuningLineIsWrittenAsSwiftUISpellsIt() throws {
        let cases: [(String, String, String)] = [
            ("swap = spring 0.38 0.88", "swap", ".spring(response: 0.38, dampingFraction: 0.88)"),
            ("swap = .spring(response: 0.38, dampingFraction: 0.88)", "swap", ".spring(response: 0.38, dampingFraction: 0.88)"),
            ("press = easeInOut 0.15", "press", ".easeInOut(duration: 0.15)"),
            ("press = .easeInOut(duration: 0.15)", "press", ".easeInOut(duration: 0.15)"),
            ("press = linear 0.3", "press", ".linear(duration: 0.3)"),
            ("swap = snappy", "swap", ".snappy"),
            ("swap = none", "swap", "nil"),
            ("Mark.Turn = 42", "mark.turn", "42"),
            ("mark.size = 100", "mark.size", "100"),
            ("button.spinner = 0.85", "button.spinner", "0.85"),
            ("header.below = 42", "header.below", "42"),
            ("code.length = 6", "code.length", "6"),
            ("code.tracking = 12", "code.tracking", "12"),
            ("code.glyph = envelope.badge", "code.glyph", "\"envelope.badge\""),
            ("code.glyph = \"envelope.badge\"", "code.glyph", "\"envelope.badge\""),
            ("forgot.detents = medium large", "forgot.detents", "[.medium, .large]"),
            ("forgot.detents = [.medium, .large]", "forgot.detents", "[.medium, .large]"),
            ("forgot.detents = fraction(0.6), large", "forgot.detents", "[.fraction(0.6), .large]"),
            ("forgot.detents = height(320)", "forgot.detents", "[.height(320)]"),
            ("mark.shadow = 0.3 3 1 1", "mark.shadow", "color: Color.primary.opacity(0.3), radius: 3, x: 1, y: 1"),
            ("haptic = light", "haptic", ".light"),
            ("haptic = soft", "haptic", ".soft"),
        ]
        for (line, key, swift) in cases {
            let assignment = try TuningLine.parse(line)
            XCTAssertEqual(assignment.key.key, key, line)
            XCTAssertEqual(assignment.value.swift, swift, line)
        }
        // Nothing, where a value can say it: a still mark, no shadow, no tap, no animation.
        for line in ["mark.turn = 0", "mark.shadow = none", "mark.shadow = 0", "haptic = none", "swap = none"] {
            XCTAssertTrue(try TuningLine.parse(line).value.isNone, line)
        }
        XCTAssertFalse(try TuningLine.parse("mark.turn = 42").value.isNone)
    }

    func testATuningLineItCannotReadIsRefusedWithWhatItTakes() {
        let cases: [(String, String)] = [
            ("mark.turn 42", "a tuning line is `key = value`, like `mark.turn = 42` or `swap = spring 0.38 0.88`"),
            ("mark.spin = 42", "`mark.spin` is not a key; the keys are mark.size, mark.turn, mark.shadow"),
            ("mark.size = big", "`mark.size` takes a number from 0 to 400, like `100`"),
            ("mark.size = 500", "`mark.size` takes a number from 0 to 400, like `100`"),
            ("button.spinner = 5", "`button.spinner` takes a number from 0.1 to 4, like `0.85`"),
            ("code.length = 3", "`code.length` takes a whole number from 4 to 10, like `6`"),
            ("code.length = 6.5", "`code.length` takes a whole number from 4 to 10, like `6`"),
            ("swap = spring 0.38", "`swap` takes an animation: `spring <response> <damping>` like `spring 0.38 0.88`"),
            ("swap = bounce", "`swap` takes an animation"),
            ("press = easeInOut", "`press` takes an animation"),
            ("code.glyph = Envelope Badge", "`code.glyph` takes an SF Symbol's name, like `envelope.badge`"),
            ("forgot.detents = medium medium", "`forgot.detents` takes the heights a sheet rests at, once each"),
            ("forgot.detents = small", "`forgot.detents` takes the heights a sheet rests at"),
            ("mark.shadow = 0.3 3", "`mark.shadow` takes `opacity radius x y`, like `0.3 3 1 1`"),
            ("mark.shadow = 2 3 1 1", "`mark.shadow` takes `opacity radius x y`"),
            ("haptic = strong", "`haptic` takes light, medium, heavy, soft, rigid or none"),
        ]
        for (line, reason) in cases {
            XCTAssertThrowsError(try TuningLine.parse(line), line) { error in
                XCTAssertTrue("\(error)".hasPrefix("tuning `\(line)`: \(reason)"), "\(error)")
            }
        }
    }

    func testEveryDefaultIsAValueItsKeyTakes() {
        for key in TuningKeys.all {
            guard case .success = TuningValueReader.read(key.fallback, for: key) else {
                return XCTFail("\(key.key)'s default `\(key.fallback)` is not one it takes")
            }
        }
    }

    // MARK: - launch

    func testALaunchLineNamesTheStateADestinationOpens() throws {
        let cases: [(String, String, LaunchState.Step)] = [
            ("auth = signIn", "auth", .signIn),
            ("auth.signup = signUp", "auth.signup", .signUp),
            ("auth.signup = sign-up", "auth.signup", .signUp),
            ("auth.forgot = forgot", "auth.forgot", .forgot),
            ("auth.code = code \"ada@seer.social\"", "auth.code", .code(email: "ada@seer.social", reset: false)),
            ("auth.reset = code reset \"ada@seer.social\"", "auth.reset", .code(email: "ada@seer.social", reset: true)),
            ("auth.pending = code", "auth.pending", .code(email: nil, reset: false)),
            ("auth.pending = code reset", "auth.pending", .code(email: nil, reset: true)),
        ]
        for (line, destination, step) in cases {
            let state = try LaunchLine.parse(line)
            XCTAssertEqual(state.destination, destination, line)
            XCTAssertEqual(state.step, step, line)
        }
    }

    func testALaunchLineItCannotReadIsRefusedWithWhatItTakes() {
        let cases: [(String, String)] = [
            ("auth signIn", "a launch line is `destination = state`, like `auth.signup = signUp`"),
            ("auth home = signIn", "`auth home` is not a destination name"),
            ("auth = home", "`home` is not a state; a launch opens signIn, signUp, forgot, or code with an email"),
            ("auth = signIn now", "signIn takes nothing after it"),
            ("auth = signUp now", "signUp takes nothing after it"),
            ("auth = forgot sheet", "forgot takes nothing after it"),
            ("auth.code = code ada@seer.social", "code takes the email in quotes, like `code \"name@example.com\"`"),
            ("auth.code = code \"\"", "the email is empty"),
        ]
        for (line, reason) in cases {
            XCTAssertThrowsError(try LaunchLine.parse(line), line) { error in
                XCTAssertTrue("\(error)".hasPrefix("launch `\(line)`: \(reason)"), "\(error)")
            }
        }
    }

    // MARK: - The call

    func testEveryProblemWithACallIsSaidAtOnce() {
        let input = AuthAgent.Input(
            mark: "Brand Mark",
            look: ["title = Font.brandTitle", "title = Font.brandBody", "heading = Font.brandTitle"],
            strings: ["signIn.title = \"A\"", "signIn.title = \"B\"", "signIn.titel = \"C\""],
            tuning: ["mark.turn = 42", "mark.turn = 60", "mark.size = big"],
            launch: ["auth = signIn", "auth = signUp", "auth = home"],
            prefix: "kit", imports: ["Brand Kit"])
        let reasons = Fixture.refusals(input)
        XCTAssertEqual(reasons.count, 11, reasons.joined(separator: "\n"))
        let expected = [
            "mark `Brand Mark`: a mark is",
            "look `title = Font.brandBody`: `title` is mapped twice; keep one line a role",
            "look `heading = Font.brandTitle`: `heading` is not a look role",
            "strings `signIn.title = \"B\"`: `signIn.title` is set twice; keep one line a key",
            "strings `signIn.titel = \"C\"`: `signIn.titel` is not a key",
            "tuning `mark.turn = 60`: `mark.turn` is set twice; keep one line a key",
            "tuning `mark.size = big`: `mark.size` takes a number",
            "launch `auth = signUp`: `auth` is named twice; one line a destination",
            "launch `auth = home`: `home` is not a state",
            "prefix `kit`: not a prefix for type names; UpperCamelCase letters and digits, like `Kit`",
            "imports `Brand Kit`: not a module name",
        ]
        for (reason, start) in zip(reasons, expected) { XCTAssertTrue(reason.hasPrefix(start), "\(reason)\nexpected: \(start)") }
        XCTAssertEqual(Fixture.refusals(AuthAgent.Input()), [], "a call with nothing is read: every default")
        XCTAssertEqual(Fixture.refusals(AuthAgent.Input(look: ["", "  "], strings: [""], imports: ["SwiftUI", "SeerKit", "SeerKit"])), [],
                       "blank lines are skipped, SwiftUI and a module named twice are left at one import")
    }

    func testTheCallsDefaultsAreTheKitsOwn() throws {
        let call = try AuthCall.read(AuthAgent.Input())
        XCTAssertEqual(call.into, "Components/Auth")
        XCTAssertEqual(call.mark, .symbol("person.crop.circle"))
        XCTAssertEqual(call.words.count, StringKeys.all.count)
        XCTAssertEqual(call.tuning.count, TuningKeys.all.count)
        XCTAssertEqual(call.flags, ["mark.symbol", "haptic"], "a still mark with no shadow, a tap, no prefix on a refusal, no check on the screen")
        let seer = try AuthCall.read(Fixture.seer())
        XCTAssertEqual(seer.flags, ["mark.turns", "mark.shadow", "haptic", "signIn.refused", "signIn.check"])
        XCTAssertEqual(seer.values["s:signIn.refusedInvalid"], "\"Unauthorized: Invalid login credentials\"")
        XCTAssertEqual(seer.values["mark"], "SeerMark()")
        XCTAssertEqual(try AuthCall.read(AuthAgent.Input(imports: ["SwiftUI", "SeerKit", "SeerKit"])).imports, ["SeerKit"])
    }
}
