@preconcurrency import SharedModels
import Vapor

func configure(_ app: Application) throws {
    app.webSocket("channel") { (req, ws) async in
        await WebSocketRepository.shared.add(ws)

        ws.onClose.whenComplete { _ in
            Task {
                await WebSocketRepository.shared.remove(ws)
            }
        }

        ws.onText { ws, _ async in
            try? await ws.close(code: .unacceptableData)
        }

        ws.onBinary { ws, data async in
            guard let incomingMessage = try? decoder.decode(IncomingMessage.self, from: data) else {
                try? await ws.close(code: .unacceptableData)
                return
            }

            let outgoingMessage: OutgoingMessage

            switch incomingMessage {
            case let .add(item):
                let newItem = Item(id: UUID(), text: item.text)
                await ItemRepository.shared.add(newItem)
                outgoingMessage = .add(item: newItem)

            case let .update(item):
                guard let updatedItem = await ItemRepository.shared.set(item) else {
                    return
                }
                outgoingMessage = .update(item: updatedItem)

            case let .delete(id):
                guard let deletedItem = await ItemRepository.shared.delete(withId: id) else {
                    return
                }
                outgoingMessage = .delete(item: deletedItem)
            }

            guard let data = try? encoder.encode(outgoingMessage) else {
                return
            }

            for ws in await WebSocketRepository.shared.get() {
                try? await ws.send([UInt8](data))
            }
        }

        let outgoingMessage = OutgoingMessage.items(items: await ItemRepository.shared.get())

        guard let data = try? encoder.encode(outgoingMessage) else {
            return
        }

        try? await ws.send([UInt8](data))
    }
}
