//
//  Models.swift
//  My2048Game
//
//  Created by Hao Liu on 11/8/25.
//

// MARK: - Model

/// A struct to hold the game state for saving and loading.
/// Conforming to Codable allows us to easily encode/decode it to JSON.
struct GameState: Codable {
    var grid: [[Int]]
    var score: Int
}

/// Represents the four possible swipe directions.
enum SwipeDirection {
    case up, down, left, right
}
