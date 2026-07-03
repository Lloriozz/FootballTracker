import SwiftUI

/// Generic segmented control that works with any hashable selection value.
struct GlassSegmentedControl<Selection: Hashable>: View {
    /// Pairs of underlying value and visible label.
    let items: [(Selection, String)]

    /// Bound selection owned by the parent view.
    @Binding var selection: Selection

    /// Renders each segment as a button in a material capsule.
    var body: some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.0) { item in
                Button {
                    // Snappy animation makes the selected pill feel responsive.
                    withAnimation(.snappy) {
                        selection = item.0
                    }
                } label: {
                    Text(item.1)
                        .font(.rounded(.headline, weight: .bold))
                        // Selected segment uses black text on a white pill.
                        .foregroundStyle(selection == item.0 ? Color.black : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            if selection == item.0 {
                                Capsule(style: .continuous).fill(Color.white)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        // Outer padding creates breathing room around the selected capsule.
        .padding(6)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(Theme.glassStroke, lineWidth: 1)
        }
    }
}
