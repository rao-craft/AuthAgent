import Foundation
import XCTest
@testable import AuthAgent

/// What a call writes, file by file: the Seer call drawn as the original composes its screens (the inventory's tree,
/// in order, with its values), the defaults in the system's look, and a prefix and imports for another app.
final class AuthEmitTests: XCTestCase {
    /// Each file's parts in the order the original composes them (`kits/inventory/auth.md`): a part found before the
    /// one listed ahead of it fails, so the tree's order is pinned as well as its values.
    static let tree: [(file: String, parts: [String])] = [
        ("AuthSignInView.swift", [
            "VStack(spacing: 0) {", "Spacer()", "VStack(spacing: 8) {", "AuthMark()",
            "Text(\"Welcome to Seer\")", ".font(AuthLook.title)", ".foregroundStyle(AuthLook.titleColor)",
            "Text(\"Sign in to continue\")", ".font(AuthLook.subtitle)", ".foregroundStyle(AuthLook.subtitleColor)",
            ".padding(.bottom, 42)", "VStack(spacing: 12) {", "AuthField(\"Email\"", ".submitLabel(.next)",
            "AuthField(\"Password\", text: $password, kind: .password)", ".submitLabel(.go)", ".padding(.horizontal, 42)",
            "HStack {", "Spacer()", "Text(\"Forgot password?\")", ".font(AuthLook.link)", ".foregroundStyle(AuthLook.accent)",
            ".buttonStyle(.plain)", ".padding(.horizontal, 42)", ".padding(.top, 8)",
            "Text(message)", ".font(AuthLook.message)", ".foregroundStyle(AuthLook.danger)", ".multilineTextAlignment(.center)",
            ".padding(.horizontal, 42)", ".padding(.top, 12)",
            "AuthButton(\"Sign In\"", ".padding(.horizontal, 50)", ".padding(.top, 28)", "Spacer()",
            "HStack(spacing: 4) {", "Text(\"Don't have an account?\")", ".font(AuthLook.footer)",
            ".foregroundStyle(AuthLook.secondaryForeground)", "create()", "AuthLook.impact()", "Text(\"Create one.\")",
            ".font(AuthLook.footerLink)", ".foregroundStyle(AuthLook.accent)", ".buttonStyle(.plain)", ".padding(.bottom, 32)",
            ".onTapGesture { focus = nil }",
        ]),
        ("AuthSignUpView.swift", [
            "VStack(spacing: 0) {", "Spacer()", "VStack(spacing: 8) {", "AuthMark()", "Text(\"Create account\")",
            "Text(\"Start your journey\")", ".padding(.bottom, 42)", "VStack(spacing: 12) {",
            "AuthField(\"Password (min 6 characters)\", text: $password, kind: .newPassword)", ".submitLabel(.next)",
            "AuthField(\"Confirm password\", text: $confirmation, kind: .newPassword, error: !matches)", ".submitLabel(.go)",
            ".padding(.horizontal, 42)", "if !matches {", "Text(\"Passwords do not match\")", ".font(AuthLook.message)",
            ".foregroundStyle(AuthLook.danger)", ".frame(maxWidth: .infinity, alignment: .leading)", ".padding(.horizontal, 42)",
            ".padding(.top, 6)", "Text(message)", "AuthButton(\"Create Account\"", ".padding(.horizontal, 50)", ".padding(.top, 28)",
            "Spacer()", "HStack(spacing: 4) {", "Text(\"Already have an account?\")", "signInInstead()", "AuthLook.impact()",
            "Text(\"Sign in.\")", ".padding(.bottom, 32)", ".onTapGesture { focus = nil }",
        ]),
        ("AuthMark.swift", [
            "SeerMark()", ".frame(width: 100, height: 100)", ".padding(.vertical, 24)",
            ".shadow(color: Color.primary.opacity(0.3), radius: 3, x: 1, y: 1)", ".rotationEffect(.degrees(angle))",
            "withAnimation(.linear(duration: 42).repeatForever(autoreverses: false))", "angle = 360", ".padding(.bottom, 8)",
        ]),
        ("AuthCodeView.swift", [
            "VStack(spacing: 0) {", "Spacer()", "VStack(spacing: 8) {", "Image(systemName: \"envelope.badge\")",
            ".font(AuthLook.glyph)", ".foregroundStyle(AuthLook.secondaryForeground)", ".padding(.bottom, 12)",
            "Text(title)", ".font(AuthLook.codeTitle)", ".foregroundStyle(AuthLook.foreground)",
            "Text(\"We sent a 6-digit code to\\n\\(email)\")", ".font(AuthLook.codeBody)", ".foregroundStyle(AuthLook.secondaryForeground)",
            ".multilineTextAlignment(.center)", ".lineSpacing(3)", ".padding(.bottom, 40)", ".padding(.horizontal, 24)",
            "VStack(spacing: 16) {", "TextField(\"code\", text: $code)", ".keyboardType(.numberPad)", ".textContentType(.oneTimeCode)",
            ".font(AuthLook.codeField)", ".multilineTextAlignment(.center)", ".tracking(12)", ".focused($focused)", ".prefix(6)",
            ".padding(.vertical, 16)", "RoundedRectangle(cornerRadius: 12)", ".fill(AuthLook.codeFill)", ".padding(.horizontal, 24)",
            "Text(\"Didn't receive it? Check your spam folder.\")", ".font(AuthLook.caption)",
            ".foregroundStyle(AuthLook.tertiaryForeground)", "Text(message)", ".padding(.horizontal, 24)", ".padding(.top, 12)",
            "AuthButton(button", ".padding(.horizontal, 24)", ".padding(.top, 28)", "back()", "Text(\"Use a different email\")",
            ".font(AuthLook.link)", ".foregroundStyle(.secondary)", ".padding(.top, 16)", "Spacer()",
            ".onAppear { focused = true }", ".onTapGesture { focused = false }",
        ]),
        ("AuthForgotView.swift", [
            "NavigationStack {", "VStack(spacing: 0) {", "Spacer()", "VStack(spacing: 8) {", "Image(systemName: \"lock.rotation\")",
            ".font(AuthLook.glyph)", ".foregroundStyle(AuthLook.secondaryForeground)", ".padding(.bottom, 8)",
            "Text(\"Enter your email and we'll send you a reset code.\")", ".font(AuthLook.instruction)",
            ".foregroundStyle(AuthLook.secondaryForeground)", ".multilineTextAlignment(.center)", ".lineSpacing(3)",
            ".padding(.bottom, 40)", ".padding(.horizontal, 42)", "AuthField(\"Email\"", ".focused($focused)", ".submitLabel(.send)",
            ".padding(.horizontal, 42)", "Text(message)", ".font(AuthLook.sheetMessage)", ".foregroundStyle(AuthLook.danger)",
            ".padding(.horizontal, 42)", ".padding(.top, 12)", "AuthButton(\"Send Reset Code\"", ".padding(.horizontal, 50)",
            ".padding(.top, 28)", "Spacer()", ".toolbar {", "ToolbarItem(placement: Self.closing)", "dismiss()",
            "Image(systemName: \"xmark\")", ".symbolRenderingMode(.hierarchical)", ".foregroundStyle(AuthLook.accent)",
            ".accessibilityLabel(\"Close\")", "ToolbarItem(placement: .principal)", "Text(\"Reset Password\")",
            ".font(AuthLook.sheetTitle)", ".foregroundStyle(AuthLook.titleColor)", ".navigationBarTitleDisplayMode(.inline)",
            ".onAppear { focused = true }", ".onTapGesture { focused = false }", "return .topBarTrailing",
        ]),
        ("AuthField.swift", [
            ".font(AuthLook.field)",
            ".keyboardType(kind == .email ? .emailAddress : .default)", ".textContentType(contentType)", ".autocorrectionDisabled()",
            ".textInputAutocapitalization(.never)", ".padding(.horizontal, 16)", ".padding(.vertical, 12)",
            ".overlay(alignment: .bottom) {", "Rectangle()", ".fill(error ? AuthLook.lineError : AuthLook.line)",
            ".frame(height: 1)", ".padding(.horizontal, 8)", "SecureField(placeholder, text: $text)",
            "TextField(placeholder, text: $text)",
        ]),
        ("AuthButton.swift", [
            "Button {", "guard acting else { return }", "action()", "AuthLook.impact()", "ZStack {", "ProgressView()",
            ".tint(AuthLook.spinner)", ".scaleEffect(0.85)", "Text(title)", ".font(AuthLook.button)",
            ".foregroundStyle(acting ? AuthLook.control : AuthLook.controlFaint)", ".frame(maxWidth: .infinity)",
            ".frame(height: 52)", ".background(", "RoundedRectangle(cornerRadius: 4)",
            ".stroke(acting ? AuthLook.control : AuthLook.controlFaint, lineWidth: 1)", ".disabled(!acting)",
            ".animation(.easeInOut(duration: 0.15), value: enabled)", ".animation(.easeInOut(duration: 0.15), value: busy)",
        ]),
        ("AuthFlow.swift", [
            "ZStack {", "AuthSignInView(", ".transition(Self.back)", "AuthSignUpView(", ".transition(Self.forward)", "AuthCodeView(",
            ".transition(Self.forward)", ".animation(.spring(response: 0.38, dampingFraction: 0.88), value: step)",
            ".frame(maxWidth: .infinity, maxHeight: .infinity)", ".background(AuthLook.background)", ".sheet(isPresented: $forgot) {",
            "AuthForgotView(", ".presentationDetents([.medium, .large])", ".presentationDragIndicator(.visible)",
            ".asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),",
            "removal: .move(edge: .leading).combined(with: .opacity))",
            ".asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),",
            "removal: .move(edge: .trailing).combined(with: .opacity))",
        ]),
    ]

