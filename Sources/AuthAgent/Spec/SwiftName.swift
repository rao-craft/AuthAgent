//  WHAT: What Swift accepts as a name: a type, a module, a prefix for type names, an SF Symbol's name.

import Foundation

enum SwiftName {
    static func isTypeName(_ text: String) -> Bool {
        text.range(of: #"^[A-Z][A-Za-z0-9_]*$"#, options: .regularExpression) != nil
    }

    /// `SeerKit`, `Foundation`: what an `import` names.
    static func isModuleName(_ text: String) -> Bool {
        text.range(of: #"^[A-Za-z_][A-Za-z0-9_]*$"#, options: .regularExpression) != nil
    }

    /// `envelope.badge`, `lock.rotation`, `person.crop.circle`: lowercase words and digits joined by dots.
    static func isSymbolName(_ text: String) -> Bool {
        text.range(of: #"^[a-z0-9]+(\.[a-z0-9]+)*$"#, options: .regularExpression) != nil
    }

    /// `brandTitle`, `accent`: a bare member, read off the role's own type (`.brandTitle`).
    static func isBareMember(_ text: String) -> Bool {
        text.range(of: #"^[a-z_][A-Za-z0-9_]*$"#, options: .regularExpression) != nil
    }
}
