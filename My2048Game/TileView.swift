import SwiftUI

/// Displays a single tile on the board.
struct TileView: View {
    let tile: Tile // Changed from `value: Int`
    
    // New @State for managing the pop animation
    @State private var scale: CGFloat = 1.0
    
    // Dynamically get colors based on the tile value
    private var backgroundColor: Color {
        return tileColors[tile.value, default: Color(hex: "cdc1b4")]
    }
    
    private var foregroundColor: Color {
        return (tile.value == 2 || tile.value == 4) ? Color(hex: "776e65") : .white
    }
    
    private var fontSize: CGFloat {
        switch tile.value {
        case 0...64: return 36
        case 128...512: return 32
        case 1024...2048: return 24
        default: return 20
        }
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(backgroundColor)
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                // Show number only if value is not 0
                Group {
                    if tile.value > 0 {
                        Text(String(tile.value))
                            .font(.system(size: fontSize, weight: .bold))
                            .foregroundColor(foregroundColor)
                            .minimumScaleFactor(0.5) // Allow text to shrink
                    }
                }
            )
            // --- This is the new animation part ---
            .scaleEffect(scale) // Use the @State variable
            .onAppear {
                // This closure fires when the TileView appears on screen.
                
                if tile.isNewlyMerged {
                    // This is a merged tile.
                    // Start with a "pop"
                    scale = 1.2
                    // After 0.1s, animate back to normal.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.1, dampingFraction: 0.6)) {
                            scale = 1.0
                        }
                    }
                } else {
                    // This is a brand new (non-merged) tile.
                    // The transition in ContentView handles its scale-in.
                    scale = 1.0
                }
            }
    }
    
    // --- Tile Color Map ---
    private let tileColors: [Int: Color] = [
        0: Color(hex: "cdc1b4").opacity(0.35), // Empty tile
        2: Color(hex: "eee4da"),
        4: Color(hex: "ede0c8"),
        8: Color(hex: "f2b179"),
        16: Color(hex: "f59563"),
        32: Color(hex: "f67c5f"),
        64: Color(hex: "f65e3b"),
        128: Color(hex: "edcf72"),
        256: Color(hex: "edcc61"),
        512: Color(hex: "edc850"),
        1024: Color(hex: "edc53f"),
        2048: Color(hex: "edc22e"),
        4096: Color(hex: "800000")
    ]
}


// MARK: - Utility

/// Helper extension to initialize a Color from a hex string.
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xff0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00ff00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000ff) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
