//
//  GameOverPlay.swift
//  My2048Game
//
//  Created by Hao Liu on 11/8/25.
//
import SwiftUI

/// A semi-transparent overlay shown when the game is over.
struct GameOverOverlay: View {
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Game Over!")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(Color(hex: "776e65"))
            
            Button(action: retryAction) {
                Text("Try Again")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color(hex: "8f7a66"))
                    .cornerRadius(6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.8))
        .edgesIgnoringSafeArea(.all)
    }
}
