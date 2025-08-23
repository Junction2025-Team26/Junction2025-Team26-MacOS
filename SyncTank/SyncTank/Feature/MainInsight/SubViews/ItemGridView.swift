//
//  ItemGridView.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI

struct ItemGridView: View {
    let items: [DashItem]
    var onRemove: (DashItem) -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 24) {
            ForEach(items) { item in
                ResponseCardView(item: item, onRemove: onRemove)
            }
        }
    }
}
