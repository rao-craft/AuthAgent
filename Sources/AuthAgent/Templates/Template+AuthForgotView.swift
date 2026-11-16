//  WHAT: The template of `AuthForgotView.swift`, the reset sheet: its name in the bar and a close button, a glyph, what
//        happens, an email and the button.

extension Template {
    static let authForgotView = ##"""
    import SwiftUI

    /// The reset sheet: its name in the bar and a close button, a glyph, what happens, an email and the button. Once
    /// `reset` returns, `sent` takes the email on (the flow closes the sheet and asks for the code); with no `sent`, the
    /// sheet says the code is on its way.
    struct AuthForgotView: View {
        /// Sends the reset code; nil leaves the button out.
        var reset: (@MainActor (_ email: String) async throws -> Void)?
        /// Called with the email once `reset` returns.
        var sent: ((_ email: String) -> Void)?

        @Environment(\.dismiss) private var dismiss
        @State private var email = ""
        @State private var message: String?
        @State private var notice: String?
        @State private var busy = false
        @FocusState private var focused: Bool

        /// The button acts once there is an email.
        private var ready: Bool { !email.trimmingCharacters(in: .whitespaces).isEmpty }

        var body: some View {
            NavigationStack {
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: {{t:header.spacing}}) {
                        Image(systemName: {{t:forgot.glyph}})
                            .font(AuthLook.glyph)
                            .foregroundStyle(AuthLook.secondaryForeground)
                            .padding(.bottom, {{t:forgot.glyphBelow}})
                            .accessibilityHidden(true)
                        Text({{s:forgot.instruction}})
                            .font(AuthLook.instruction)
                            .foregroundStyle(AuthLook.secondaryForeground)
                            .multilineTextAlignment(.center)
                            .lineSpacing({{t:forgot.lineSpacing}})
                    }
                    .padding(.bottom, {{t:forgot.headerBelow}})
                    .padding(.horizontal, {{t:fields.inset}})
                    AuthField({{s:email}}, text: $email, kind: .email)
                        .focused($focused)
                        .submitLabel(.send)
                        .onSubmit { send() }
                        .padding(.horizontal, {{t:fields.inset}})
                    if let message {
                        Text(message)
                            .font(AuthLook.sheetMessage)
                            .foregroundStyle(AuthLook.danger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, {{t:fields.inset}})
                            .padding(.top, {{t:message.above}})
                    }
                    if let notice {
                        Text(notice)
                            .font(AuthLook.sheetMessage)
                            .foregroundStyle(AuthLook.secondaryForeground)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, {{t:fields.inset}})
                            .padding(.top, {{t:message.above}})
                    }
                    if reset != nil {
                        AuthButton({{s:forgot.button}}, enabled: ready, busy: busy, action: send)
                            .padding(.horizontal, {{t:button.inset}})
                            .padding(.top, {{t:button.above}})
                    }
                    Spacer()
                }
                .toolbar {
                    ToolbarItem(placement: Self.closing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: {{t:forgot.closeGlyph}})
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(AuthLook.accent)
                        }
                        .accessibilityLabel({{s:forgot.close}})
                    }
                    ToolbarItem(placement: .principal) {
                        Text({{s:forgot.title}})
                            .font(AuthLook.sheetTitle)
                            .foregroundStyle(AuthLook.titleColor)
                    }
                }
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
            }
            .onAppear { focused = true }
            .onTapGesture { focused = false }
        }

        /// Where the close button sits: the trailing end of the bar.
        private static var closing: ToolbarItemPlacement {
            #if os(iOS)
            return .topBarTrailing
            #else
            return .primaryAction
            #endif
        }

        /// Return and the button: sends the reset code, then hands the email on.
        private func send() {
            guard ready, !busy, let reset else { return }
            let address = email.trimmingCharacters(in: .whitespaces)
            focused = false
            message = nil
            notice = nil
            busy = true
            Task {
                do {
                    try await reset(address)
                    if let sent {
                        sent(address)
                    } else {
                        notice = {{s:forgot.sent}}
                    }
                } catch {
                    message = AuthFlow.reason(error)
                }
                busy = false
            }
        }
    }

    #Preview {
        Color.clear
            .sheet(isPresented: .constant(true)) {
                AuthForgotView(reset: { _ in }, sent: { _ in })
                    .presentationDetents({{t:forgot.detents}})
                    .presentationDragIndicator(.visible)
            }
    }
    """##
}
