//
//  SegmentsView.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI

extension InsightViewModel.Tab {
    var index: Int {
        switch self {
        case .all:     return 0
        case .plans:   return 1
        case .insight: return 2
        }
    }
}

struct SegmentsView: View {
    @Binding var selected: InsightViewModel.Tab
    
    private let corner: CGFloat = 23   // 요청: 총 바탕 라디우스 23
    @Namespace private var ns
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(InsightViewModel.Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        selected = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                    // 선택된 것만 "노브"를 그려서 슬라이딩 효과
                        .background(
                            Group {
                                if selected == tab {
                                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                                        .fill(Color("SelectedColor"))
                                        .matchedGeometryEffect(id: "SEGMENT_HILIGHT", in: ns)
                                }
                            }
                        )
                        .contentShape(RoundedRectangle(cornerRadius: corner))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(tab.rawValue))
                .accessibilityAddTraits(selected == tab ? .isSelected : [])
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .contentShape(RoundedRectangle(cornerRadius: corner))
    }
}
