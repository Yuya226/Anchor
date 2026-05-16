//
//  ActivitySession.swift
//  Anchor
//
//  Created by Yuya Kubo on 2026/05/17.
//

import Foundation
import SwiftData

@Model
final class ActivitySession {
    var id: UUID
    var title: String
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Int
    var result: String?
    var actualActivity: String?

    init(
        id: UUID = UUID(),
        title: String,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        durationSeconds: Int = 0,
        result: String? = nil,
        actualActivity: String? = nil
    ) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.result = result
        self.actualActivity = actualActivity
    }
}
