import SwiftUI

extension Color {
    /// Converts a `#RRGGBB` string into a SwiftUI color.
    init(hex: String) {
        // Remove the leading hash if the JSON includes one.
        let normalized = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        // Parse the remaining six hex digits; default to black if invalid.
        let value = UInt64(normalized, radix: 16) ?? 0
        // Extract RGB channels from the packed integer.
        let red = Double((value >> 16) & 0xff) / 255
        let green = Double((value >> 8) & 0xff) / 255
        let blue = Double(value & 0xff) / 255
        // Initialize SwiftUI's color using normalized 0...1 channel values.
        self.init(red: red, green: green, blue: blue)
    }
}
