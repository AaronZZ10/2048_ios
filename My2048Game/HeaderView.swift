//
//  HeaderView.swift
//  My2048Game
//
//  Created by Hao Liu on 11/8/25.
//
import SwiftUI
struct HeaderView: View {
    let score: Int
    let highScore: Int
    let newGameAction: () -> Void
    
    var body: some View {
        HStack {
            Text("2048")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(Color(hex: "776e65"))
            
            Spacer()
            
            ScoreView(title: "SCORE", score: score)
            ScoreView(title: "BEST", score: highScore)
        }
        
        HStack {
            Spacer()
            Button(action: newGameAction) {
                Text("New Game")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(hex: "8f7a66"))
                    .cornerRadius(6)
            }
        }
    }
}

