//
//  ContentView.swift
//  Anchor
//
//  Created by Yuya Kubo on 2026/05/17.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: AnchorTab = .home

    var body: some View {
        selectedContent
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab)
        }
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedTab {
        case .log:
            LogTabView()
        case .shelf:
            NavigationStack {
                ShelfItemListView()
            }
        case .home:
            HomeView()
        case .tasks:
            NavigationStack {
                TaskListView()
            }
        case .settings:
            NavigationStack {
                DataManagementView()
            }
        }
    }
}

private enum AnchorTab: CaseIterable {
    case log
    case shelf
    case home
    case tasks
    case settings

    var title: String {
        switch self {
        case .log:
            "ログ"
        case .shelf:
            "棚上げ"
        case .home:
            "ホーム"
        case .tasks:
            "タスク"
        case .settings:
            "設定"
        }
    }

    var systemImage: String {
        switch self {
        case .log:
            "list.bullet.rectangle"
        case .shelf:
            "tray"
        case .home:
            "house.fill"
        case .tasks:
            "checklist"
        case .settings:
            "gearshape"
        }
    }
}

private struct CustomTabBar: View {
    @Binding var selectedTab: AnchorTab

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color(red: 0.98, green: 0.97, blue: 0.94))
                .shadow(color: Color.black.opacity(0.09), radius: 18, y: 8)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(AnchorTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        if tab == .home {
                            HomeTabItem(isSelected: selectedTab == tab)
                        } else {
                            StandardTabItem(tab: tab, isSelected: selectedTab == tab)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(tab.title)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
        }
        .frame(height: 76)
        .padding(.horizontal, 16)
        .padding(.top, 22)
        .padding(.bottom, 12)
        .background(Color(red: 0.95, green: 0.94, blue: 0.91))
    }
}

private struct StandardTabItem: View {
    let tab: AnchorTab
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: tab.systemImage)
                .font(.system(size: 15, weight: .semibold))

            Text(tab.title)
                .font(.caption2)
                .fontWeight(isSelected ? .semibold : .regular)
        }
        .foregroundStyle(isSelected ? Color(red: 0.25, green: 0.38, blue: 0.35) : Color(red: 0.58, green: 0.60, blue: 0.57))
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background {
            if isSelected {
                Capsule()
                    .fill(Color(red: 0.91, green: 0.92, blue: 0.88))
            }
        }
    }
}

private struct HomeTabItem: View {
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color(red: 0.21, green: 0.34, blue: 0.31) : Color(red: 0.33, green: 0.45, blue: 0.41))
                    .frame(width: 66, height: 66)

                Image(systemName: "house.fill")
                    .font(.system(size: 27, weight: .bold))
                    .offset(y: -1)
                .foregroundStyle(.white)
            }
            .overlay {
                Circle()
                    .stroke(Color(red: 0.98, green: 0.97, blue: 0.94), lineWidth: 5)
            }
            .shadow(color: Color.black.opacity(isSelected ? 0.20 : 0.13), radius: 14, y: 7)

            Text("ホーム")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(isSelected ? Color(red: 0.21, green: 0.34, blue: 0.31) : Color(red: 0.48, green: 0.51, blue: 0.48))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 66)
    }
}

private struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DoubtLog.createdAt, order: .reverse) private var doubtLogs: [DoubtLog]
    @Query(sort: \ShelfItem.createdAt, order: .reverse) private var shelfItems: [ShelfItem]
    @Query(sort: \ActivitySession.startedAt, order: .reverse) private var activitySessions: [ActivitySession]
    @Query(sort: \AnchorTask.createdAt, order: .reverse) private var tasks: [AnchorTask]

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
                        AnchorCard(title: "今の重点テーマ", value: activeThemeTitle)
                        AnchorCard(title: "次の一手", value: activeTaskTitle)

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

    private var activeTask: AnchorTask? {
        tasks.first { $0.isActive && !$0.isCompleted }
    }

    private var activeTaskTitle: String {
        activeTask?.title ?? "ホーム画面を形にする"
    }

    private var activeThemeTitle: String {
        activeTask?.themeTitle ?? "Anchor MVPを作る"
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

                Button("日記") {
                    isShowingCheckInSheet = true
                }
                    .buttonStyle(SecondaryAnchorButtonStyle())
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
        let session = ActivitySession(title: activeTaskTitle)
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

private struct LogTabView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("ログ")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

                    Text("迷いとチェックインを見返す場所")
                        .font(.body)
                        .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))

                    NavigationLink {
                        DoubtLogListView()
                    } label: {
                        TabNavigationCard(title: "迷いログ", subtitle: "預けた迷いを見返す")
                    }

                    NavigationLink {
                        HistoryView()
                    } label: {
                        TabNavigationCard(title: "これまでの日記", subtitle: "これまでの日記と作業ログを見返す")
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
}

