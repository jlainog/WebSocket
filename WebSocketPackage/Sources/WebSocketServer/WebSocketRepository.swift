import Vapor

actor WebSocketRepository {
    static let shared = WebSocketRepository()

    private var webSockets: [WebSocket] = []

    func get() async -> [WebSocket] {
        webSockets
    }

    func add(_ ws: WebSocket) async {
        webSockets.append(ws)
    }

    func remove(_ ws: WebSocket) async {
        webSockets.removeAll(where: { $0 === ws })
    }
}
