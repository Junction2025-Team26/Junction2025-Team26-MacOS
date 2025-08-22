//
//  EmptyItemView.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

// Features/Insight/Views/EmptyStateView.swift
import SwiftUI

struct EmptyItemView: View {
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 36, weight: .light))
            Text(message)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, minHeight: 280)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.04)))
    }
}
