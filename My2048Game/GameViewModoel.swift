import SwiftUI
import Combine

@MainActor
class GameViewModel: ObservableObject {
    
    // --- Published Properties ---
    /// The main 4x4 game grid, now holding Tile objects.
    @Published var grid: [[Tile?]] = Array(repeating: Array(repeating: nil, count: 4), count: 4)
    
    /// The player's current score.
    @Published var score: Int = 0
    
    /// True when no more moves are possible.
    @Published var isGameOver: Bool = false

    /// True when the player has reached the 2048 tile.
    @Published var didWin: Bool = false
    
    @Published var winMessage: String? = nil
    
    // --- Persistence ---
    @AppStorage("highScore_2048") var highScore: Int = 0
    @AppStorage("hasShownWinPopup_2048") var hasShownWinPopup: Bool = false
    private let userDefaults = UserDefaults.standard
    private let gameStateKey = "savedGameState_2048"
    
    private var startTime: Date?
    
    private var previousState: ([[Tile?]], Int)?
    
    // --- Initialization ---
    init() {
        if !loadGame() {
            newGame()
        }
    }
    
    // MARK: - Game Flow
    
    func newGame() {
        grid = Array(repeating: Array(repeating: nil, count: 4), count: 4)
        score = 0
        isGameOver = false
        didWin = false
        hasShownWinPopup = false
        winMessage = nil;
        startTime = nil;
        previousState = nil
        addRandomTile()
        addRandomTile()
        saveGame()
    }
    
    private func addRandomTile() {
        var emptyCells = [(Int, Int)]()
        for r in 0..<4 {
            for c in 0..<4 {
                if grid[r][c] == nil {
                    emptyCells.append((r, c))
                }
            }
        }
        
        if let (r, c) = emptyCells.randomElement() {
            let value = (Int.random(in: 0..<10) == 0) ? 4 : 2
            grid[r][c] = Tile(value: value)
        }
    }
    
    // MARK: - Persistence Methods
    
    private func saveGame() {
        // Convert [[Tile?]] to [[Int]] for saving
        let intGrid = grid.map { row in
            row.map { $0?.value ?? 0 }
        }
        
        let state = GameState(grid: intGrid, score: score)
        if let data = try? JSONEncoder().encode(state) {
            userDefaults.set(data, forKey: gameStateKey)
        }
        
        if score > highScore {
            highScore = score
        }
    }
    
    private func loadGame() -> Bool {
        guard let data = userDefaults.data(forKey: gameStateKey),
              let state = try? JSONDecoder().decode(GameState.self, from: data) else {
            return false
        }
        
        // Restore state from [[Int]]
        self.score = state.score
        var newGrid = Array(repeating: Array(repeating: nil as Tile?, count: 4), count: 4)
        for r in 0..<4 {
            for c in 0..<4 {
                if state.grid[r][c] > 0 {
                    newGrid[r][c] = Tile(value: state.grid[r][c])
                }
            }
        }
        self.grid = newGrid
        checkGameOver()
        return true
    }

    // MARK: - Game Logic (Move & Merge)
    
