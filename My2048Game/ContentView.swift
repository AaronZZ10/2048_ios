import SwiftUI



// MARK: - View (SwiftUI)

struct ContentView: View {
    /// Create and observe the one instance of our ViewModel.
    @StateObject private var viewModel = GameViewModel()
    
    /// Size of the gap between tiles.
    private let gridSize: CGFloat = 8.0
    
    var body: some View {
        VStack(spacing: 20) {
            
            HeaderView(score: viewModel.score, highScore: viewModel.highScore) {
                // Action for the "New Game" button
                viewModel.newGame()
            }
            
            GameBoardView()
                .gesture(
                    DragGesture(minimumDistance: 10, coordinateSpace: .local)
                        .onEnded { value in
                            handleSwipe(translation: value.translation)
                        }
                )
            
            Spacer()
        }
        .padding()
        .background(Color(hex: "faf8ef")) // Main background color
        .overlay(
            // Game Over overlay
            Group {
                if viewModel.isGameOver {
                    GameOverOverlay {
                        viewModel.newGame()
                    }
                }
            }
        )
        .onKeyPress { keyPress in
                    // Handle arrow key presses for macOS and iPadOS keyboards
                    switch keyPress.key {
                    case .leftArrow:
                        viewModel.move(.left)
                        return .handled // We handled this key press
                    case .rightArrow:
                        viewModel.move(.right)
                        return .handled
                    case .upArrow:
                        viewModel.move(.up)
                        return .handled
                    case .downArrow:
                        viewModel.move(.down)
                        return .handled
                    default:
                        // Let other keys (like Tab) behave normally
                        return .ignored
                    }
                }
    }
    
    /// The main 4x4 game board.
    @ViewBuilder
    private func GameBoardView() -> some View {
        ZStack {
            // Background grid
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "bbada0"))
            
            VStack(spacing: gridSize) {
                ForEach(0..<4, id: \.self) { r in
                    HStack(spacing: gridSize) {
                        ForEach(0..<4, id: \.self) { c in
                            TileView(value: viewModel.grid[r][c])
                        }
                    }
                }
            }
            .padding(gridSize)
        }
        .frame(maxWidth: 500, maxHeight: 500) // Makes it a responsive square
        .aspectRatio(1, contentMode: .fit)
    }
    
    /// Determines the swipe direction from the drag gesture.
    private func handleSwipe(translation: CGSize) {
        let width = translation.width
        let height = translation.height
        
        // Check for horizontal swipe
        if abs(width) > abs(height) {
            if width > 0 {
                viewModel.move(.right)
            } else {
                viewModel.move(.left)
            }
        } else { // Vertical swipe
            if height > 0 {
                viewModel.move(.down)
            } else {
                viewModel.move(.up)
            }
        }
    }
}





#Preview {
    ContentView()
}
