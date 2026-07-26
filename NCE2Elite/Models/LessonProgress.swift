/// LessonProgress — SwiftData 持久化模型
/// 记录每课的播放进度与收藏状态

import Foundation
import SwiftData

@Model
final class LessonProgress {
    @Attribute(.unique) var lessonId: Int
    var isFavorite: Bool = false
    var lastPlayedPosition: Double = 0
    var isCompleted: Bool = false
    var lastPlayedDate: Date?

    init(lessonId: Int,
         isFavorite: Bool = false,
         lastPlayedPosition: Double = 0,
         isCompleted: Bool = false,
         lastPlayedDate: Date? = nil) {
        self.lessonId = lessonId
        self.isFavorite = isFavorite
        self.lastPlayedPosition = lastPlayedPosition
        self.isCompleted = isCompleted
        self.lastPlayedDate = lastPlayedDate
    }
}
