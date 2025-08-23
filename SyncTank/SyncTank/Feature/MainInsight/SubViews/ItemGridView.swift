//
//  ItemGridView.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI

struct ItemGridView: View {
    let items: [DashItem]
    
    private let columns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 24) {
            ForEach(items) { item in
                switch item.kind {
                case .plan, .insight:
                    TextCardView(item: item)          // 텍스트 + (있다면) 오른쪽 첨부
                case .attachment:
                    AttachmentOnlyCardView(item: item) // 첨부 전용 카드
                }
            }
        }
    }
}
