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

final class DittoManager {

    // MARK: - Ditto Collections

    private final class Collections {
        let inventories: DittoCollection

        init(_ store: DittoStore) {
            self.inventories = store.collection(ItemDittoModel.collectionName)
        }
    }

    // MARK: - Models for Views

    struct Models {
        var items = [ItemDittoModel]()
    }

    private(set) var models = Models()

    // MARK: - Singleton object

    static let shared = DittoManager()

    // MARK: - Private Ditto properties

    private lazy var ditto: Ditto! = { startDitto() }()
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
            // Disable avoid_redundant_bluetooth
            Task {
                try await ditto.store.execute(query: "ALTER SYSTEM SET mesh_chooser_avoid_redundant_bluetooth = false")
            }
            try ditto.startSync()
        } catch {
            let dittoErr = (error as? DittoSwiftError)?.errorDescription
            assertionFailure(dittoErr ?? error.localizedDescription)
        }

        return ditto
    }

    var dittoInfoView: DittoInfoViewController {
        DittoInfoViewFactory.create(ditto: ditto)
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
                guard let self = self else { return }

                let allItems = docs.map { ItemDittoModel($0) }
                self.models.items = allItems

                switch event {
                case .initial:

                    self.itemsUpdated.send((indices: allItems.indexes, event: event))

                case .update(let detail):

                    self.itemsUpdated.send((indices: detail.updates, event: event))

                @unknown default: break
                }
            }
        )
    }

    func prepopulateItemsIfAbsent(itemIds: [Int]) {

        let allItems = itemIds.map {
            ["_id": $0,
             "counter": DittoCounter()]
        }

        ditto.store.write { transaction in
            let scope = transaction.scoped(toCollectionNamed: ItemDittoModel.collectionName)
            allItems.forEach {
                do {
                    try scope.upsert($0, writeStrategy: .insertDefaultIfAbsent)
                } catch {
                    let dittoErr = (error as? DittoSwiftError)?.errorDescription
                    assertionFailure(dittoErr ?? error.localizedDescription)
                }

            }
        }
    }

    func incrementCounterFor(id: Int) {

        collections.inventories.findByID(id).update { doc in
            doc?["counter"].counter?.increment(by: 1)
        }
    }

    func decrementCounterFor(id: Int)  {

        collections.inventories.findByID(id).update { doc in
            doc?["counter"].counter?.increment(by: -1)
        }
    }
}
