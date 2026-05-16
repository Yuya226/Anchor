//
//  ContentView.swift
//  Anchor
//
//  Created by Yuya Kubo on 2026/05/17.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DoubtLog.createdAt, order: .reverse) private var doubtLogs: [DoubtLog]
    @Query(sort: \ShelfItem.createdAt, order: .reverse) private var shelfItems: [ShelfItem]
    @Query(sort: \ActivitySession.startedAt, order: .reverse) private var activitySessions: [ActivitySession]

    @State private var isShowingDoubtSheet = false
    @State private var doubtContent = ""
    @State private var feedbackSession: ActivitySession?
    @State private var sessionResult = "できた"
    @State private var actualActivity = ""
    @State private var isShowingCheckInSheet = false
    @State private var achievementScore = 3
    @State private var satisfactionScore = 3
    @State private var doubtScore = 3
    @State private var checkInMemo = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    VStack(spacing: 14) {
                        AnchorCard(title: "今の重点テーマ", value: "Anchor MVPを作る")
                        AnchorCard(title: "次の一手", value: "ホーム画面を形にする")

                        TimelineView(.periodic(from: .now, by: 1)) { timeline in
                            HStack(spacing: 14) {
                                AnchorCard(title: "今日の積み上げ", value: workDurationText(now: timeline.date))
                                AnchorCard(title: "今日の迷い", value: "\(todayDoubtCount)回")
                            }
                        }

                        ShelfCard(
                            title: "棚上げ中",
                            items: homeShelfItemTitles
                        )
                    }

                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 72)
            }
            .background(Color(red: 0.95, green: 0.94, blue: 0.91))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingDoubtSheet) {
                DoubtLogSheet(
                    content: $doubtContent,
                    onCancel: closeDoubtSheet,
                    onSave: saveDoubtLog
                )
            }
            .sheet(isPresented: isShowingSessionFeedback) {
                SessionFeedbackSheet(
                    result: $sessionResult,
                    actualActivity: $actualActivity,
                    onSave: saveSessionFeedback
                )
            }
            .sheet(isPresented: $isShowingCheckInSheet) {
                CheckInSheet(
                    achievementScore: $achievementScore,
                    satisfactionScore: $satisfactionScore,
                    doubtScore: $doubtScore,
                    memo: $checkInMemo,
                    onCancel: closeCheckInSheet,
                    onSave: saveCheckIn
                )
            }
        }
    }

    private var isShowingSessionFeedback: Binding<Bool> {
        Binding(
            get: { feedbackSession != nil },
            set: { isShowing in
                if !isShowing {
                    clearSessionFeedback()
                }
            }
        )
    }

    private var todayDoubtCount: Int {
        doubtLogs.filter { Calendar.current.isDateInToday($0.createdAt) }.count
    }

    private var activeSession: ActivitySession? {
        activitySessions.first { $0.endedAt == nil }
    }

    private var homeShelfItemTitles: [String] {
        let savedTitles = shelfItems.prefix(3).map(\.title)

        if savedTitles.isEmpty {
            return [
                "英語の本を読む",
                "論文を読む",
                "金融キャリアの深掘り"
            ]
        }

        return savedTitles
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
            Button(activeSession == nil ? "作業開始" : "作業停止") {
                toggleWorkSession()
            }
                .buttonStyle(PrimaryAnchorButtonStyle())

            HStack(spacing: 12) {
                Button("迷った") {
                    isShowingDoubtSheet = true
                }
                    .buttonStyle(SecondaryAnchorButtonStyle())

                Button("チェックイン") {
                    isShowingCheckInSheet = true
                }
                    .buttonStyle(SecondaryAnchorButtonStyle())
            }

            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    NavigationLink {
                        DoubtLogListView()
                    } label: {
                        Text("迷いログ")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(red: 0.25, green: 0.38, blue: 0.35))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }

                    NavigationLink {
                        ShelfItemListView()
                    } label: {
                        Text("棚上げ")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(red: 0.25, green: 0.38, blue: 0.35))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }

                NavigationLink {
                    HistoryView()
                } label: {
                    Text("履歴を見る")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(red: 0.25, green: 0.38, blue: 0.35))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }
        }
        .padding(.top, 8)
    }

    private func closeDoubtSheet() {
        doubtContent = ""
        isShowingDoubtSheet = false
    }

    private func saveDoubtLog() {
        let trimmedContent = doubtContent.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedContent.isEmpty else {
            return
        }

        let doubtLog = DoubtLog(content: trimmedContent)
        modelContext.insert(doubtLog)
        doubtContent = ""
        isShowingDoubtSheet = false
    }

    private func toggleWorkSession() {
        if let activeSession {
            finishWorkSession(activeSession)
        } else {
            startWorkSession()
        }
    }

    private func startWorkSession() {
        let session = ActivitySession(title: "Anchor MVPを作る")
        modelContext.insert(session)
    }

    private func finishWorkSession(_ session: ActivitySession) {
        let endedAt = Date()
        session.endedAt = endedAt
        session.durationSeconds = max(0, Int(endedAt.timeIntervalSince(session.startedAt)))
        feedbackSession = session
    }

    private func saveSessionFeedback() {
        let trimmedActivity = actualActivity.trimmingCharacters(in: .whitespacesAndNewlines)

        feedbackSession?.result = sessionResult
        feedbackSession?.actualActivity = trimmedActivity.isEmpty ? nil : trimmedActivity
        clearSessionFeedback()
    }

    private func clearSessionFeedback() {
        feedbackSession = nil
        sessionResult = "できた"
        actualActivity = ""
    }

    private func closeCheckInSheet() {
        resetCheckInInput()
        isShowingCheckInSheet = false
    }

    private func saveCheckIn() {
        let memo = checkInMemo.trimmingCharacters(in: .whitespacesAndNewlines)
        let checkIn = CheckIn(
            achievementScore: achievementScore,
            satisfactionScore: satisfactionScore,
            doubtScore: doubtScore,
            memo: memo
        )

        modelContext.insert(checkIn)
        resetCheckInInput()
        isShowingCheckInSheet = false
    }

    private func resetCheckInInput() {
        achievementScore = 3
        satisfactionScore = 3
        doubtScore = 3
        checkInMemo = ""
    }

    private func workDurationText(now: Date) -> String {
        let seconds = todayWorkDurationSeconds(now: now)
        let minutes = seconds / 60

        if minutes < 60 {
            return "\(minutes)分"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)時間\(remainingMinutes)分"
    }

    private func todayWorkDurationSeconds(now: Date) -> Int {
        activitySessions.reduce(0) { total, session in
            guard Calendar.current.isDateInToday(session.startedAt) else {
                return total
            }

            if let endedAt = session.endedAt {
                return total + max(0, Int(endedAt.timeIntervalSince(session.startedAt)))
            }

            return total + max(0, Int(now.timeIntervalSince(session.startedAt)))
        }
    }
}

