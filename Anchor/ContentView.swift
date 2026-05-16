//
//  ContentView.swift
//  Anchor
//
//  Created by Yuya Kubo on 2026/05/17.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                VStack(spacing: 14) {
                    AnchorCard(title: "今の重点テーマ", value: "Anchor MVPを作る")
                    AnchorCard(title: "次の一手", value: "ホーム画面を形にする")

                    HStack(spacing: 14) {
                        AnchorCard(title: "今日の積み上げ", value: "0分")
                        AnchorCard(title: "今日の迷い", value: "0回")
                    }

                    ShelfCard(
                        title: "棚上げ中",
                        items: [
                            "英語の本を読む",
                            "論文を読む",
                            "金融キャリアの深掘り"
                        ]
                    )
                }

                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 32)
        }
        .background(Color(red: 0.95, green: 0.94, blue: 0.91))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日のアンカー")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

            Text("迷いはここに預けて、次の一手に戻る")
                .font(.body)
                .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button("作業開始") {}
                .buttonStyle(PrimaryAnchorButtonStyle())

            HStack(spacing: 12) {
                Button("迷った") {}
                    .buttonStyle(SecondaryAnchorButtonStyle())

                Button("チェックイン") {}
                    .buttonStyle(SecondaryAnchorButtonStyle())
            }
        }
        .padding(.top, 8)
    }
}

private struct AnchorCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.45, green: 0.47, blue: 0.45))

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ShelfCard: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.45, green: 0.47, blue: 0.45))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.body)
                        .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct PrimaryAnchorButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(configuration.isPressed ? Color(red: 0.20, green: 0.31, blue: 0.29) : Color(red: 0.25, green: 0.38, blue: 0.35))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct SecondaryAnchorButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color(red: 0.25, green: 0.38, blue: 0.35))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? Color(red: 0.86, green: 0.88, blue: 0.84) : Color(red: 0.90, green: 0.91, blue: 0.87))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    ContentView()
}
