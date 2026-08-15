import Foundation
import SwiftData

@Model
final class Book {
    var id: UUID = UUID()
    var isbn: String = ""
    var title: String = ""
    var author: String = ""
    var coverURL: String? = nil
    var totalPages: Int = 0
    var currentPage: Int = 0
    var isCompleted: Bool = false
    var isAbandoned: Bool = false
    var sortOrder: Int = 0
    var startedAt: Date = Date()
    var completedAt: Date? = nil

    init(isbn: String, title: String, author: String, coverURL: String?, totalPages: Int) {
        self.id = UUID()
        self.isbn = isbn
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.totalPages = totalPages
        self.currentPage = 0
        self.isCompleted = false
        self.isAbandoned = false
        self.sortOrder = 0
        self.startedAt = .now
        self.completedAt = nil
    }
}
