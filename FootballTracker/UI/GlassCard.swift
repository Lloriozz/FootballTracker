import SwiftUI

/// Reusable glass container for cards, banners, and grouped sections.
struct GlassCard<Content: View>: View {
    /// System accessibility setting that asks apps to avoid translucent materials.
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    /// Rounded corner size for the card.
    var cornerRadius: CGFloat = 28

    /// Inner spacing between the card edge and its content.
    var padding: CGFloat = 20

    /// Optional tint gradient that sits behind the material.
    var gradient: LinearGradient? = nil

    /// Caller-provided card body.
    @ViewBuilder var content: Content

    /// Renders the content on top of material, stroke, and shadow layers.
    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    // The gradient tints the material from behind.
                    .fill(gradient ?? LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                    // Reduce Transparency swaps glass for a more solid fill.
                    .overlay(reduceTransparency ? Theme.bgSecondary.opacity(0.92) : Theme.glassFill)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay {
                // A faint border makes the card readable against dark backgrounds.
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.glassStroke, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.22), radius: 18, x: 0, y: 8)
    }
}

/// Reusable pill-shaped button matching the Apple Sports-style onboarding buttons.
struct GlassPillButton<Label: View>: View {
    /// System accessibility setting that asks apps to avoid translucent materials.
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    /// Prominent buttons use a white fill and dark text.
    var isProminent = false

    /// Action invoked when the button is tapped.
    var action: () -> Void

    /// Caller-provided button label.
    @ViewBuilder var label: Label

    /// Renders the label inside a material-backed capsule.
    var body: some View {
        Button(action: action) {
            label
                .font(.rounded(.headline, weight: .bold))
                .foregroundStyle(isProminent ? Color.black : Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background {
                    Capsule(style: .continuous)
                        // Solid white is used for the main onboarding Continue button.
                        .fill(isProminent ? Color.white : (reduceTransparency ? Theme.bgPrimary.opacity(0.9) : Theme.glassFill))
                        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                }
                .overlay {
                    // The border keeps non-prominent glass buttons visible.
                    Capsule(style: .continuous)
                        .stroke(Theme.glassStroke, lineWidth: 1)
                }
        }
        // Plain style avoids default blue iOS button styling.
        .buttonStyle(.plain)
    }
}

/// A reusable full-screen background that loads a resource image and applies a dark gradient overlay
/// to ensure text and glass components remain readable on top of it.
struct AppBackground: View {
    let imageName: String

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base background color in case the image fails to load
                Theme.bgPrimary.ignoresSafeArea()

                // Background Image
                if let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }

                // Darkening Gradient Overlay for readability
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }
}

/// A reusable glass-styled text field with an optional icon.
struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String?
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(width: 20)
            }

            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundStyle(.white)
                    .tint(Color(hex: "#00C853"))
            } else {
                TextField(placeholder, text: $text)
                    .foregroundStyle(.white)
                    .tint(Color(hex: "#00C853"))
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(reduceTransparency ? Theme.bgSecondary.opacity(0.9) : Theme.glassFill)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.glassStroke, lineWidth: 1)
        }
    }
}

/// A standard glass-morphism container specifically designed for list rows.
struct GlassListRow<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(reduceTransparency ? Theme.bgSecondary.opacity(0.9) : Theme.glassFill)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.glassStroke, lineWidth: 1)
            }
            // Add padding so it looks like a floating card within a List
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
    }
}
