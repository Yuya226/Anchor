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

    init(
        id: UUID = UUID(),
        achievementScore: Int,
        satisfactionScore: Int,
        doubtScore: Int,
        memo: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.achievementScore = achievementScore
        self.satisfactionScore = satisfactionScore
        self.doubtScore = doubtScore
        self.memo = memo
        self.createdAt = createdAt
    }
}