private struct DoubtLogListView: View {
    @Query(sort: \DoubtLog.createdAt, order: .reverse) private var doubtLogs: [DoubtLog]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("迷いログ")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

                Text("預けた迷いを、あとで見返せる場所")
                    .font(.body)
                    .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))

                if doubtLogs.isEmpty {
                    EmptyDoubtLogCard()
                } else {
                    VStack(spacing: 12) {
                        ForEach(doubtLogs) { doubtLog in
                            DoubtLogRow(doubtLog: doubtLog)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(Color(red: 0.95, green: 0.94, blue: 0.91))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DoubtLogRow: View {
    let doubtLog: DoubtLog

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(doubtLog.createdAt, format: Date.FormatStyle(date: .numeric, time: .shortened))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.45, green: 0.47, blue: 0.45))

            Text(doubtLog.content)
                .font(.body)
                .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct EmptyDoubtLogCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("まだ迷いは預けられていません")
                .font(.headline)
                .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

            Text("迷ったときに記録すれば、あとで見返せます。")
                .font(.body)
                .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct HistoryView: View {
    @Query(sort: \ActivitySession.startedAt, order: .reverse) private var activitySessions: [ActivitySession]
    @Query(sort: \CheckIn.createdAt, order: .reverse) private var checkIns: [CheckIn]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("履歴")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

                Text("積み上げとチェックインを、あとで見返せる場所")
                    .font(.body)
                    .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))

                if activitySessions.isEmpty && checkIns.isEmpty {
                    EmptyHistoryCard()
                } else {
                    VStack(spacing: 12) {
                        ForEach(activitySessions) { session in
                            ActivitySessionHistoryRow(session: session)
                        }

                        ForEach(checkIns) { checkIn in
                            CheckInHistoryRow(checkIn: checkIn)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(Color(red: 0.95, green: 0.94, blue: 0.91))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ActivitySessionHistoryRow: View {
    let session: ActivitySession

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("作業ログ")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.45, green: 0.47, blue: 0.45))

            Text(session.title)
                .font(.headline)
                .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(session.startedAt, format: Date.FormatStyle(date: .numeric, time: .shortened))
                .font(.caption)
                .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))

            Text("積み上げ: \(durationText(seconds: session.durationSeconds))")
                .font(.body)
                .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

            if let result = session.result {
                Text("結果: \(result)")
                    .font(.body)
                    .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))
            }

            if let actualActivity = session.actualActivity {
                Text("実際: \(actualActivity)")
                    .font(.body)
                    .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func durationText(seconds: Int) -> String {
        let minutes = seconds / 60

        if minutes < 60 {
            return "\(minutes)分"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)時間\(remainingMinutes)分"
    }
}