    func testTheSeerCallComposesEachScreenAsTheOriginalDoes() throws {
        let files = try Fixture.emitted(Fixture.seer())
        for (file, parts) in Self.tree {
            let text = try XCTUnwrap(files[file], file)
            var from = text.startIndex
            for part in parts {
                guard let found = text.range(of: part, range: from..<text.endIndex) else {
                    XCTFail("\(file): `\(part)` is missing, or out of the original's order")
                    break
                }
                from = found.upperBound
            }
        }
        // What the original leaves out stays out: no ground behind a screen or the sheet (the flow paints the one
        // ground), no colour on a field's text, the button in the button's own style, no tap on a link but the footer's.
        for file in ["AuthSignInView.swift", "AuthSignUpView.swift", "AuthCodeView.swift", "AuthForgotView.swift"] {
            XCTAssertFalse(files[file]!.contains(".background(AuthLook.background)"), "\(file) draws on the flow's ground")
        }
        XCTAssertFalse(files["AuthField.swift"]!.contains(".foregroundStyle("), "a field's text is the system's primary")
        XCTAssertFalse(files["AuthButton.swift"]!.contains(".buttonStyle("), "the outlined button keeps the default button style")
        let taps = files.mapValues { $0.components(separatedBy: "AuthLook.impact()").count - 1 }.filter { $0.value > 0 }
        XCTAssertEqual(taps, ["AuthButton.swift": 1, "AuthSignInView.swift": 1, "AuthSignUpView.swift": 1],
                       "felt on the button and the footer links only")
        // The look the original draws, from the Seer call's lines; the rest are the defaults, which are the original's.
        let look = try XCTUnwrap(files["AuthLook.swift"])
        for member in ["titleColor: Color { Color.primary.opacity(0.75) }", "subtitleColor: Color { Color.primary.opacity(0.6) }",
                       "accent: Color { Color.accent }", "spinner: Color { Color.white }", "danger: Color { Color.red.opacity(0.85) }",
                       "line: Color { Color.primary.opacity(0.2) }", "lineError: Color { Color.red.opacity(0.4) }",
                       "control: Color { Color.primary }", "controlFaint: Color { Color.primary.opacity(0.3) }",
                       "codeFill: Color { Color.secondary.opacity(0.08) }", "title: Font { Font.brandTitle }",
                       "subtitle: Font { Font.brandNote2.italic() }", "field: Font { Font.system(size: 16, weight: .regular, design: .serif) }",
                       "link: Font { Font.system(size: 13, weight: .medium, design: .serif) }",
                       "message: Font { Font.system(size: 13, design: .serif) }",
                       "button: Font { Font.system(size: 16, weight: .semibold, design: .serif) }",
                       "footer: Font { Font.system(size: 14, design: .serif) }",
                       "footerLink: Font { Font.system(size: 14, weight: .semibold, design: .serif) }",
                       "glyph: Font { .system(size: 44, weight: .light) }", "codeTitle: Font { .system(size: 28, weight: .semibold) }",
                       "codeBody: Font { .system(size: 15, weight: .regular) }",
                       "codeField: Font { .system(size: 32, weight: .semibold, design: .monospaced) }",
                       "caption: Font { .system(size: 12) }", "sheetTitle: Font { Font.brandTitle }",
                       "instruction: Font { Font.system(size: 16, weight: .regular, design: .serif) }",
                       "sheetMessage: Font { Font.system(size: 13) }", "UIImpactFeedbackGenerator(style: .light)"] {
            XCTAssertTrue(look.contains(member), "AuthLook: \(member)")
        }
    }

