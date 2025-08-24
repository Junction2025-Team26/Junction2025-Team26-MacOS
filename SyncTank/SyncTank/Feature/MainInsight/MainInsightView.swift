//
//  CapsuleView.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI


struct MainInsightView: View {
    
    @StateObject private var vm = InsightViewModel()
    
    // 정적 참조 추가
    static var sharedViewModel: InsightViewModel?
    
    // 토스트
    @State private var toastText: String? = nil
    
    // ⬇️ 추가: 전송 중/체크 뱃지 상태
    @State private var isSending = false
    @State private var showCheck = false
    
    var body: some View {
        
        ZStack {
            Color(.mainInsightWindow).ignoresSafeArea()
            
            VStack(spacing: 20) {
                SegmentsView(selected: $vm.selected)
                    .padding(.top, 12)
                
                ScrollView {
                    if vm.pageItems.isEmpty {
                        EmptyItemView(message: "No items yet. Drop files or create a plan.")
                            .padding(.horizontal, 24)
                            .padding(.top, 40)
                    } else {
                        ItemGridView(items: vm.pageItems, onRemove: vm.remove)
                            .padding(.horizontal, 24)
                            .padding(.top, 6)
                    }
                }
                
                // 페이지네이션 (아이템이 6개 초과일 때만 표시)
                if vm.items.count > 6 {
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
                    .padding(.vertical, 24)
                }
            }
            .padding(.bottom, 140)
            
            // 플로팅 캡슐
            CapsuleInputView(
                text: $vm.inputText,
                pendingAttachment: $vm.pendingAttachment,
                pendingFileName: $vm.pendingFileName,
                onSend: {
                    guard !vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty || vm.pendingAttachment != nil else {
                        showToast("Type something or attach a file/photo.")
                        return
                    }
                    Task { @MainActor in
                        await vm.sendAndReload(text: vm.inputText, attachment: vm.pendingAttachment)
                        vm.inputText = ""
                        vm.pendingAttachment = nil
                        vm.pendingFileName = nil
                        showToast("Sent.")
                    }
                },
                onRejectMultiple: {
                    showToast("Only one file or photo can be attached.")
                }
            )
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 24)
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity, alignment: .bottom)
            
            // 토스트
            if let msg = toastText {
                VStack {
                    Spacer()
                    ToastView(text: msg)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 100)
                }
                .animation(.easeInOut(duration: 0.2), value: toastText)
            }
        }
        .frame(width: Metrics.windowWidth, height: Metrics.windowHeight)
        .preferredColorScheme(.dark)
        .onAppear {
            // 정적 참조 설정
            MainInsightView.sharedViewModel = vm
            Task {
                await vm.fetchLatest()
            }
        }
    }
    
    private func showToast(_ text: String) {
        toastText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation { toastText = nil }
        }
    }
}
