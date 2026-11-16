import Foundation
import XCTest
@testable import AuthAgent

/// The templates as Swift an app can hold: every combination of the call's flags renders whole and parses, every view
/// has a preview, and nothing of Granite, no stored state and no iOS-only API outside `#if os(iOS)` reaches the app.
final class TemplateTests: XCTestCase {
    /// Every flag a template branches on, so every combination is drawn once.
    static let flags = ["mark.symbol", "mark.turns", "mark.shadow", "haptic", "signIn.refused", "signIn.check"]

    func testEveryCombinationOfFlagsRendersWholeAndParses() throws {
        let values = try AuthCall.read(Fixture.seer()).values
        let templates = AuthPlan.parts.compactMap { part -> (String, String)? in
            if case .template(let source) = part.source { return (part.name, source) }
            return nil
        }
        XCTAssertEqual(templates.count, 9)
        var parsed: [Set<String>] = [[], Set(Self.flags)]
        for mask in 0..<(1 << Self.flags.count) {
            let flags = Set(Self.flags.indices.filter { mask & (1 << $0) != 0 }.map { Self.flags[$0] })
            for (name, source) in templates {
                let text = try TemplateRender.render(source, flags: flags, values: values)
                XCTAssertFalse(text.contains("{{"), "\(name) \(flags): a value left out")
                XCTAssertFalse(text.contains("//@"), "\(name) \(flags): a block mark left in")
                XCTAssertEqual(text.filter { $0 == "{" }.count, text.filter { $0 == "}" }.count, "\(name) \(flags): braces balance")
                XCTAssertEqual(text.filter { $0 == "(" }.count, text.filter { $0 == ")" }.count, "\(name) \(flags): parentheses balance")
            }
            if flags == ["mark.turns", "haptic"] { parsed.append(flags) }
        }
        // The toolchain's own parser over the extremes and a middle: none of the flags, all of them, and one mix.
        for flags in parsed {
            let folder = try Fixture.folder()
            let urls = try templates.map { name, source -> URL in
                let url = folder.appendingPathComponent(name + ".swift")
                try TemplateRender.render(source, flags: flags, values: values).write(to: url, atomically: true, encoding: .utf8)
                return url
            }
            XCTAssertNil(try SwiftParse.check(urls), "\(flags)")
        }
    }

    func testTheOutputIsAppSwiftAndNothingElse() throws {
        for (call, input) in [("least", AuthAgent.Input()), ("seer", try Fixture.seer()), ("shelf", try Fixture.shelf())] {
            for (file, text) in try Fixture.emitted(input) {
                let place = "\(call) \(file)"
                XCTAssertFalse(text.contains("import Granite"), "\(place): no Granite in the app's views")
                XCTAssertFalse(text.contains("ObservableObject") || text.contains("@Observable"), "\(place): values and closures in, no store")
                // No stored state: every static is computed, and nothing is declared at the top level but types.
                XCTAssertEqual(text.matches(#"static (let|var) \w+(: [^{=\n]+)? ="#), [], "\(place): no stored statics")
                XCTAssertEqual(text.matches(#"(?m)^(let|var) "#), [], "\(place): no globals")
                // What only iOS has stands inside `#if os(iOS)`, so the files build for the Mac too.
                let everywhere = Self.everywhere(text).joined(separator: "\n")
                for word in ["keyboardType", "textContentType", "textInputAutocapitalization", "navigationBarTitleDisplayMode",
                             "topBarTrailing", "UIImpactFeedbackGenerator", "UITextContentType", "uiColor:", "import UIKit"] {
                    XCTAssertFalse(everywhere.contains(word), "\(place): \(word) outside #if os(iOS)")
                }
                if text.contains(": View {") { XCTAssertTrue(text.contains("#Preview {"), "\(place): every view has a preview") }
            }
            // The one icon-only control, the sheet's close button, says what it does.
            let forgot = try XCTUnwrap(try Fixture.emitted(input).first { $0.key.hasSuffix("AuthForgotView.swift") }?.value)
            XCTAssertEqual(forgot.matches(#"Image\(systemName: "[^"]+"\)\s+\.symbolRenderingMode\(\.hierarchical\)\s+\.foregroundStyle\([^)]+\)\s+\}\s+\.accessibilityLabel\("#).count, 1,
                           "\(call): the close button is labelled")
        }
    }

    /// The lines of `text` every platform reads: outside `#if os(iOS)` and outside the `#else` of `#if os(macOS)`.
    static func everywhere(_ text: String) -> [String] {
        var blocks: [(condition: String, iOSOnly: Bool)] = []
        var lines: [String] = []
        for line in text.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#if ") {
                blocks.append((trimmed, trimmed == "#if os(iOS)"))
            } else if trimmed == "#else", let last = blocks.popLast() {
                blocks.append((last.condition, last.condition == "#if os(macOS)"))
            } else if trimmed == "#endif" {
                _ = blocks.popLast()
            } else if !blocks.contains(where: \.iOSOnly) {
                lines.append(line)
            }
        }
        return lines
    }
}
