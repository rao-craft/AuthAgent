//  WHAT: The template of `AuthCodeView.swift`: the glyph, a title, where the code went, the code field (digits only,
//        number pad, wide tracking, the last digit sends it), a caption, the button and a way back.

extension Template {
    static let authCodeView = ##"""
    import SwiftUI

    /// The one-time code: a glyph, a title, where the code went, the code field, a caption, the button and a way back.
    /// It confirms a new account's email, or with `reset` a reset's; the field keeps digits only and the last one sends.
    struct AuthCodeView: View {
        /// Where the code went.
        var email: String
        /// Whether the code confirms a reset: the title and the button say so.
        var reset: Bool = false
        /// Checks the code; nil leaves the button out.
        var verify: (@MainActor (_ email: String, _ code: String) async throws -> Void)?
        /// Sends the code again; nil leaves the link out.
        var resend: (@MainActor (_ email: String) async throws -> Void)?
        /// Back to the screen before, for another email; nil leaves the link out.
        var back: (() -> Void)?

        @State private var code = ""
        @State private var message: String?
        @State private var busy = false
        @FocusState private var focused: Bool

        private var title: LocalizedStringKey { reset ? {{s:code.resetTitle}} : {{s:code.title}} }
        private var button: LocalizedStringKey { reset ? {{s:code.resetButton}} : {{s:code.button}} }

        /// The button acts once every digit is there.
        private var ready: Bool { code.count == {{t:code.length}} }

        var body: some View {
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: {{t:header.spacing}}) {
                    Image(systemName: {{t:code.glyph}})
                        .font(AuthLook.glyph)
                        .foregroundStyle(AuthLook.secondaryForeground)
                        .padding(.bottom, {{t:code.glyphBelow}})
                        .accessibilityHidden(true)
                    Text(title)
                        .font(AuthLook.codeTitle)
                        .foregroundStyle(AuthLook.foreground)
                    Text("{{e:code.sent}}\n\(email)")
                        .font(AuthLook.codeBody)
                        .foregroundStyle(AuthLook.secondaryForeground)
                        .multilineTextAlignment(.center)
                        .lineSpacing({{t:code.lineSpacing}})
                        // Both lines, always: a screen squeezed by the keyboard shortens the spacers, never the address.
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, {{t:code.headerBelow}})
                .padding(.horizontal, {{t:code.inset}})
                VStack(spacing: {{t:code.gap}}) {
                    TextField({{s:code.placeholder}}, text: $code)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        #endif
                        .font(AuthLook.codeField)
                        .multilineTextAlignment(.center)
                        .tracking({{t:code.tracking}})
                        .focused($focused)
                        .onChange(of: code) { _, typed in
                            let digits = String(typed.filter { $0.isASCII && $0.isNumber }.prefix({{t:code.length}}))
                            if digits != typed {
                                code = digits
                            } else if digits.count == {{t:code.length}} {
                                submit()
                            }
                        }
                        .padding(.vertical, {{t:code.fieldPadding}})
                        .background(
                            RoundedRectangle(cornerRadius: {{t:code.fieldRadius}})
                                .fill(AuthLook.codeFill)
                        )
                        .padding(.horizontal, {{t:code.inset}})
                    Text({{s:code.hint}})
                        .font(AuthLook.caption)
                        .foregroundStyle(AuthLook.tertiaryForeground)
                }
                if let message {
                    Text(message)
                        .font(AuthLook.message)
                        .foregroundStyle(AuthLook.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, {{t:code.inset}})
                        .padding(.top, {{t:message.above}})
                }
                if verify != nil {
                    AuthButton(button, enabled: ready, busy: busy, action: submit)
                        .padding(.horizontal, {{t:code.inset}})
                        .padding(.top, {{t:button.above}})
                }
                if let back {
                    // The button's own style tints the link: `.secondary` is the app's accent, a level lighter.
                    Button {
                        back()
                    } label: {
                        Text({{s:code.back}})
                            .font(AuthLook.link)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, {{t:code.backAbove}})
                }
                if resend != nil {
                    Button {
                        sendAgain()
                    } label: {
                        Text({{s:code.resend}})
                            .font(AuthLook.link)
                            .foregroundStyle(AuthLook.accent)
                    }
                    .disabled(busy)
                    .padding(.top, {{t:code.backAbove}})
                }
                Spacer()
            }
            .onAppear { focused = true }
            .onTapGesture { focused = false }
        }

        /// The last digit and the button: checks the code.
        private func submit() {
            guard ready, !busy, let verify else { return }
            let typed = code
            message = nil
            busy = true
            Task {
                do {
                    try await verify(email, typed)
                } catch {
                    message = AuthFlow.reason(error)
                }
                busy = false
            }
        }

        /// The resend link: sends the code again and clears the field.
        private func sendAgain() {
            guard !busy, let resend else { return }
            message = nil
            busy = true
            Task {
                do {
                    try await resend(email)
                    code = ""
                } catch {
                    message = AuthFlow.reason(error)
                }
                busy = false
            }
        }
    }

    #Preview {
        AuthCodeView(email: "name@example.com", verify: { _, _ in }, resend: { _ in }, back: {})
    }
    """##
}
