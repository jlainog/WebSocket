import Foundation
import IdentifiedCollections
import SharedModels

actor ItemRepository {
    static let shared = ItemRepository()

    private var items: IdentifiedArrayOf<Item> = [
        Item(id: .init(), text: "Item 1"),
        Item(id: .init(), text: "Item 2"),
        Item(id: .init(), text: "Item 3"),
        Item(id: .init(), text: "Item 4"),
        Item(id: .init(), text: "Item 5"),
    ]

    func get() async -> IdentifiedArrayOf<Item> { items }

    func get(withId id: UUID) async -> Item? {
        items[id: id]
    }

    func set(_ item: Item) async -> Item? {
        items[id: item.id] = item
        return item
    }

    func add(_ item: Item) async {
        items.append(item)
    }

    func delete(withId id: UUID) async -> Item? {
        items.remove(id: id)
    }
}
