//
//  DoubtLog.swift
//  Anchor
//
//  Created by Yuya Kubo on 2026/05/17.
//

import Foundation
import SwiftData

@Model
final class DoubtLog {
    var id: UUID
    var content: String
    var createdAt: Date

    init(id: UUID = UUID(), content: String, createdAt: Date = Date()) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
    }
}
