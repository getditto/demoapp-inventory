//
//  DittoProvider.swift
//  SwiftUIInventory
//
//  Created by Alexander on 2025-09-09.
//

import Combine
import DittoSwift
import SwiftUI

struct ObserverResult<T: Codable> {
    let results: [T]
    let signalNext: () -> Void

    init(results: [T], signalNext: @escaping () -> Void) {
        self.results = results
        self.signalNext = signalNext
    }
}

final actor DittoManager {
    private(set) var dittoInstance: Ditto
    private var subscriptions = [DittoSyncSubscription]()
    private var inventoryObserver: DittoStoreObserver?

    let passthroughSubject = PassthroughSubject<ObserverResult<ItemModel>, Never>()

    var inventoryPublisher: AnyPublisher<ObserverResult<ItemModel>, Never> {
        passthroughSubject.eraseToAnyPublisher()
    }

    init() async throws {
        guard let authURL = URL(string: Env.AUTH_URL) else { throw AppError.message("Auth URL not found") }
        let config = DittoConfig(databaseID: Env.APP_ID, connect: .server(url: authURL))
        let ditto = try await Ditto.open(config: config)
        try ditto.disableSyncWithV3()
        self.dittoInstance = ditto

        ditto.auth?.expirationHandler = { ditto, secondsRemaining in
            ditto.auth?.login(token: Env.ONLINE_AUTH_TOKEN, provider: .development) { clientInfo, error in
                guard let error else {
                    print("Ditto Authentication success")
                    return
                }
                print("Ditto Authentication failed with error: \(error)")
            }
        }

        try await ditto.store.execute(query: "ALTER SYSTEM SET mesh_chooser_avoid_redundant_bluetooth = false")
        try await ditto.store.execute(query: "ALTER SYSTEM SET dql_strict_mode = false")
    }

    @discardableResult func initializeSubscription() -> DittoSyncSubscription? {
        do {
            guard subscriptions.isEmpty else { throw AppError.message("Subscription is already active") }
            let sub = try dittoInstance.sync.registerSubscription(query: "SELECT * FROM inventories")
            subscriptions.append(sub)
            try startSync()
            return sub
        } catch {
            print("Subscription failed to register: \(error)")
            return nil
        }
    }

    func setObserver() throws {
        guard inventoryObserver == nil else { throw AppError.message("Inventory observer is already active") }
        inventoryObserver = try dittoInstance.store.registerObserver(query: "SELECT * FROM inventories", handlerWithSignalNext: { [weak self] result, signalNext in
            Task {
                guard let self else { return }
                let decodedItems = result.items.compactMap { item -> ItemModel? in
                    do {
                        let item = try JSONDecoder().decode(ItemModel.self, from: item.jsonData())
                        return item
                    } catch {
                        print("Unable to decode item: \(error) - \(String(data: item.jsonData(), encoding: .utf8) ?? "No data")")
                        return nil
                    }
                }
                await self.passthroughSubject.send(ObserverResult(results: decodedItems, signalNext: signalNext))
            }
        })
    }

    func updateCounter(itemID: Codable, increment: Double = 1.0) async throws {
        let data = try JSONEncoder().encode(itemID)
        let object = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        try await dittoInstance.store.execute(
            query: "UPDATE inventories APPLY stock PN_INCREMENT BY \(increment) WHERE _id = (:id)",
            arguments: [
                "id": object
            ]
        )
    }

    func insertInitialDocuments(document: ItemModel) async throws {
        let data = try JSONEncoder().encode(document)
        let object = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        try await dittoInstance.store.execute(
            query: "INSERT INTO inventories DOCUMENTS (:document) ON ID CONFLICT DO UPDATE",
            arguments: [
                "document": object
            ]
        )
    }

    func deleteAllDocuments() async throws {
        try await dittoInstance.store.execute(query: "DELETE FROM inventories")
    }

    func terminateObserver() {
        self.inventoryObserver?.cancel()
        self.inventoryObserver = nil
    }

    func startSync() throws {
        try dittoInstance.sync.start()
    }

    func stopSync() {
        dittoInstance.sync.stop()
    }
}

@Observable final class DittoProvider {
    private(set) var dittoManager: DittoManager

    var ditto: Ditto {
        get async {
            await dittoManager.dittoInstance
        }
    }

    init() async throws {
        self.dittoManager = try await DittoManager()
    }

    func insertInitialModel(model: ItemModel) async throws {
        try await dittoManager.insertInitialDocuments(document: model)
    }

    func incrementCount(modelID: ItemCompositeKey, increment: Double) async throws {
        guard increment != 0 else { return }
        try await dittoManager.updateCounter(itemID: modelID, increment: increment)
    }
}
