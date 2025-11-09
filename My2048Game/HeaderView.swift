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
    let isMuted: Bool // New: To show the correct icon
    let newGameAction: () -> Void
    let undoAction: () -> Void
    let toggleMusicAction: () -> Void // New: Action for the button
    let canUndo: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("2048")
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(.white)
                .frame(width: 80, height: 80) // square box
                .background(Color(hex: "800000")) 
                .cornerRadius(8)
                .shadow(radius: 2)

            Spacer()

            // Scores on the right
            HStack(spacing: 10) {
                ScoreView(title: "SCORE", score: score)
                ScoreView(title: "BEST", score: highScore)
            }
        }
        
        HStack(spacing: 10) {
           
            Button(action: newGameAction) {
                Text("New Game")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(height: 40) // ✅ same height as toggle
                    .padding(.horizontal, 20)
                    .background(Color(hex: "8f7a66"))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            Button(action: undoAction) {
                Text("Undo")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(height: 40)
                    .padding(.horizontal, 20)
                    .background(Color(hex: "8f7a66"))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .opacity(canUndo ? 1 : 0.5)
            }
            .disabled(!canUndo)
            Spacer()
            Button(action: toggleMusicAction) {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 40) // Match overall height with text button
                    .background(Color(hex: "8f7a66"))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            
            
        }
    }
}

#Preview {
    HeaderView(score: 66000, highScore: 66000, isMuted: false, newGameAction: {}, undoAction: {}, toggleMusicAction: {}, canUndo: false)
}
