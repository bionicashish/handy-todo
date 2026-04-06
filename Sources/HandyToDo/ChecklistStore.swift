import Foundation
import Observation

@Observable
@MainActor
final class ChecklistStore {

    var items: [ChecklistItem] = [] {
        didSet { persistItems() }
    }

    private let userDefaultsKey = "com.handytodo.items.v1"

    init() {
        loadItems()
    }

    func add(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(ChecklistItem(title: trimmed))
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    func clearAll() {
        items.removeAll()
    }

    private func loadItems() {
        guard
            let data = UserDefaults.standard.data(forKey: userDefaultsKey),
            let decoded = try? JSONDecoder().decode([ChecklistItem].self, from: data)
        else { return }
        items = decoded
    }

    private func persistItems() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
}
