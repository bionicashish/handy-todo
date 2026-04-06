import Foundation

struct ChecklistItem: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var title: String
    var isCompleted: Bool

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
    }
}
