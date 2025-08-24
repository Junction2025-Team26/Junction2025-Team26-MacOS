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
            .disabled(isSending)
            .blur(radius: isSending ? 2 : 0)
            
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
                        
                    isSending = true
                    Task { @MainActor in
                        await vm.sendAndReload(text: vm.inputText, attachment: vm.pendingAttachment)
                        vm.inputText = ""
                        vm.pendingAttachment = nil
                        vm.pendingFileName = nil
                        
                        // 3) 로딩 종료 → 체크 표시
                        isSending = false
                        showCheck = true
                        
                        // 4) 체크 잠깐 보여주고 닫기
                        try? await Task.sleep(nanoseconds: 600_000_000)
                        withAnimation { showCheck = false }
                        
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
            
            if isSending || showCheck {
                BlockingOverlay(isLoading: isSending, showCheck: showCheck)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.15), value: isSending)
                    .animation(.easeInOut(duration: 0.15), value: showCheck)
                    .ignoresSafeArea()
                    .allowsHitTesting(true)   // 오버레이가 모든 터치를 흡수
            }
            
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

private struct BlockingOverlay: View {
    let isLoading: Bool
    let showCheck: Bool

    var body: some View {
        ZStack {
            // 반투명 딤: 포커스 + 터치 차단
            Color.black.opacity(0.25)
                .contentShape(Rectangle())  // 빈 영역도 히트
                .allowsHitTesting(true)

            // 중앙 컨텐츠
            Group {
                if isLoading {
                    LearningView()             // 회전 스피너 (ProgressView 대체 가능)
                        .frame(width: 160, height: 160)
                } else if showCheck {
                    CheckmarkView()            // 완료 체크 애니메이션
                        .frame(width: 160, height: 160)
                }
            }
        }
    }
}