private struct CheckInHistoryRow: View {
    let checkIn: CheckIn

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("チェックイン")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.45, green: 0.47, blue: 0.45))

            Text(checkIn.createdAt, format: Date.FormatStyle(date: .numeric, time: .shortened))
                .font(.caption)
                .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))

            Text("達成度 \(checkIn.achievementScore) / 納得度 \(checkIn.satisfactionScore) / 迷い \(checkIn.doubtScore)")
                .font(.body)
                .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

            if !checkIn.memo.isEmpty {
                Text(checkIn.memo)
                    .font(.body)
                    .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct EmptyHistoryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("まだ履歴はありません")
                .font(.headline)
                .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

            Text("作業やチェックインを記録すると、ここで見返せます。")
                .font(.body)
                .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ShelfItemListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShelfItem.createdAt, order: .reverse) private var shelfItems: [ShelfItem]

    @State private var isShowingAddSheet = false
    @State private var title = ""
    @State private var reason = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("棚上げリスト")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

                        Text("今はやらない選択肢を、捨てずに置いておく場所")
                            .font(.body)
                            .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))
                    }

                    Spacer()

                    Button {
                        isShowingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color(red: 0.25, green: 0.38, blue: 0.35))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("棚上げ項目を追加")
                }

                if shelfItems.isEmpty {
                    EmptyShelfItemCard()
                } else {
                    VStack(spacing: 12) {
                        ForEach(shelfItems) { shelfItem in
                            ShelfItemRow(shelfItem: shelfItem)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .background(Color(red: 0.95, green: 0.94, blue: 0.91))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingAddSheet) {
            ShelfItemSheet(
                title: $title,
                reason: $reason,
                onCancel: closeSheet,
                onSave: saveShelfItem
            )
        }
    }

    private func closeSheet() {
        title = ""
        reason = ""
        isShowingAddSheet = false
    }

    private func saveShelfItem() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            return
        }

        modelContext.insert(ShelfItem(title: trimmedTitle, reason: trimmedReason))
        title = ""
        reason = ""
        isShowingAddSheet = false
    }
}

private struct ShelfItemRow: View {
    let shelfItem: ShelfItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(shelfItem.title)
                .font(.headline)
                .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))
                .frame(maxWidth: .infinity, alignment: .leading)

            if !shelfItem.reason.isEmpty {
                Text(shelfItem.reason)
                    .font(.body)
                    .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))
            }

            Text(shelfItem.createdAt, format: Date.FormatStyle(date: .numeric, time: .shortened))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.45, green: 0.47, blue: 0.45))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct EmptyShelfItemCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("まだ棚上げはありません")
                .font(.headline)
                .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

            Text("今はやらないことを置いておくと、次の一手に戻りやすくなります。")
                .font(.body)
                .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct SessionFeedbackSheet: View {
    @Binding var result: String
    @Binding var actualActivity: String

    let onSave: () -> Void

    private let resultOptions = [
        "できた",
        "少しできた",
        "別のことをした",
        "何もしなかった"
    ]

    private let alternativeActivityOptions = [
        "YouTube",
        "Netflix",
        "アニメ",
        "映画",
        "筋トレ",
        "散歩",
        "睡眠",
        "ポルノ",
        "別の勉強",
        "バイト",
        "何もしない",
        "その他"
    ]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("作業をふり返る")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

                Text("実際に起きたことを軽く残して、次に使える記録にします。")
                    .font(.body)
                    .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))

                VStack(alignment: .leading, spacing: 10) {
                    Text("本来のタスク")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(red: 0.45, green: 0.47, blue: 0.45))

                    VStack(spacing: 10) {
                        ForEach(resultOptions, id: \.self) { option in
                            Button {
                                result = option
                            } label: {
                                HStack {
                                    Text(option)
                                        .font(.body)
                                        .fontWeight(.semibold)

                                    Spacer()

                                    if result == option {
                                        Image(systemName: "checkmark")
                                            .font(.body.weight(.bold))
                                    }
                                }
                                .foregroundStyle(result == option ? .white : Color(red: 0.25, green: 0.38, blue: 0.35))
                                .padding(14)
                                .background(result == option ? Color(red: 0.25, green: 0.38, blue: 0.35) : Color(red: 0.90, green: 0.91, blue: 0.87))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }
                }

                if result == "別のことをした" || result == "何もしなかった" {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("代替行動")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(red: 0.45, green: 0.47, blue: 0.45))

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                            ForEach(alternativeActivityOptions, id: \.self) { option in
                                Button {
                                    actualActivity = option
                                } label: {
                                    Text(option)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(actualActivity == option ? .white : Color(red: 0.25, green: 0.38, blue: 0.35))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(actualActivity == option ? Color(red: 0.25, green: 0.38, blue: 0.35) : Color(red: 0.90, green: 0.91, blue: 0.87))
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("実際にしたこと")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(red: 0.45, green: 0.47, blue: 0.45))

                    TextField("例: YouTube、散歩、別の勉強", text: $actualActivity)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Spacer()

                Button("保存", action: onSave)
                    .buttonStyle(PrimaryAnchorButtonStyle())
            }
            .padding(20)
            .background(Color(red: 0.95, green: 0.94, blue: 0.91))
        }
    }
}

