import SwiftUI

struct CheckmarkView: View {
    @State private var showCheckmark = false
    
    var body: some View {
        ZStack {
            // 배경 원형
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 80, height: 80)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            // 체크마크 아이콘
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
                .scaleEffect(showCheckmark ? 1.0 : 0.5)
                .opacity(showCheckmark ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showCheckmark)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // 전체 영역 사용
        .onAppear {
            // 체크마크 애니메이션 시작
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showCheckmark = true
                }
            }
        }
    }
}

#Preview {
    CheckmarkView()
}
