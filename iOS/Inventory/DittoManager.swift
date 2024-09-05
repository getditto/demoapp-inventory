//
//  DittoManager.swift
//  Inventory
//
//  Created by Shunsuke Kondo on 2023/01/19.
//  Copyright © 2023 Ditto. All rights reserved.
//

import Foundation
import DittoSwift
import Combine


// MARK: - Class Implementation

final class DittoManager: ObservableObject {

    // MARK: - Ditto Collections

    private final class Collections {
        let inventories: DittoCollection

        init(_ store: DittoStore) {
            self.inventories = store.collection(ItemDittoModel.collectionName)
        }
    }

    // MARK: - Models for Views

    @Published var items = [ItemDittoModel]()

    // MARK: - Singleton object

    static let shared = DittoManager()

    // MARK: - Private Ditto properties

    lazy var ditto: Ditto! = { startDitto() }()
    private lazy var collections = { Collections(ditto.store) }()

    private var subscriptions = [DittoSyncSubscription]()
    private var liveQueries = [DittoLiveQuery]()

    // MARK: - Combine Subjects (to be observed from outside of this class)
    let itemsUpdated = PassthroughSubject<(indices: [Int], event: DittoLiveQueryEvent), Never>()

    // constructor is private because this is a singleton class
    private init() {}

    private func startDitto() -> Ditto {
        DittoLogger.minimumLogLevel = .debug

        let ditto = Ditto(identity: .onlinePlayground(appID: Env.APP_ID, token: Env.ONLINE_AUTH_TOKEN, enableDittoCloudSync: false))

        do {
            // Disable sync with V3 Ditto
            try ditto.disableSyncWithV3()
            try ditto.startSync()
        } catch {
            let dittoErr = (error as? DittoSwiftError)?.errorDescription
            assertionFailure(dittoErr ?? error.localizedDescription)
        }

        return ditto
    }
}


// MARK: - Upsert Methods

extension DittoManager {

    func subscribeAllInventoryItems() {

        do {
            subscriptions.append(try ditto.sync.registerSubscription(query: "SELECT * FROM inventories"))
        } catch {
            print("Query Error: \(error)")
        }

        liveQueries.append(
            collections.inventories.findAll().observeLocal { [weak self] docs, event in
                self?.items = docs.map { ItemDittoModel($0) }
            }
        )
    }

    func prepopulateItemsIfAbsent(items: [ItemDittoModel]) {
        ditto.store.write { transaction in
            let scope = transaction.scoped(toCollectionNamed: ItemDittoModel.collectionName)
            items.map{ $0.document() }.forEach {
                do {
                    try scope.upsert($0, writeStrategy: .insertDefaultIfAbsent)
                } catch {
                    let dittoErr = (error as? DittoSwiftError)?.errorDescription
                    assertionFailure(dittoErr ?? error.localizedDescription)
                }

            }
        }
    }

    func incrementCounterFor(id: String) {

        collections.inventories.findByID(id).update { doc in
            doc?["counter"].counter?.increment(by: 1)
        }
    }

    func decrementCounterFor(id: String)  {

        collections.inventories.findByID(id).update { doc in
            doc?["counter"].counter?.increment(by: -1)
        }
    }
}
