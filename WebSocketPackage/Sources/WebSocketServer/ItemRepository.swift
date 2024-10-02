import Foundation
import SharedModels

actor ItemRepository {
    static let shared = ItemRepository()

    private var items: [Item] = [
        Item(id: .init(), text: "Item 1"),
        Item(id: .init(), text: "Item 2"),
        Item(id: .init(), text: "Item 3"),
        Item(id: .init(), text: "Item 4"),
        Item(id: .init(), text: "Item 5"),
    ]

    func get() async -> [Item] { items }

    func get(withId id: UUID) async -> Item? {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        return items[index]
    }

    func set(_ item: Item) async -> Item? {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return nil
        }
        items[index] = item
        return item
    }

    func add(_ item: Item) async {
        items.append(item)
    }

    func delete(withId id: UUID) async -> Item? {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        return items.remove(at: index)
    }
}
