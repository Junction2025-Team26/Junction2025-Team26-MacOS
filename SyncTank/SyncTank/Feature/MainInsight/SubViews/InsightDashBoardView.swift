//
//  InsightDashBoardView.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI

struct InsightDashboard: View {
    @StateObject private var vm = InsightViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            SegmentsView(selected: $vm.selected)
                .padding(.top, 12)
            
            ScrollView {
                if vm.pageItems.isEmpty {
                    EmptyItemView(message: "No items yet. Drop files or create a plan.")
                        .padding(.horizontal, 24)
                        .padding(.top, 40)
                } else {
                    ItemGridView(items: vm.pageItems, onRemove: { item in
                        vm.remove(item)
                    })
                        .padding(.horizontal, 24)
                        .padding(.top, 6)
                }
                
                // 페이지네이션
                HStack(spacing: 12) {
                    Button { vm.goPrev() } label: {
                        Image(systemName: "chevron.left")
                    }.disabled(vm.page == 0)
                    
                    Text("\(vm.page + 1) / \(vm.pageCount)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    
                    Button { vm.goNext() } label: {
                        Image(systemName: "chevron.right")
                    }.disabled(vm.page >= vm.pageCount - 1)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 18)
            }
        }
        .padding(.bottom, 140) // 하단 입력 캡슐 공간
    }
}
