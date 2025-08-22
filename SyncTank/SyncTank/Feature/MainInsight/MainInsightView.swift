//
//  CapsuleView.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI

struct MainInsightView: View {
    @State private var input = ""
    
    var body: some View {
        
        ZStack {
            Color(.mainInsightWindow).ignoresSafeArea()
            
            InsightDashboard()
            
            // 하단 입력 플로팅 캡슐
            CapsuleInputView(text: $input) { value in
                print("Send:", value)
                // TODO: Upstage API 호출
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 24)
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: Metrics.windowWidth, height: Metrics.windowHeight)
        .preferredColorScheme(.dark)
    }
}

#Preview { MainInsightView() }