    func testTheLeastCallDrawsTheSystemsLook() throws {
        let files = try Fixture.emitted(AuthAgent.Input())
        XCTAssertEqual(files.keys.sorted(), AuthPlan.names.map { $0 + ".swift" }.sorted())
        let mark = try XCTUnwrap(files["AuthMark.swift"])
        XCTAssertTrue(mark.contains("Image(systemName: \"person.crop.circle\")"))
        XCTAssertFalse(mark.contains("rotationEffect") || mark.contains(".shadow(") || mark.contains("@State"), "a still mark, no shadow")
        let look = try XCTUnwrap(files["AuthLook.swift"])
        XCTAssertFalse(look.contains("The call's"), "every role reads the system's value")
        XCTAssertTrue(look.contains("static var accent: Color { Color.accentColor }"))
        XCTAssertTrue(files["AuthLaunch.swift"]!.contains("if let pendingEmail { return (.code(email: pendingEmail, reset: false), false) }"))
        XCTAssertFalse(files["AuthLaunch.swift"]!.contains("switch destination"), "no launch lines, no destinations")
        // No tap at all: the feel is an empty function and UIKit stays out of the look.
        let still = try Fixture.emitted(AuthAgent.Input(tuning: ["haptic = none"]))["AuthLook.swift"]!
        XCTAssertTrue(still.contains("static func impact() {}"))
        XCTAssertFalse(still.contains("UIKit"))
    }

