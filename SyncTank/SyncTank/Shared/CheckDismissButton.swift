//
//  CheckDismissButton.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI

struct CheckDismissButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Color.white.opacity(0.6))
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.black)
            }
            .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Mark as done")
    }
}
