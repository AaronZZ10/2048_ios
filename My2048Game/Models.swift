//
//  Models.swift
//  My2048Game
//
//  Created by Hao Liu on 11/8/25.
//

// MARK: - Model

/// A struct to hold the game state for saving and loading.
/// Conforming to Codable allows us to easily encode/decode it to JSON.
import Foundation

/// A struct to hold the game state for saving and loading.
/// Conforming to Codable allows us to easily encode/decode it to JSON.
struct GameState: Codable {
    var grid: [[Int]] // We still save as [[Int]] for simplicity
    var score: Int
}

/// Represents a single tile on the board.
/// It's Identifiable so SwiftUI can track it for animations.
struct Tile: Identifiable, Equatable {
    let id: UUID = UUID() // Stable, unique ID
    var value: Int
    var isNewlyMerged: Bool = false
    
    // Equatable conformance
    static func == (lhs: Tile, rhs: Tile) -> Bool {
        lhs.id == rhs.id && lhs.value == rhs.value
    }
}

/// Represents the four possible swipe directions.
enum SwipeDirection {
    case up, down, left, right
}
