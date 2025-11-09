//
//  ScoreView.swift
//  My2048Game
//
//  Created by Hao Liu on 11/8/25.
//
import SwiftUI

struct ScoreView: View {
    let title: String
    let score: Int

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: "eee4da"))
            Text("\(score)")
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.white)
                .minimumScaleFactor(0.5)
        }
        .frame(width: 80, height: 80) // 🟫 make square like logo
        .background(Color(hex: "bbada0"))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}



