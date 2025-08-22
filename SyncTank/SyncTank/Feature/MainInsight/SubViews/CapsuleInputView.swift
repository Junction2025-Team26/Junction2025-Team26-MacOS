//
//  CapsuleInputView.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//
import SwiftUI

struct CapsuleInputView: View {
    @Binding var text: String
    var onSend: (String) -> Void = { _ in }
    
    var body: some View {
        HStack(spacing: 12) {
            
            CapsulePlaceHolderView(text: $text, onSend: onSend)
                .padding(.leading, 20)
            
            Button {
                onSend(text)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 14)
        }
        .frame(width: Metrics.capsuleWidth, height: Metrics.capsuleHeight)
        .background(
            RoundedRectangle(cornerRadius: Metrics.capsuleCorner, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.capsuleCorner, style: .continuous)
                .stroke(Color.white.opacity(Metrics.capsuleStrokeOpacity), lineWidth: 1)
        )
        .shadow(radius: 8, y: 4)
    }
}
