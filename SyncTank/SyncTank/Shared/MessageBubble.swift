import SwiftUI

// 팝오버에서 사용하는 간단한 메시지 표시용
struct SimpleMessageView: View {
    let text: String
    let timestamp: Date
    
    var body: some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(text)
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(3)
                
                Text(formatTimestamp(timestamp))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.8))
            )
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    SimpleMessageView(
        text: "테스트 메시지입니다.",
        timestamp: Date()
    )
}
