@preconcurrency import SharedModels
import Vapor

func configure(_ app: Application) throws {
    app.webSocket("channel") { (req, ws) async in
        do {
            let initialListOfItems = ServerMessage.items(
                items: await ItemRepository.shared.get()
            )
            let data = try encoder.encode(initialListOfItems)
            try await ws.send([UInt8](data))
        } catch {
            print("Error sending initial list of items: \(error)")
        }

        await WebSocketRepository.shared.add(ws)

        ws.onClose.whenComplete { _ in
            Task { await WebSocketRepository.shared.remove(ws) }
        }

        ws.onText { ws, _ async in
            try? await ws.close(code: .unacceptableData)
        }

        ws.onBinary { ws, data async in
            do {
                guard let sendData = try await handleData(data) else {
                    return
                }

                for ws in await WebSocketRepository.shared.get() {
                    try? await ws.send([UInt8](sendData))
                }
            } catch {
                try? await ws.close(code: .unacceptableData)
            }
        }
    }
}

func handleData(_ data: ByteBuffer) async throws -> Data? {
    let appMessage = try decoder.decode(AppMessage.self, from: data)

    let serverMessage: ServerMessage

    switch appMessage {
    case let .add(item):
        await ItemRepository.shared.add(item)
        serverMessage = .add(item: item)

    case let .update(item):
        guard let updatedItem = await ItemRepository.shared.set(item) else {
            return nil
        }
        serverMessage = .update(item: updatedItem)

    case let .delete(id):
        guard let deletedItem = await ItemRepository.shared.delete(withId: id) else {
            return nil
        }
        serverMessage = .delete(item: deletedItem)
    }

    return try encoder.encode(serverMessage)
}
