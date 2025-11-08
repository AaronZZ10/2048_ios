//
//  ScoreView.swift
//  My2048Game
//
//  Created by Hao Liu on 11/8/25.
//
import SwiftUI

/// A view for displaying a single score (Current or Best).
struct ScoreView: View {
    let title: String
    let score: Int
    
    var body: some View {
        VStack {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "eee4da"))
            Text(String(score))
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 5)
        .background(Color(hex: "bbada0"))
        .cornerRadius(6)
    }
}

