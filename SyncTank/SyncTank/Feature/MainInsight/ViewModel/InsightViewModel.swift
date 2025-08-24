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
    
    @Published var inputText: String = ""
    @Published var pendingAttachment: AttachmentPayload? = nil
    @Published var pendingFileName: String? = nil
    
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
    func sendAndReload(text: String, attachment: AttachmentPayload?) async {
        print("🔍 sendAndReload 시작")
        
        // Step 1: 서버 저장 요청
        let service = SyncTankService()
        let result = await service.saveDocument(
            id: UUID().uuidString,
            kind: "plan",
            title: text.isEmpty ? "Untitled" : text,
            content: text,
            leftTime: nil,
            attachment: attachment,
            isUpdated: false
        )
        
        switch result {
        case .success:
            print("✅ 저장 성공 → fetch 시작")
            await fetchLatest()
            print("🔍 fetchLatest 완료, items 개수: \(items.count)")
        case .failure(let err):
            print("❌ 저장 실패:", err)
        }
    }
    
    func fetchLatest() async {
        print("🔍 fetchLatest 시작")
        let service = SyncTankService()
        let result = await service.fetchDocuments()
        
        await MainActor.run {
            switch result {
            case .success(let items):
                print("🔍 서버에서 받은 items 개수: \(items.count)")
                withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                    self.items = items.sorted(by: { $0.title > $1.title })
                }
                print("🔍 UI 업데이트 완료, 현재 items 개수: \(self.items.count)")
            case .failure(let error):
                print("❌ fetch 실패: \(error)")
            }
        }
    }
    
}
