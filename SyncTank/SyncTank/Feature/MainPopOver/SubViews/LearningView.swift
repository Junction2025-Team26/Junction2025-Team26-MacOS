//
//  LearningView.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/24/25.
//

import SwiftUI

struct LearningView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 80, height: 80)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            // 회전하는 아이콘
            Image(systemName: "arrow.2.circlepath.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
                .rotationEffect(.degrees(animate ? 360 : 0))
                .animation(.linear(duration: 1.0).repeatForever(autoreverses: false),
                           value: animate)
        }
        .onAppear { animate = true }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
