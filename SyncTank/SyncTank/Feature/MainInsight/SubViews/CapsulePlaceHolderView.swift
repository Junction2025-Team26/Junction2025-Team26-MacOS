//
//  CapsulePlaceHolderView.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI

struct CapsulePlaceHolderView: View {
    @Binding var text: String
    var onSend: (String) -> Void = { _ in }
    @FocusState private var isFocused: Bool
    
    var body: some View {
        
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text("Drop, Ask anything")
                    .foregroundStyle(.placeHolder)
                    .font(.system(size: 16, weight: .light))
            }
            TextField("", text: $text )
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(.primary)
                .submitLabel(.send)
                .onSubmit { onSend(text) }
                .focused($isFocused)
        }
        .padding(.vertical, 14)
        .onAppear {
            // Clipgo 패턴: onAppear에서 포커스 설정
            DispatchQueue.main.async {
                isFocused = true
                print("CapsulePlaceHolderView focus set in onAppear: \(isFocused)")
            }
        }
    }
}

