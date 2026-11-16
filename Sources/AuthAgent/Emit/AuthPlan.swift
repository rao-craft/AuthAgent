//  WHAT: What a call writes: every part of the flow by type, kind and where its text comes from, in the order a page is
//        built from them; then each part made for a call, renamed with its prefix and importing its modules.
//  PIN:  THE WHOLE FLOW, EVERY CALL. A screen a page does not wire is left out by its closure being nil, never by its
//        file, so a later call into the same folder writes the same set and the files always agree.
//  PIN:  THE PREFIX TOUCHES THE KIT'S NAMES ONLY. A template is renamed before the call's values go in, so the app's
//        Swift (its mark, its look) and its words reach the file as the call wrote them.

import Foundation

/// One part of the flow: a type of its own in a file of its own.
struct AuthPart: Sendable, Equatable {
    enum Kind: String, Sendable {
        /// A view a page shows (`AuthFlow`) or one it is built from.
        case view
        /// What the views read: the look, where the flow opens, which screen is up.
        case support
    }

    enum Source: Sendable, Equatable {
        /// A template, rendered with the call's flags and values.
        case template(String)
        /// `AuthLook`, written from the call's look lines.
        case look
        /// `AuthLaunch`, written from the call's launch lines.
        case launch
    }

    let name: String
    let kind: Kind
    let source: Source
    /// Whether it imports the call's modules: the parts that name the app's own Swift. The look imports them itself.
    let importing: Bool
}

/// One file a call writes: its type, file name, kind and text.
struct AuthFile: Sendable, Equatable {
    let name: String
    let file: String
    let kind: AuthPart.Kind
    let text: String
}

enum AuthPlan {
    /// The root view a page shows.
    static let root = "AuthFlow"

    static let parts: [AuthPart] = [
        AuthPart(name: "AuthFlow", kind: .view, source: .template(Template.authFlow), importing: false),
        AuthPart(name: "AuthSignInView", kind: .view, source: .template(Template.authSignInView), importing: false),
        AuthPart(name: "AuthSignUpView", kind: .view, source: .template(Template.authSignUpView), importing: false),
        AuthPart(name: "AuthCodeView", kind: .view, source: .template(Template.authCodeView), importing: false),
        AuthPart(name: "AuthForgotView", kind: .view, source: .template(Template.authForgotView), importing: false),
        AuthPart(name: "AuthField", kind: .view, source: .template(Template.authField), importing: false),
        AuthPart(name: "AuthButton", kind: .view, source: .template(Template.authButton), importing: false),
        AuthPart(name: "AuthMark", kind: .view, source: .template(Template.authMark), importing: true),
        AuthPart(name: "AuthStep", kind: .support, source: .template(Template.authStep), importing: false),
        AuthPart(name: "AuthLook", kind: .support, source: .look, importing: false),
        AuthPart(name: "AuthLaunch", kind: .support, source: .launch, importing: false),
    ]

    /// Every type the kit declares, as a template names it.
    static var names: [String] { parts.map(\.name) }

    /// Every file `call` writes, in the order of `parts`.
    static func files(for call: AuthCall) throws -> [AuthFile] {
        let flags = call.flags
        let values = call.values
        return try parts.map { part in
            var text: String
            switch part.source {
            case .template(let source):
                let renamed = TemplateRender.prefixing(source, names: names, prefix: call.prefix)
                text = try TemplateRender.render(renamed, flags: flags, values: values)
            case .look:
                text = LookEmitter.emit(call)
            case .launch:
                text = LaunchEmitter.emit(call)
            }
            if part.importing { text = importing(text, call.imports) }
            let name = call.prefix + part.name
            return AuthFile(name: name, file: name + ".swift", kind: part.kind, text: text)
        }
    }

    /// `text` with an `import` a module after its `import SwiftUI`.
    static func importing(_ text: String, _ modules: [String]) -> String {
        guard !modules.isEmpty else { return text }
        let lines = modules.map { "import \($0)\n" }.joined()
        guard let range = text.range(of: "import SwiftUI\n") else { return lines + text }
        return text.replacingCharacters(in: range, with: "import SwiftUI\n" + lines)
    }
}
