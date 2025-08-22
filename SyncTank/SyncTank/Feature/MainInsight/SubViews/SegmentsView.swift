//
//  SegmentsView.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI

struct SegmentsView: View {
    @Binding var selected: InsightViewModel.Tab

    var body: some View {
        HStack(spacing: 8) {
            ForEach(InsightViewModel.Tab.allCases, id: \.self) { tab in
                Button {
                    selected = tab
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 18).padding(.vertical, 8)
                        .background(
                            Capsule().fill(selected == tab ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.06)))
    }
}
