//
//  GameViewModoel.swift
//  My2048Game
//
//  Created by Hao Liu on 11/8/25.
//

import Combine
import Foundation
import SwiftUI
// MARK: - ViewModel

@MainActor
class GameViewModel: ObservableObject {
    
    // --- Published Properties ---
    /// The main 4x4 game grid.
    @Published var grid: [[Int]] = Array(repeating: Array(repeating: 0, count: 4), count: 4)
    
    /// The player's current score.
    @Published var score: Int = 0
    
    /// True when no more moves are possible.
    @Published var isGameOver: Bool = false
    
    // --- Persistence ---
    /// Uses @AppStorage to automatically save the high score to UserDefaults.
    @AppStorage("highScore_2048") var highScore: Int = 0
    
    /// Standard UserDefaults for saving/loading the game state.
    private let userDefaults = UserDefaults.standard
    private let gameStateKey = "savedGameState_2048"
    
    // --- Initialization ---
    init() {
        // When the app starts, try to load a saved game.
        // If one doesn't exist, start a new game.
        if !loadGame() {
            newGame()
        }
    }
    
    // MARK: - Game Flow
    
    /// Starts a new game from scratch.
    func newGame() {
        grid = Array(repeating: Array(repeating: 0, count: 4), count: 4)
        score = 0
        isGameOver = false
        addRandomTile()
        addRandomTile()
        saveGame() // Save the new game state
    }
    
    /// Adds a new tile (90% chance of '2', 10% chance of '4') to an empty spot.
    private func addRandomTile() {
        var emptyCells = [(Int, Int)]()
        for r in 0..<4 {
            for c in 0..<4 {
                if grid[r][c] == 0 {
                    emptyCells.append((r, c))
                }
            }
        }
        
        if let (r, c) = emptyCells.randomElement() {
            grid[r][c] = (Int.random(in: 0..<10) == 0) ? 4 : 2
        }
    }
    
    // MARK: - Persistence Methods
    
    /// Saves the current grid and score to UserDefaults.
    private func saveGame() {
        let state = GameState(grid: grid, score: score)
        if let data = try? JSONEncoder().encode(state) {
            userDefaults.set(data, forKey: gameStateKey)
        }
        
        // Update high score if needed
        if score > highScore {
            highScore = score
        }
    }
    
    /// Tries to load a saved game state from UserDefaults.
    /// - Returns: `true` if loading was successful, `false` otherwise.
    private func loadGame() -> Bool {
        guard let data = userDefaults.data(forKey: gameStateKey),
              let state = try? JSONDecoder().decode(GameState.self, from: data) else {
            return false
        }
        
        // Restore the saved state
        self.grid = state.grid
        self.score = state.score
        checkGameOver() // Check if the loaded state is already game over
        return true
    }

    // MARK: - Game Logic (Move & Merge)
    
    /// Main public function to handle a swipe.
    func move(_ direction: SwipeDirection) {
        if isGameOver { return }
        
        var (newGrid, didMove) = (grid, false)
        
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
            grid = newGrid
            addRandomTile()
            saveGame() // Save after every successful move
            checkGameOver()
        }
    }
    
    // --- Private Move Helpers ---
    
    /// Transforms a single row/column by compacting, merging, and compacting again.
    /// This is the core logic for a single "left" move.
    private func transform(row: [Int]) -> (newRow: [Int], didChange: Bool, scoreDelta: Int) {
        var newRow = [Int]()
        var scoreDelta = 0
        
        // 1. Compact: Filter out zeros
        let compacted = row.filter { $0 != 0 }
        
        // 2. Merge
        var i = 0
        while i < compacted.count {
            if i + 1 < compacted.count && compacted[i] == compacted[i+1] {
                // Merge
                let mergedValue = compacted[i] * 2
                newRow.append(mergedValue)
                scoreDelta += mergedValue
                i += 2 // Skip the next tile
            } else {
                // No merge
                newRow.append(compacted[i])
                i += 1
            }
        }
        
        // 3. Pad: Fill the rest with zeros
        let padding = Array(repeating: 0, count: 4 - newRow.count)
        newRow.append(contentsOf: padding)
        
        // Check if the row actually changed
        let didChange = (newRow != row)
        
        return (newRow, didChange, scoreDelta)
    }
    
    private func moveLeft(_ grid: [[Int]]) -> (newGrid: [[Int]], didMove: Bool) {
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
    
    private func moveRight(_ grid: [[Int]]) -> (newGrid: [[Int]], didMove: Bool) {
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
    private func transpose(_ grid: [[Int]]) -> [[Int]] {
        var newGrid = Array(repeating: Array(repeating: 0, count: 4), count: 4)
        for r in 0..<4 {
            for c in 0..<4 {
                newGrid[c][r] = grid[r][c]
            }
        }
        return newGrid
    }

    private func moveUp(_ grid: [[Int]]) -> (newGrid: [[Int]], didMove: Bool) {
        // Transpose -> Move Left -> Transpose
        let transposedGrid = transpose(grid)
        let (movedGrid, didMove) = moveLeft(transposedGrid)
        let newGrid = transpose(movedGrid)
        return (newGrid, didMove)
    }

    private func moveDown(_ grid: [[Int]]) -> (newGrid: [[Int]], didMove: Bool) {
        // Transpose -> Move Right -> Transpose
        let transposedGrid = transpose(grid)
        let (movedGrid, didMove) = moveRight(transposedGrid)
        let newGrid = transpose(movedGrid)
        return (newGrid, didMove)
    }
    
    // MARK: - Game Over Logic
    
    /// Checks if the game is over (no empty cells and no possible merges).
    private func checkGameOver() {
        if hasEmptyCells() {
            isGameOver = false
            return
        }
        
        if canMerge() {
            isGameOver = false
            return
        }
        
        // No empty cells and no possible merges
        isGameOver = true
    }
    
    private func hasEmptyCells() -> Bool {
        return grid.flatMap { $0 }.contains(0)
    }
    
    /// Checks for any possible adjacent merges (horizontally or vertically).
    private func canMerge() -> Bool {
        for r in 0..<4 {
            for c in 0..<4 {
                let value = grid[r][c]
                
                // Check right
                if c + 1 < 4 && grid[r][c+1] == value {
                    return true
                }
                // Check down
                if r + 1 < 4 && grid[r+1][c] == value {
                    return true
                }
            }
        }
        return false
    }
}
