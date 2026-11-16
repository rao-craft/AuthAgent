//  WHAT: A call read whole: its mark, the look roles it maps, every word and every tuning value (the call's, else the
//        default), its launch states, the prefix and imports; and from them the flags and the values the templates
//        are filled with.
//  PIN:  EVERY PROBLEM AT ONCE. Each line is read even after one fails, so a refusal names all of them and one more
//        call fixes the lot; nothing is planned until there are none.

import Foundation

struct AuthCall: Sendable {
    let mark: Mark
    /// Role name → the Swift the call maps it to; a role left out reads the system's.
    let look: [String: String]
    /// Key → the words, the call's or the default, for every key.
    let words: [String: String]
    /// Key → the value, the call's or the default, for every key.
    let tuning: [String: TuningValue]
    let launch: [LaunchState]
    let prefix: String
    let imports: [String]
    let into: String
    /// The keys and roles the call set, for the answer's notes.
    let setWords: Set<String>
    let setTuning: Set<String>

    static let defaultInto = "Components/Auth"

    static func read(_ input: AuthAgent.Input) throws(AuthError) -> AuthCall {
        var problems: [String] = []

        var mark = Mark.fallback
        do { mark = try Mark.read(input.mark) } catch { problems.append("\(error)") }

        var look: [String: String] = [:]
        for line in input.look ?? [] where !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                let assignment = try LookLine.parse(line)
                if look[assignment.role.name] != nil {
                    problems.append("look `\(line)`: `\(assignment.role.name)` is mapped twice; keep one line a role")
                } else {
                    look[assignment.role.name] = assignment.expression
                }
            } catch { problems.append("\(error)") }
        }

        var words = Dictionary(uniqueKeysWithValues: StringKeys.all.map { ($0.key, $0.english) })
        var setWords: Set<String> = []
        for line in input.strings ?? [] where !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                let assignment = try StringLine.parse(line)
                if !setWords.insert(assignment.key.key).inserted {
                    problems.append("strings `\(line)`: `\(assignment.key.key)` is set twice; keep one line a key")
                } else {
                    words[assignment.key.key] = assignment.words
                }
            } catch { problems.append("\(error)") }
        }

        var tuning: [String: TuningValue] = [:]
        for key in TuningKeys.all {
            if case .success(let value) = TuningValueReader.read(key.fallback, for: key) { tuning[key.key] = value }
        }
        var setTuning: Set<String> = []
        for line in input.tuning ?? [] where !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                let assignment = try TuningLine.parse(line)
                if !setTuning.insert(assignment.key.key).inserted {
                    problems.append("tuning `\(line)`: `\(assignment.key.key)` is set twice; keep one line a key")
                } else {
                    tuning[assignment.key.key] = assignment.value
                }
            } catch { problems.append("\(error)") }
        }

        var launch: [LaunchState] = []
        for line in input.launch ?? [] where !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                let state = try LaunchLine.parse(line)
                if launch.contains(where: { $0.destination == state.destination }) {
                    problems.append("launch `\(line)`: `\(state.destination)` is named twice; one line a destination")
                } else {
                    launch.append(state)
                }
            } catch { problems.append("\(error)") }
        }

        let prefix = (input.prefix ?? "").trimmingCharacters(in: .whitespaces)
        if !prefix.isEmpty, !SwiftName.isTypeName(prefix) {
            problems.append("prefix `\(prefix)`: not a prefix for type names; UpperCamelCase letters and digits, like `Kit`")
        }
        var imports: [String] = []
        for module in (input.imports ?? []).map({ $0.trimmingCharacters(in: .whitespaces) }) where !module.isEmpty {
            if !SwiftName.isModuleName(module) {
                problems.append("imports `\(module)`: not a module name")
            } else if module != "SwiftUI", !imports.contains(module) {
                imports.append(module)
            }
        }
        let into = (input.into ?? "").trimmingCharacters(in: .whitespaces)
        guard problems.isEmpty else { throw .problems(problems) }
        return AuthCall(mark: mark, look: look, words: words, tuning: tuning, launch: launch, prefix: prefix, imports: imports,
                        into: into.isEmpty ? defaultInto : into, setWords: setWords, setTuning: setTuning)
    }

    // MARK: - What the templates read

    /// The conditions a template's `//@if` blocks test.
    var flags: Set<String> {
        var flags: Set<String> = []
        if case .symbol = mark { flags.insert("mark.symbol") }
        if tuning["mark.turn"]?.isNone == false { flags.insert("mark.turns") }
        if tuning["mark.shadow"]?.isNone == false { flags.insert("mark.shadow") }
        if tuning["haptic"]?.isNone == false { flags.insert("haptic") }
        if words["signIn.refused"]?.isEmpty == false { flags.insert("signIn.refused") }
        if words["signIn.invalid"]?.isEmpty == false { flags.insert("signIn.check") }
        return flags
    }

    /// What each `{{…}}` in a template is filled with: `s:key` a word as a Swift literal, `e:key` the same without its
    /// quotes (inside a literal that interpolates), `t:key` a tuning value as SwiftUI spells it, `mark` the mark.
    var values: [String: String] {
        var values: [String: String] = [:]
        for (key, text) in words {
            values["s:" + key] = SwiftLiteral.quoted(text)
            values["e:" + key] = SwiftLiteral.escaped(text)
        }
        // A sign-in the screen refuses itself reads as one sentence: "Unauthorized: Invalid login credentials".
        values["s:signIn.refusedInvalid"] = SwiftLiteral.quoted((words["signIn.refused"] ?? "") + (words["signIn.invalid"] ?? ""))
        for (key, value) in tuning { values["t:" + key] = value.swift }
        switch mark {
        case .symbol(let name): values["mark"] = SwiftLiteral.quoted(name)
        case .view(let expression): values["mark"] = expression
        }
        return values
    }
}
