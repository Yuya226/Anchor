//
//  AnchorTask.swift
//  Anchor
//
//  Created by Yuya Kubo on 2026/05/17.
//

import Foundation
import SwiftData

@Model
final class AnchorTask {
    var id: UUID
    var title: String
    var detail: String?
    var createdAt: Date
    var dueDate: Date?
    var isActive: Bool
    var isCompleted: Bool
    var priority: Int
    var taskStyle: String
    var themeTitle: String?
    var minimumAction: String?
    var requiredDevice: String?
    var context: String?
    var estimatedMinutes: Int?

    init(
        id: UUID = UUID(),
        title: String,
        detail: String? = nil,
        createdAt: Date = Date(),
        dueDate: Date? = nil,
        isActive: Bool = false,
        isCompleted: Bool = false,
        priority: Int = 0,
        taskStyle: String = "Hybrid",
        themeTitle: String? = nil,
        minimumAction: String? = nil,
        requiredDevice: String? = nil,
        context: String? = nil,
        estimatedMinutes: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.isActive = isActive
        self.isCompleted = isCompleted
        self.priority = priority
        self.taskStyle = taskStyle
        self.themeTitle = themeTitle
        self.minimumAction = minimumAction
        self.requiredDevice = requiredDevice
        self.context = context
        self.estimatedMinutes = estimatedMinutes
    }
}