    func testAPrefixRenamesTheKitsTypesAndImportsReachWhereTheAppsNamesAre() throws {
        let files = try Fixture.emitted(Fixture.shelf())
        XCTAssertEqual(files.keys.sorted(), AuthPlan.names.map { "Kit" + $0 + ".swift" }.sorted())
        let kitNames = AuthPlan.names.joined(separator: "|")
        for (file, text) in files {
            XCTAssertEqual(text.matches(#"\b(\#(kitNames))\b"#), [], "\(file): every kit type carries the prefix")
            XCTAssertEqual(text.contains("import ShelfDesign"), file == "KitAuthMark.swift" || file == "KitAuthLook.swift",
                           "\(file): the import is where the app's names are")
        }
        // The app's Swift and words land as the call wrote them.
        XCTAssertTrue(files["KitAuthMark.swift"]!.contains("Image(\"Logo\").resizable()\n            .frame(width: 72, height: 72)"))
        XCTAssertTrue(files["KitAuthLook.swift"]!.contains("static var accent: Color { Color.brand }"))
        XCTAssertTrue(files["KitAuthLook.swift"]!.contains("UIImpactFeedbackGenerator(style: .soft)"))
        XCTAssertTrue(files["KitAuthSignInView.swift"]!.contains("prefix = \"Couldn't sign in: \""))
        XCTAssertTrue(files["KitAuthFlow.swift"]!.contains(".presentationDetents([.fraction(0.6), .large])"))
        XCTAssertTrue(files["KitAuthButton.swift"]!.contains("RoundedRectangle(cornerRadius: 12)"))
        XCTAssertTrue(files["KitAuthCodeView.swift"]!.contains("Text(\"Send a new code\")"), "a resend link where the call names one")
        // A launch with no email opens the code screen for the email still waiting, a reset one for the email it names.
        let launch = try XCTUnwrap(files["KitAuthLaunch.swift"])
        for line in ["case \"login.code\": return (.code(email: pendingEmail ?? \"\", reset: false), false)",
                     "case \"login.reset\": return (.code(email: \"reader@example.com\", reset: true), false)",
                     "case \"login.forgot\": return (.signIn, true)",
                     "static func opening(pendingEmail: String? = nil) -> (step: KitAuthStep, forgot: Bool)"] {
            XCTAssertTrue(launch.contains(line), line)
        }
    }
}
