//
//  DataManagementView.swift
//  Anchor
//
//  Created by Yuya Kubo on 2026/05/17.
//

import Foundation
import SwiftData
import SwiftUI

struct DataManagementView: View {
    @Query(sort: \DoubtLog.createdAt, order: .reverse) private var doubtLogs: [DoubtLog]
    @Query(sort: \ShelfItem.createdAt, order: .reverse) private var shelfItems: [ShelfItem]
    @Query(sort: \ActivitySession.startedAt, order: .reverse) private var activitySessions: [ActivitySession]
    @Query(sort: \CheckIn.createdAt, order: .reverse) private var checkIns: [CheckIn]

    @State private var exportFileURL: URL?
    @State private var exportMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("データ管理")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

                Text("保存した記録をJSONとして書き出します。インポートはまだ行いません。")
                    .font(.body)
                    .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))

                DataSummaryCard(
                    doubtLogCount: doubtLogs.count,
                    shelfItemCount: shelfItems.count,
                    activitySessionCount: activitySessions.count,
                    checkInCount: checkIns.count
                )

                Button("JSONを書き出す", action: exportJSON)
                    .buttonStyle(DataManagementPrimaryButtonStyle())

                if let exportFileURL {
                    ShareLink(item: exportFileURL) {
                        Text("共有する")
                            .font(.headline)
                            .foregroundStyle(Color(red: 0.25, green: 0.38, blue: 0.35))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.90, green: 0.91, blue: 0.87))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }

                if !exportMessage.isEmpty {
                    Text(exportMessage)
                        .font(.footnote)
                        .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(Color(red: 0.95, green: 0.94, blue: 0.91))
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func exportJSON() {
        do {
            let payload = AnchorExportPayload(
                exportedAt: Date(),
                doubtLogs: doubtLogs.map(DoubtLogExport.init),
                shelfItems: shelfItems.map(ShelfItemExport.init),
                activitySessions: activitySessions.map(ActivitySessionExport.init),
                checkIns: checkIns.map(CheckInExport.init)
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(payload)
            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("anchor-export-\(fileTimestamp()).json")

            try data.write(to: fileURL, options: [.atomic])
            exportFileURL = fileURL
            exportMessage = "JSONを書き出しました。共有ボタンから保存できます。"
        } catch {
            exportFileURL = nil
            exportMessage = "JSONの書き出しに失敗しました: \(error.localizedDescription)"
        }
    }

    private func fileTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}

private struct DataSummaryCard: View {
    let doubtLogCount: Int
    let shelfItemCount: Int
    let activitySessionCount: Int
    let checkInCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("書き出し対象")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.45, green: 0.47, blue: 0.45))

            Text("迷いログ: \(doubtLogCount)件")
            Text("棚上げ: \(shelfItemCount)件")
            Text("作業ログ: \(activitySessionCount)件")
            Text("日記: \(checkInCount)件")
        }
        .font(.body)
        .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct DataManagementPrimaryButtonStyle: ButtonStyle {
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

private struct AnchorExportPayload: Codable {
    let exportedAt: Date
    let doubtLogs: [DoubtLogExport]
    let shelfItems: [ShelfItemExport]
    let activitySessions: [ActivitySessionExport]
    let checkIns: [CheckInExport]
}

private struct DoubtLogExport: Codable {
    let id: UUID
    let content: String
    let createdAt: Date

    init(_ doubtLog: DoubtLog) {
        id = doubtLog.id
        content = doubtLog.content
        createdAt = doubtLog.createdAt
    }
}

private struct ShelfItemExport: Codable {
    let id: UUID
    let title: String
    let reason: String
    let createdAt: Date
    let reviewDate: Date?

    init(_ shelfItem: ShelfItem) {
        id = shelfItem.id
        title = shelfItem.title
        reason = shelfItem.reason
        createdAt = shelfItem.createdAt
        reviewDate = shelfItem.reviewDate
    }
}

private struct ActivitySessionExport: Codable {
    let id: UUID
    let title: String
    let startedAt: Date
    let endedAt: Date?
    let durationSeconds: Int
    let result: String?
    let actualActivity: String?
    let taskID: UUID?
    let taskTitle: String?
    let taskStyle: String?

    init(_ activitySession: ActivitySession) {
        id = activitySession.id
        title = activitySession.title
        startedAt = activitySession.startedAt
        endedAt = activitySession.endedAt
        durationSeconds = activitySession.durationSeconds
        result = activitySession.result
        actualActivity = activitySession.actualActivity
        taskID = activitySession.taskID
        taskTitle = activitySession.taskTitle
        taskStyle = activitySession.taskStyle
    }
}

private struct CheckInExport: Codable {
    let id: UUID
    let achievementScore: Int
    let satisfactionScore: Int
    let doubtScore: Int
    let memo: String
    let createdAt: Date
    let dayType: String
    let stateTags: String

    init(_ checkIn: CheckIn) {
        id = checkIn.id
        achievementScore = checkIn.achievementScore
        satisfactionScore = checkIn.satisfactionScore
        doubtScore = checkIn.doubtScore
        memo = checkIn.memo
        createdAt = checkIn.createdAt
        dayType = checkIn.dayType
        stateTags = checkIn.stateTags
    }
}
