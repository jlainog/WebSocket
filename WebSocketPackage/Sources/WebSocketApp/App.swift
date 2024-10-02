import Foundation
import IssueReporting
import SharedModels
import SwiftUI

public struct AppView: View {
    @State private var webSocketConnectionTask: Task<Void, Never>? = nil
    @State private var connection: WebSocketConnection<OutgoingMessage, IncomingMessage>?

    @State private var items: [Item] = []

    @State private var currentEditingItemId: UUID = UUID()
    @State private var currentEditingItemText: String = ""

    @State private var errorAlertTitle: String = ""
    @State private var errorAlertMessage: String = ""

    @State private var errorAlertPresented: Bool = false
    @State private var newItemAlertPresented: Bool = false
    @State private var editItemAlertPresented: Bool = false
    @State private var deleteItemConfirmationPresented: Bool = false

    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView([.vertical]) {
                LazyVStack {
                    ForEach(items, id: \.id) { item in
                        ItemView(text: item.text) {
                            // Prepare form for editing of existing Item.
                            currentEditingItemId = item.id
                            currentEditingItemText = item.text

                            editItemAlertPresented.toggle()
                        } delete: {
                            // Prepare form for deletion of existing Item.
                            currentEditingItemId = item.id
                            currentEditingItemText = item.text

                            deleteItemConfirmationPresented.toggle()
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Items")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        // Prepare form for editing of new Item.
                        currentEditingItemId = UUID()
                        currentEditingItemText = ""

                        newItemAlertPresented.toggle()
                    }
                    .labelStyle(.iconOnly)
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Text("\(items.count) Items")
                }
            }
            // Error Alert
            .alert(errorAlertTitle, isPresented: $errorAlertPresented) {
                Button("Ok", role: .cancel) { }
            } message: {
                Text(errorAlertMessage)
            }
            // New Item Alert
            .alert("New Item", isPresented: $newItemAlertPresented) {
                TextField("Text", text: $currentEditingItemText)
                Button("Cancel", role: .cancel) { }
                Button("Ok", action: saveNewItem)
            }
            // Edit existing Item Alert
            .alert("Edit Item", isPresented: $editItemAlertPresented) {
                TextField("Text", text: $currentEditingItemText)
                Button("Cancel", role: .cancel) { }
                Button("Ok", action: saveExistingItem)
            }
            // Delete existing Item Confirmation
            .confirmationDialog("Delete Item", isPresented: $deleteItemConfirmationPresented) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive, action: deleteItem)
            } message: {
                Text("Delete \"\(currentEditingItemText)\"?")
            }
            // Open WebSocket Connection and start receiving messages on View appear
            .onAppear {
                webSocketConnectionTask?.cancel()

                webSocketConnectionTask = Task {
                    await openAndConsumeWebSocketConnection()
                }
            }
            // Refresh WebSocket Connection on Pull to Refresh
            .refreshable {
                webSocketConnectionTask?.cancel()

                webSocketConnectionTask = Task {
                    await openAndConsumeWebSocketConnection()
                }
            }
            // Close WebSocket Connection on View disappear
            .onDisappear {
                webSocketConnectionTask?.cancel()
            }
        }
    }

    @MainActor func openAndConsumeWebSocketConnection() async {
        // Close any existing WebSocketConnection
        if let connection {
            connection.close()
        }

        let connection = createWebSocketConnection()
        self.connection = connection

        do {
            // Start consuming IncomingMessages
            for try await message in connection.receive() {
                switch message {
                case let .items(items):
                    self.items = items

                case let .add(item):
                    items.append(item)

                case let .update(item):
                    guard let index = items.firstIndex(where: { $0.id == item.id }) else {
                        return reportIssue("Expected updated Item to exist")
                    }

                    items[index] = item

                case let .delete(item):
                    guard let index = items.firstIndex(where: { $0.id == item.id }) else {
                        return reportIssue("Expected deleted Item to exist")
                    }

                    let _ = items.remove(at: index)
                }
            }

            print("IncomingMessage stream ended")
        } catch {
            print("Error receiving messages:", error)
        }
    }

    func saveNewItem() {
        let itemId = currentEditingItemId
        let itemText = currentEditingItemText

        guard let connection else {
            return reportIssue("Expected Connection to exist")
        }

        Task {
            do {
                let newItem = Item(id: itemId, text: itemText)

                try await connection.send(.add(item: newItem))
            } catch {
                print("Error saving new Item:", error)
            }
        }
    }

    func saveExistingItem() {
        let itemId = currentEditingItemId
        let itemText = currentEditingItemText

        guard let connection else {
            return reportIssue("Expected Connection to exist")
        }

        Task {
            do {
                let updatedItem = Item(id: itemId, text: itemText)

                try await connection.send(.update(item: updatedItem))
            } catch {
                print("Error saving existing Item:", error)
            }
        }
    }

    func deleteItem() {
        let itemId = currentEditingItemId

        guard let connection else {
            return reportIssue("Expected Connection to exist")
        }

        Task {
            do {
                try await connection.send(.delete(id: itemId))
            } catch {
                print("Error deleting Item:", error)
            }
        }
    }
}

struct ItemView: View {
    let text: String
    let edit: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(text)
                .multilineTextAlignment(.leading)
                .padding()
            Spacer()
            Button("Edit", systemImage: "pencil", action: edit)
                .labelStyle(.iconOnly)
                .padding()
            Button("delete", systemImage: "trash.fill", role: .destructive, action: delete)
                .labelStyle(.iconOnly)
                .padding()
        }
    }
}

#Preview {
    AppView()
}

func createWebSocketConnection() -> WebSocketConnection<OutgoingMessage, IncomingMessage> {
    let url = URL(string: "ws://127.0.0.1:8080/channel")!
    let request = URLRequest(url: url)
    let webSocketTask = URLSession.shared.webSocketTask(with: request)
    return WebSocketConnection<OutgoingMessage, IncomingMessage>(
        webSocketTask: webSocketTask,
        decoder: decoder,
        encoder: encoder
    )
}
