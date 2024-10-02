import Foundation
import IssueReporting
import SharedModels

public final class WebSocketConnection<
    Incoming: Decodable & Sendable,
    Outgoing: Encodable & Sendable
>: Sendable {
    public enum Error: Swift.Error {
        case connection
        case transport
        case decoding(DecodingError)
        case encoding(EncodingError)
        case disconnected
        case closed
    }

    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let webSocketTask: URLSessionWebSocketTask

    public init(
        webSocketTask: URLSessionWebSocketTask,
        decoder: JSONDecoder,
        encoder: JSONEncoder
    ) {
        self.decoder = decoder
        self.encoder = encoder
        self.webSocketTask = webSocketTask
        webSocketTask.resume()
    }

    deinit {
        webSocketTask.cancel(with: .goingAway, reason: nil)
    }

    //    throws(WebSocket.Error)
    public func send(_ message: Outgoing) async throws {
        do {
            let messageData = try encoder.encode(message)
            try await webSocketTask.send(.data(messageData))
        } catch let error as EncodingError {
            throw Error.encoding(error)
        } catch {
            throw mapError()
        }
    }

    //    throws(WebSocket.Error)
    public func receiveSingle() async throws -> Incoming {
        do {
            let message = try await webSocketTask.receive()
            switch message {
            case let .data(messageData):
                return try decoder.decode(Incoming.self, from: messageData)

            case let .string(text):
                reportIssue("Did not expect to receive message as text")
                let messageData = text.data(using: .utf8)!
                return try decoder.decode(Incoming.self, from: messageData)

            @unknown default:
                reportIssue("Unknown message type")
                webSocketTask.cancel(with: .unsupportedData, reason: nil)
                throw Error.transport
            }
        } catch let error as DecodingError {
            throw Error.decoding(error)
        } catch {
            throw mapError()
        }
    }

    public func receive() -> AsyncThrowingStream<Incoming, Swift.Error> {
        AsyncThrowingStream { [weak self] in
            guard let self else { return nil }
            do {
                let message = try await self.receiveSingle()
                return Task.isCancelled ? nil : message
            } catch let error as WebSocketConnection.Error {
                throw error
            } catch {
                throw Error.transport
            }
        }
    }

    public func close() {
        webSocketTask.cancel(with: .normalClosure, reason: nil)
    }

    private func mapError() -> WebSocketConnection.Error {
        switch webSocketTask.closeCode {
        case .invalid: return .connection
        case .goingAway: return .disconnected
        case .normalClosure: return .closed
        default: return .transport
        }
    }
}