    func move(_ direction: SwipeDirection) {
        if isGameOver { return }
        
        previousState = (grid, score)
        
        if startTime == nil {
            startTime = Date()
        }
        
        // New: Reset all merge flags at the start of a move
        resetMergeState()
        
        var (newGrid, didMove) = (grid, false)
        
        // We wrap the grid change in a withAnimation block
        // to tell SwiftUI to animate any changes.
        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            switch direction {
            case .left:
                (newGrid, didMove) = moveLeft(grid)
            case .right:
                (newGrid, didMove) = moveRight(grid)
            case .up:
                (newGrid, didMove) = moveUp(grid)
            case .down:
                (newGrid, didMove) = moveDown(grid)
            }
            
            if didMove {
                self.grid = newGrid
                // Add the new tile *after* the main animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.addRandomTile()
                    self.saveGame()
                    self.checkGameOver()
                }
            }
        }
    }
    
    func undo() {
        guard let lastState = previousState else { return }
        grid = lastState.0
        score = lastState.1
        isGameOver = false
        didWin = false
        saveGame()
    }
    
    // --- Private Move Helpers ---
    
    /// New function to reset the merge state of all tiles.
    private func resetMergeState() {
        for r in 0..<4 {
            for c in 0..<4 {
                grid[r][c]?.isNewlyMerged = false
            }
        }
    }
    
    /// Transforms a single row (now of [Tile?]).
    private func transform(row: [Tile?]) -> (newRow: [Tile?], didChange: Bool, scoreDelta: Int) {
        var newRow: [Tile?] = Array(repeating: nil, count: 4)
        var scoreDelta = 0
        
        // 1. Compact: Filter out nils
        let compacted = row.compactMap { $0 }
        
        // 2. Merge
        var mergedTiles = [Tile]()
        var i = 0
        while i < compacted.count {
            if i + 1 < compacted.count && compacted[i].value == compacted[i+1].value {
                // Merge
                let mergedValue = compacted[i].value * 2
                // We create a NEW tile, flagging it as newly merged.
                mergedTiles.append(Tile(value: mergedValue, isNewlyMerged: true))
                scoreDelta += mergedValue
                if mergedValue == 2048 && !hasShownWinPopup {
                    let elapsed = Int(Date().timeIntervalSince(startTime ?? Date()))
                    let minutes = elapsed / 60
                    let seconds = elapsed % 60
                    winMessage = String(format: "🎉 You reached 2048 in %02d:%02d!", minutes, seconds)
                    didWin = true
                    hasShownWinPopup = true
                    saveGame()
                }
                i += 2 // Skip the next tile
            } else {
                // No merge
                mergedTiles.append(compacted[i])
                i += 1
            }
        }
        
        // 3. Place merged tiles into the new row
        for (index, tile) in mergedTiles.enumerated() {
            newRow[index] = tile
        }

        // Check if the row actually changed
        let didChange = (newRow != row)
        
        return (newRow, didChange, scoreDelta)
    }
    
    private func moveLeft(_ grid: [[Tile?]]) -> (newGrid: [[Tile?]], didMove: Bool) {
        var newGrid = grid
        var didMove = false
        var scoreDelta = 0
        
        for r in 0..<4 {
            let (row, changed, delta) = transform(row: grid[r])
            newGrid[r] = row
            scoreDelta += delta
            if changed { didMove = true }
        }
        
        if didMove { score += scoreDelta }
        return (newGrid, didMove)
    }
    
    private func moveRight(_ grid: [[Tile?]]) -> (newGrid: [[Tile?]], didMove: Bool) {
        var newGrid = grid
        var didMove = false
        var scoreDelta = 0
        
        for r in 0..<4 {
            // Reverse -> Transform -> Reverse
            let reversedRow = grid[r].reversed()
            let (transformed, changed, delta) = transform(row: Array(reversedRow))
            newGrid[r] = transformed.reversed()
            scoreDelta += delta
            if changed { didMove = true }
        }
        
        if didMove { score += scoreDelta }
        return (newGrid, didMove)
    }
    
    /// Transposes a 2D array (flips rows and columns).
    private func transpose(_ grid: [[Tile?]]) -> [[Tile?]] {
        var newGrid = Array(repeating: Array(repeating: nil as Tile?, count: 4), count: 4)
        for r in 0..<4 {
            for c in 0..<4 {
                newGrid[c][r] = grid[r][c]
            }
        }
        return newGrid
    }

    private func moveUp(_ grid: [[Tile?]]) -> (newGrid: [[Tile?]], didMove: Bool) {
        // Transpose -> Move Left -> Transpose
        let transposedGrid = transpose(grid)
        let (movedGrid, didMove) = moveLeft(transposedGrid)
        let newGrid = transpose(movedGrid)
        return (newGrid, didMove)
    }

    private func moveDown(_ grid: [[Tile?]]) -> (newGrid: [[Tile?]], didMove: Bool) {
        // Transpose -> Move Right -> Transpose
        let transposedGrid = transpose(grid)
        let (movedGrid, didMove) = moveRight(transposedGrid)
        let newGrid = transpose(movedGrid)
        return (newGrid, didMove)
    }
    
    // MARK: - Game Over Logic
    
    private func checkGameOver() {
        if hasEmptyCells() {
            isGameOver = false
            return
        }
        
        if canMerge() {
            isGameOver = false
            return
        }
        
        isGameOver = true
    }
    
    private func hasEmptyCells() -> Bool {
        return grid.flatMap { $0 }.contains(nil)
    }
    
    private func canMerge() -> Bool {
        for r in 0..<4 {
            for c in 0..<4 {
                guard let value = grid[r][c]?.value else { continue }
                
                // Check right
                if c + 1 < 4 && grid[r][c+1]?.value == value {
                    return true
                }
                // Check down
                if r + 1 < 4 && grid[r+1][c]?.value == value {
                    return true
                }
            }
        }
        return false
    }
}