private struct CheckInSheet: View {
    @Binding var achievementScore: Int
    @Binding var satisfactionScore: Int
    @Binding var doubtScore: Int
    @Binding var memo: String

    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("チェックイン")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

                Text("今日の状態を軽く残します。")
                    .font(.body)
                    .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))

                ScorePicker(title: "達成度", score: $achievementScore)
                ScorePicker(title: "納得度", score: $satisfactionScore)
                ScorePicker(title: "迷いの強さ", score: $doubtScore)

                VStack(alignment: .leading, spacing: 10) {
                    Text("一言メモ")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(red: 0.45, green: 0.47, blue: 0.45))

                    TextEditor(text: $memo)
                        .frame(minHeight: 120)
                        .padding(12)
                        .scrollContentBackground(.hidden)
                        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Spacer()

                VStack(spacing: 12) {
                    Button("保存", action: onSave)
                        .buttonStyle(PrimaryAnchorButtonStyle())

                    Button("キャンセル", action: onCancel)
                        .buttonStyle(SecondaryAnchorButtonStyle())
                }
            }
            .padding(20)
            .background(Color(red: 0.95, green: 0.94, blue: 0.91))
        }
    }
}

private struct ScorePicker: View {
    let title: String
    @Binding var score: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.45, green: 0.47, blue: 0.45))

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        score = value
                    } label: {
                        Text("\(value)")
                            .font(.headline)
                            .foregroundStyle(score == value ? .white : Color(red: 0.25, green: 0.38, blue: 0.35))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(score == value ? Color(red: 0.25, green: 0.38, blue: 0.35) : Color(red: 0.90, green: 0.91, blue: 0.87))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
        }
    }
}

private struct ShelfItemSheet: View {
    @Binding var title: String
    @Binding var reason: String

    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("棚上げする")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

                VStack(alignment: .leading, spacing: 10) {
                    Text("項目")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(red: 0.45, green: 0.47, blue: 0.45))

                    TextField("今はやらないこと", text: $title)
                        .textFieldStyle(.plain)
                        .padding(14)
                        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("理由")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(red: 0.45, green: 0.47, blue: 0.45))

                    TextEditor(text: $reason)
                        .frame(minHeight: 120)
                        .padding(12)
                        .scrollContentBackground(.hidden)
                        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Spacer()

                VStack(spacing: 12) {
                    Button("保存", action: onSave)
                        .buttonStyle(PrimaryAnchorButtonStyle())
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("キャンセル", action: onCancel)
                        .buttonStyle(SecondaryAnchorButtonStyle())
                }
            }
            .padding(20)
            .background(Color(red: 0.95, green: 0.94, blue: 0.91))
        }
    }
}

private struct DoubtLogSheet: View {
    @Binding var content: String

    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("迷いを預ける")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

                TextEditor(text: $content)
                    .frame(minHeight: 160)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(Color(red: 0.99, green: 0.98, blue: 0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Spacer()

                VStack(spacing: 12) {
                    Button("保存", action: onSave)
                        .buttonStyle(PrimaryAnchorButtonStyle())
                        .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button("キャンセル", action: onCancel)
                        .buttonStyle(SecondaryAnchorButtonStyle())
                }
            }
            .padding(20)
            .background(Color(red: 0.95, green: 0.94, blue: 0.91))
        }
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
        .modelContainer(for: [DoubtLog.self, ShelfItem.self, ActivitySession.self, CheckIn.self], inMemory: true)
}
