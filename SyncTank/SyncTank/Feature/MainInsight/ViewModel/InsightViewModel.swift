//
//  InsightViewModel.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI

@MainActor
final class InsightViewModel: ObservableObject {
    enum Tab: String, CaseIterable { case all = "All", plans = "Plans", insight = "Insight" }
    
    @Published var selected: Tab = .all
    @Published var page: Int = 0
    
    @Published var items: [DashItem] = []
    
    let pageSize = 6   // 3열 × 2행
    
    var filtered: [DashItem] {
        switch selected {
        case .all:   return items
        case .plans: return items.filter { $0.kind == .plan }
        case .insight: return items.filter { $0.kind == .insight }
        }
    }
    
    var pageCount: Int {
        let c = filtered.count
        return max(1, Int(ceil(Double(c) / Double(pageSize))))
    }
    
    var pageItems: [DashItem] {
        let start = page * pageSize
        let end = min(filtered.count, start + pageSize)
        guard start < end else { return [] }
        return Array(filtered[start..<end])
    }
    
    func goPrev() { page = max(0, page - 1) }
    func goNext() { page = min(pageCount - 1, page + 1) }
    
    func categoryOnChangeTab(_ t: Tab) {
        selected = t
        page = 0
    }
    
    func remove(_ item: DashItem) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            items.removeAll { $0.id == item.id }
        }
        // 페이지 보정
        page = min(page, max(0, pageCount - 1))
    }
    
    // 캡슐에서 Send 눌렀을 때 추가 (디폴트 .plan)
    func addFromComposer(text: String, attachment: AttachmentPayload?) {
        let newItem = DashItem(
            kind: .plan,
            title: text.isEmpty ? "Untitled" : text,
            content: attachment?.isImage == true ? "Attached an image." :
                (attachment != nil ? "Attached a file." : "Text only."),
            attachment: attachment
        )
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            items.insert(newItem, at: 0)
        }
    }
    
}
