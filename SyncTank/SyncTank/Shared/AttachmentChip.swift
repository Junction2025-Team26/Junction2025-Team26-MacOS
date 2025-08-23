import SwiftUI

// 팝오버에서 사용하는 첨부파일 칩
struct AttachmentChip: View {
    let attachment: AttachmentPayload
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: attachment.iconName)
                .foregroundColor(.blue)
                .font(.caption)
                .frame(width: 16, height: 16)
            
            Text(attachment.filename)
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: 120)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
        )
    }
}

#Preview {
    AttachmentChip(
        attachment: AttachmentPayload(
            isImage: false,
            fileExt: "PDF",
            preview: nil,
            fileURLString: nil
        ),
        onRemove: {}
    )
}
