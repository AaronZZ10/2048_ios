import SwiftUI
import AVFoundation // Import the audio-visual framework

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    private let gridSize: CGFloat = 8.0
    
    // State variable to hold the audio player
    @State private var audioPlayer: AVAudioPlayer?
    
    // Persistently store the mute state
    @AppStorage("isMusicMuted") private var isMusicMuted: Bool = false
    
    @State private var canUndo: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            
            HeaderView(
                score: viewModel.score,
                highScore: viewModel.highScore,
                isMuted: isMusicMuted, // Pass the state
                newGameAction: {
                    viewModel.newGame()
                },
                undoAction:{
                    viewModel.undo()
                    canUndo = false
                },
                toggleMusicAction: { // Pass the toggle action
                    toggleMusic()
                },
                canUndo: canUndo
            )
            
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
        .background(Color(hex: "faf8ef"))
        .alert(viewModel.winMessage ?? "🎉 You reached 2048!", isPresented: $viewModel.didWin) {
            Button("Continue", role: .cancel) {
                viewModel.didWin = false
                viewModel.winMessage = nil
            }
        }
        .overlay(
            Group {
                if viewModel.isGameOver {
                    GameOverOverlay {
                        viewModel.newGame()
                    }
                }
            }
        )
        .focusable()
        .onKeyPress { keyPress in
            switch keyPress.key {
            case .leftArrow:
                viewModel.move(.left)
                canUndo = true
                return .handled
            case .rightArrow:
                viewModel.move(.right)
                canUndo = true
                return .handled
            case .upArrow:
                viewModel.move(.up)
                canUndo = true
                return .handled
            case .downArrow:
                viewModel.move(.down)
                canUndo = true
                return .handled
            default:
                return .ignored
            }
        }
        .onAppear {
            // When the view appears, start the music (if not muted)
            playMusic()
        }
    }
    
    /// The main 4x4 game board.
    @ViewBuilder
    private func GameBoardView() -> some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            // Calculate size of one tile
            let tileSize = (totalWidth - (gridSize * 5)) / 4.0
            
            ZStack {
                // Layer 1: The main background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: "bbada0"))
                
                // Layer 2: The 16 empty cell backgrounds
                VStack(spacing: gridSize) {
                    ForEach(0..<4, id: \.self) { _ in
                        HStack(spacing: gridSize) {
                            ForEach(0..<4, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: "cdc1b4").opacity(0.35))
                                    .frame(width: tileSize, height: tileSize)
                            }
                        }
                    }
                }
                .padding(gridSize)
                
                // Layer 3: The actual, moving tiles
                // We flatten the grid into a 1D array of tiles that have
                // a position, so we can render them in one ForEach.
                let tiles = viewModel.grid.enumerated().flatMap { (r, row) in
                    row.enumerated().compactMap { (c, tile) in
                        tile.map { (tile: $0, r: r, c: c) }
                    }
                }
                
                ForEach(tiles, id: \.tile.id) { item in
                    TileView(tile: item.tile)
                        .frame(width: tileSize, height: tileSize)
                        // Calculate the (x, y) position for this tile
                        .position(
                            x: (tileSize + gridSize) * CGFloat(item.c) + (tileSize / 2) + gridSize,
                            y: (tileSize + gridSize) * CGFloat(item.r) + (tileSize / 2) + gridSize
                        )
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }
            .frame(width: totalWidth, height: totalWidth)
        }
        .frame(maxWidth: 500, maxHeight: 500)
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func handleSwipe(translation: CGSize) {
        // ... (this function remains unchanged)
        let width = translation.width
        let height = translation.height
        
        if abs(width) > abs(height) {
            if width > 0 {
                viewModel.move(.right)
                canUndo = true
            } else {
                viewModel.move(.left)
                canUndo = true
            }
        } else {
            if height > 0 {
                viewModel.move(.down)
                canUndo = true
            } else {
                viewModel.move(.up)
                canUndo = true
            }
        }
    }
    
    /// Finds, prepares, and plays the background music.
    private func playMusic() {
        // IMPORTANT: Add a music file named "background-music.mp3"
        // to your Xcode project for this to work.
        guard let soundURL = Bundle.main.url(forResource: "background-music", withExtension: "mp3") else {
            print("Could not find music file: background-music.mp3")
            return
        }
        
        do {
            // Initialize the audio player
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.prepareToPlay()
            
            // Only play if not muted
            if !isMusicMuted {
                audioPlayer?.play()
            }
        } catch {
            print("Error initializing audio player: \(error.localizedDescription)")
        }
    }
    
    /// Toggles the music state on or off.
    private func toggleMusic() {
        isMusicMuted.toggle()
        
        if isMusicMuted {
            audioPlayer?.stop()
        } else {
            // If player doesn't exist yet, create it
            if audioPlayer == nil {
                playMusic()
            } else {
                // Otherwise, just resume playing
                audioPlayer?.play()
            }
        }
    }
}

#Preview{
    ContentView()
}
