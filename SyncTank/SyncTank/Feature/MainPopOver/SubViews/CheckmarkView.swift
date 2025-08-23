import SwiftUI

struct CheckmarkView: View {
    @State private var showCheckmark = false
    
    var body: some View {
        ZStack {
            // 배경 원형
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 60, height: 60)
            
            // 체크마크 아이콘
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)
                .scaleEffect(showCheckmark ? 1.0 : 0.5)
                .opacity(showCheckmark ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showCheckmark)
        }
        .onAppear {
            // 체크마크 애니메이션 시작
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showCheckmark = true
            }
        }
    }
}

#Preview {
    CheckmarkView()
}
