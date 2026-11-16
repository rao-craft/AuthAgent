//  WHAT: The template of `AuthMark.swift`: the app's mark (a view of its own, or a symbol) at the head of Sign In and Sign
//        Up, sized and spaced, and shadowed and turned when the call asks.

extension Template {
    static let authMark = ##"""
    import SwiftUI

    /// The app's mark at the head of Sign In and Sign Up, at its size, with the space the head gives it; a view of the
    /// app's is drawn as it draws itself.
    struct AuthMark: View {
        //@if mark.turns
        @State private var angle: Double = 0
        //@endif

        var body: some View {
            //@if mark.symbol
            Image(systemName: {{mark}})
                .resizable()
                .scaledToFit()
                .foregroundStyle(AuthLook.secondaryForeground)
            //@else
            {{mark}}
            //@endif
                .frame(width: {{t:mark.size}}, height: {{t:mark.size}})
                .padding(.vertical, {{t:mark.padding}})
                //@if mark.shadow
                .shadow({{t:mark.shadow}})
                //@endif
                //@if mark.turns
                .rotationEffect(.degrees(angle))
                .onAppear {
                    withAnimation(.linear(duration: {{t:mark.turn}}).repeatForever(autoreverses: false)) {
                        angle = 360
                    }
                }
                //@endif
                .padding(.bottom, {{t:mark.below}})
                .accessibilityHidden(true)
        }
    }

    #Preview {
        AuthMark()
    }
    """##
}