private struct TabNavigationCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

            Text(subtitle)
                .font(.body)
                .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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

                Text("積み上げと日記を、あとで見返せる場所")
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

            Text("作業や日記を記録すると、ここで見返せます。")
                .font(.body)
                .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AnchorTask.createdAt, order: .reverse) private var tasks: [AnchorTask]

    @State private var isShowingAddSheet = false
    @State private var title = ""
    @State private var themeTitle = ""
    @State private var minimumAction = ""
    @State private var taskStyle = "Hybrid"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("タスク")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

                        Text("今本当にすべきことを置いておく場所")
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
                    .accessibilityLabel("タスクを追加")
                }

                if tasks.isEmpty {
                    EmptyTaskCard()
                } else {
                    VStack(spacing: 12) {
                        ForEach(tasks) { task in
                            TaskRow(task: task, onSetActive: {
                                setActiveTask(task)
                            })
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
            TaskSheet(
                title: $title,
                themeTitle: $themeTitle,
                minimumAction: $minimumAction,
                taskStyle: $taskStyle,
                onCancel: closeSheet,
                onSave: saveTask
            )
        }
    }

    private func closeSheet() {
        resetInput()
        isShowingAddSheet = false
    }

    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTheme = themeTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMinimum = minimumAction.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            return
        }

        let shouldActivate = !tasks.contains { $0.isActive && !$0.isCompleted }
        let task = AnchorTask(
            title: trimmedTitle,
            isActive: shouldActivate,
            taskStyle: taskStyle,
            themeTitle: trimmedTheme.isEmpty ? nil : trimmedTheme,
            minimumAction: trimmedMinimum.isEmpty ? nil : trimmedMinimum
        )

        modelContext.insert(task)
        resetInput()
        isShowingAddSheet = false
    }

    private func resetInput() {
        title = ""
        themeTitle = ""
        minimumAction = ""
        taskStyle = "Hybrid"
    }

    private func setActiveTask(_ selectedTask: AnchorTask) {
        for task in tasks {
            task.isActive = task.id == selectedTask.id
        }
    }
}

private struct TaskRow: View {
    let task: AnchorTask
    let onSetActive: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(task.title)
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

                Spacer()

                Text(task.taskStyle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 0.25, green: 0.38, blue: 0.35))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(red: 0.90, green: 0.91, blue: 0.87))
                    .clipShape(Capsule())
            }

            if task.isActive {
                Text("今日のアンカー")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.25, green: 0.38, blue: 0.35))
            } else {
                Button("アンカーにする", action: onSetActive)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.25, green: 0.38, blue: 0.35))
            }

            if let themeTitle = task.themeTitle, !themeTitle.isEmpty {
                Text(themeTitle)
                    .font(.body)
                    .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))
            }

            if let minimumAction = task.minimumAction, !minimumAction.isEmpty {
                Text("Minimum: \(minimumAction)")
                    .font(.body)
                    .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))
            }

            Text(task.createdAt, format: Date.FormatStyle(date: .numeric, time: .shortened))
                .font(.caption)
                .foregroundStyle(Color(red: 0.45, green: 0.47, blue: 0.45))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct EmptyTaskCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("まだタスクはありません")
                .font(.headline)
                .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

            Text("今本当にすべきことを追加すると、ホームのアンカーに近づきます。")
                .font(.body)
                .foregroundStyle(Color(red: 0.38, green: 0.40, blue: 0.39))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct TaskSheet: View {
    @Binding var title: String
    @Binding var themeTitle: String
    @Binding var minimumAction: String
    @Binding var taskStyle: String

    let onCancel: () -> Void
    let onSave: () -> Void

    private let taskStyles = [
        "Minimum",
        "Daily",
        "Momentum",
        "Hybrid",
        "Recovery"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("タスクを追加")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(red: 0.16, green: 0.18, blue: 0.18))

                    LabeledTextField(title: "タスク", placeholder: "今本当にすべきこと", text: $title)
                    LabeledTextField(title: "重点テーマ", placeholder: "例: Anchor MVP", text: $themeTitle)
                    LabeledTextField(title: "Minimum", placeholder: "例: 1分だけ開く", text: $minimumAction)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("実行スタイル")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(red: 0.45, green: 0.47, blue: 0.45))

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
                            ForEach(taskStyles, id: \.self) { style in
                                Button {
                                    taskStyle = style
                                } label: {
                                    Text(style)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(taskStyle == style ? .white : Color(red: 0.25, green: 0.38, blue: 0.35))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(taskStyle == style ? Color(red: 0.25, green: 0.38, blue: 0.35) : Color(red: 0.90, green: 0.91, blue: 0.87))
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                    }

                    VStack(spacing: 12) {
                        Button("保存", action: onSave)
                            .buttonStyle(PrimaryAnchorButtonStyle())
                            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Button("キャンセル", action: onCancel)
                            .buttonStyle(SecondaryAnchorButtonStyle())
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color(red: 0.95, green: 0.94, blue: 0.91))
        }
    }
}

private struct LabeledTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.45, green: 0.47, blue: 0.45))

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(14)
                .background(Color(red: 0.99, green: 0.98, blue: 0.95))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
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
                Text("日記")
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
        .modelContainer(for: [DoubtLog.self, ShelfItem.self, ActivitySession.self, CheckIn.self, AnchorTask.self], inMemory: true)
}
