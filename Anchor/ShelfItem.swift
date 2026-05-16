//
//  ShelfItem.swift
//  Anchor
//
//  Created by Yuya Kubo on 2026/05/17.
//

import Foundation
import SwiftData

@Model
final class ShelfItem {
    var id: UUID
    var title: String
    var reason: String
    var createdAt: Date
    var reviewDate: Date?

    init(
        id: UUID = UUID(),
        title: String,
        reason: String = "",
        createdAt: Date = Date(),
        reviewDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.reason = reason
        self.createdAt = createdAt
        self.reviewDate = reviewDate
    }
}
