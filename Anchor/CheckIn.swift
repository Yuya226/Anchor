//
//  CheckIn.swift
//  Anchor
//
//  Created by Yuya Kubo on 2026/05/17.
//

import Foundation
import SwiftData

@Model
final class CheckIn {
    var id: UUID
    var achievementScore: Int
    var satisfactionScore: Int
    var doubtScore: Int
    var memo: String
    var createdAt: Date
    var dayType: String
    var stateTags: String

    init(
        id: UUID = UUID(),
        achievementScore: Int,
        satisfactionScore: Int,
        doubtScore: Int,
        memo: String = "",
        createdAt: Date = Date(),
        dayType: String = "Daily",
        stateTags: String = ""
    ) {
        self.id = id
        self.achievementScore = achievementScore
        self.satisfactionScore = satisfactionScore
        self.doubtScore = doubtScore
        self.memo = memo
        self.createdAt = createdAt
        self.dayType = dayType
        self.stateTags = stateTags
    }
}
