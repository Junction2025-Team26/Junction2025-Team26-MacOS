//
//  CapsuleView.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI


struct MainInsightView: View {
    @StateObject private var vm = InsightViewModel()
    
    // 입력 상태
    @State private var input = ""
    @State private var pendingAttachment: AttachmentPayload? = nil
    @State private var pendingFileName: String? = nil
    
    // 토스트
    @State private var toastText: String? = nil
    
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
            .padding(.bottom, 140)
            
            // 플로팅 캡슐
            CapsuleInputView(
                text: $input,
                pendingAttachment: $pendingAttachment,
                pendingFileName: $pendingFileName,
                onSend: handleSend,
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
    }
    
    private func handleSend() {
        // 1개 초과 방어는 캡슐에서 이미 처리됐지만 안전망
        // 텍스트도 비고, 첨부도 없으면 무시
        if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && pendingAttachment == nil {
            showToast("Type something or attach a file/photo.")
            return
        }
        
        vm.addFromComposer(text: input, attachment: pendingAttachment)
        
        // 전송 후 초기화
        input = ""
        pendingAttachment = nil
        pendingFileName = nil
        
        // 서버 전송은 여기서 TODO:
        // TODO: build payload (text + base64 file if any) and POST
        // TODO: success/failure에 따라 토스트
        showToast("Sent.")
    }
    
    private func showToast(_ text: String) {
        toastText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation { toastText = nil }
        }
    }
}
