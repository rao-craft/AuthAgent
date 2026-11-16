//  WHAT: The template of `AuthButton.swift`, the outlined button: a full-width label in a thin rounded border, no
//        fill; label and border faint while it cannot act or is busy, a spinner for the label while busy.

extension Template {
    static let authButton = ##"""
    import SwiftUI

    /// The outlined button: a full-width label in a thin rounded border, no fill. While it cannot act or is busy, label
    /// and border go faint; busy swaps the label for a spinner. A tap that acts is felt.
    struct AuthButton: View {
        private let title: LocalizedStringKey
        private let enabled: Bool
        private let busy: Bool
        private let action: @MainActor () -> Void

        init(_ title: LocalizedStringKey, enabled: Bool = true, busy: Bool = false, action: @escaping @MainActor () -> Void) {
            self.title = title
            self.enabled = enabled
            self.busy = busy
            self.action = action
        }

        /// Whether a tap acts: enabled and not busy.
        private var acting: Bool { enabled && !busy }

        var body: some View {
            Button {
                guard acting else { return }
                action()
                AuthLook.impact()
            } label: {
                ZStack {
                    if busy {
                        ProgressView()
                            .tint(AuthLook.spinner)
                            .scaleEffect({{t:button.spinner}})
                    } else {
                        Text(title)
                            .font(AuthLook.button)
                            .foregroundStyle(acting ? AuthLook.control : AuthLook.controlFaint)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: {{t:button.height}})
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: {{t:button.radius}})
                        .stroke(acting ? AuthLook.control : AuthLook.controlFaint, lineWidth: {{t:button.border}})
                )
            }
            .disabled(!acting)
            .animation({{t:press}}, value: enabled)
            .animation({{t:press}}, value: busy)
        }
    }

    #Preview {
        VStack(spacing: 16) {
            AuthButton("Continue", action: {})
            AuthButton("Continue", enabled: false, action: {})
            AuthButton("Continue", busy: true, action: {})
        }
        .padding(.horizontal, 50)
    }
    """##
}
