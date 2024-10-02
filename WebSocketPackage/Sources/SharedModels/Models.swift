import Foundation

public struct Item: Codable {
    public let id: UUID
    public let text: String

    public init(id: UUID, text: String) {
        self.id = id
        self.text = text
    }
}

public enum IncomingMessage: Codable {
    case update(item: Item)
    case add(item: Item)
    case delete(id: UUID)
}

public enum OutgoingMessage: Codable {
    case items(items: [Item])
    case update(item: Item)
    case add(item: Item)
    case delete(item: Item)
}

public let decoder = JSONDecoder()
public let encoder = JSONEncoder()
