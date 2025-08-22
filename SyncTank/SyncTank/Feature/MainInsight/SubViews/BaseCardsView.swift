//
//  BaseCards.swift
//  SyncTank
//
//  Created by Demian Yoo on 8/23/25.
//

import SwiftUI

struct PlanCardView: View {
    let item: DashItem
    var body: some View {
        BaseCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title).font(.headline).bold()
                Text(item.subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

struct PhotoCardView: View {
    let item: DashItem
    var body: some View {
        BaseCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title).font(.headline).bold()
                    Text(item.subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                if let name = item.thumbnailName {
                    Image(name).resizable().aspectRatio(contentMode: .fill)
                        .frame(width: 96, height: 72).clipped().cornerRadius(8)
                }
            }
        }
    }
}

struct FileCardView: View {
    let item: DashItem
    var body: some View {
        BaseCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title).font(.headline).bold()
                Text(item.subtitle).font(.subheadline).foregroundStyle(.secondary)
                if let badge = item.fileBadge {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.fill").font(.system(size: 14))
                        Text(badge).font(.caption)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                }
            }
        }
    }
}

/// 공통 카드 배경
private struct BaseCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.black.opacity(0.25)))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}
