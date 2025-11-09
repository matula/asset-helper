import SwiftUI

// MARK: - Color Palette
extension Color {
    // Vibrant primary colors
    static let appPurple = Color(red: 0.5, green: 0.3, blue: 0.9)
    static let appPink = Color(red: 0.95, green: 0.3, blue: 0.6)
    static let appBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let appTeal = Color(red: 0.2, green: 0.8, blue: 0.8)
    static let appOrange = Color(red: 1.0, green: 0.5, blue: 0.2)
    static let appGreen = Color(red: 0.3, green: 0.85, blue: 0.4)

    // Tool-specific colors
    static let tilesheetColor = appPurple
    static let svgColor = appPink
    static let pngColor = appBlue
    static let audioColor = appOrange
}

// MARK: - Gradient Styles
extension LinearGradient {
    static let vibrantPurple = LinearGradient(
        colors: [Color.appPurple, Color.appPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let vibrantBlue = LinearGradient(
        colors: [Color.appBlue, Color.appTeal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let vibrantOrange = LinearGradient(
        colors: [Color.appOrange, Color.appPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let vibrantGreen = LinearGradient(
        colors: [Color.appGreen, Color.appTeal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let rainbow = LinearGradient(
        colors: [.appPurple, .appPink, .appOrange, .appTeal],
        startPoint: .leading,
        endPoint: .trailing
    )
}

extension AngularGradient {
    static let rotating = AngularGradient(
        colors: [.appPurple, .appPink, .appOrange, .appTeal, .appPurple],
        center: .center
    )
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    var gradient: LinearGradient = .vibrantPurple

    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(gradient, lineWidth: 2)
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .shadow(color: .black.opacity(0.15), radius: 15, y: 8)
    }
}

struct AnimatedGradientBorder: ViewModifier {
    @State private var rotation: Double = 0
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        AngularGradient.rotating,
                        lineWidth: 3
                    )
                    .rotationEffect(Angle(degrees: rotation))
            )
            .onAppear {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Button Styles
struct VibrantButtonStyle: ButtonStyle {
    var gradient: LinearGradient = .vibrantPurple

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(gradient)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    var color: Color = .appPurple

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(12)
            .background(
                Circle()
                    .fill(color.opacity(0.2))
            )
            .foregroundColor(color)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle(gradient: LinearGradient = .vibrantPurple) -> some View {
        modifier(CardStyle(gradient: gradient))
    }

    func glassCard() -> some View {
        modifier(GlassCard())
    }

    func animatedGradientBorder(cornerRadius: CGFloat = 16) -> some View {
        modifier(AnimatedGradientBorder(cornerRadius: cornerRadius))
    }

    func vibrantButton(gradient: LinearGradient = .vibrantPurple) -> some View {
        buttonStyle(VibrantButtonStyle(gradient: gradient))
    }

    func iconButton(color: Color = .appPurple) -> some View {
        buttonStyle(IconButtonStyle(color: color))
    }
}

// MARK: - Custom Components
struct FloatingActionButton: View {
    var icon: String
    var gradient: LinearGradient = .vibrantPurple
    var action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(gradient)
                        .shadow(color: .black.opacity(0.3), radius: isHovered ? 15 : 10, y: isHovered ? 8 : 5)
                )
                .scaleEffect(isHovered ? 1.1 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.3)) {
                isHovered = hovering
            }
        }
    }
}
