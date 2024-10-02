import Foundation
import IdentifiedCollections

public struct Item: Codable, Identifiable {
    public let id: UUID
    public let text: String

    public init(id: UUID, text: String) {
        self.id = id
        self.text = text
    }
}

public enum AppMessage: Codable {
    case update(item: Item)
    case add(item: Item)
    case delete(id: UUID)
}

public enum ServerMessage: Codable {
    case items(items: IdentifiedArrayOf<Item>)
    case update(item: Item)
    case add(item: Item)
    case delete(item: Item)
}

public let decoder = JSONDecoder()
public let encoder = JSONEncoder()
