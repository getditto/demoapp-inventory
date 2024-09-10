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

/// Singleton implementation of the DittoManager.
/// This class keeps the persistant connection with Ditto and allows any view to be able to interact with Ditto when it needs to
final class DittoManager: ObservableObject {

    // MARK: - Ditto Collections

    private final class Collections {
        let inventories: DittoCollection

        init(_ store: DittoStore) {
            self.inventories = store.collection(collectionNameKey)
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


    /// Creates a subscription to sync changes with other peers in the mesh.
    /// Adds a live query which will load the now synced data into memory so that views can use it.
    func subscribeAllInventoryItems() {
        do {
            subscriptions.append(try ditto.sync.registerSubscription(query: "SELECT * FROM \(collectionNameKey)"))
        } catch {
            print("Query Error: \(error)")
        }

        liveQueries.append(
            collections.inventories.findAll().observeLocal { [weak self] docs, event in
                self?.items = docs.map { ItemDittoModel($0) }
            }
        )
    }


    /// Takes the hard coded documents and adds them if they do not already exist in the local store.
    /// - Parameter items: The Ditto items that will be used in the views.
    func prepopulateItemsIfAbsent(items: [ItemDittoModel]) {
        ditto.store.write { transaction in
            let scope = transaction.scoped(toCollectionNamed: collectionNameKey)
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


    /// Adds one to the Ditto counter on the Ditto document. This will update the local DB and then automatically sync the change with other peers if it can.
    /// - Parameter id: The id of the document to update
    func incrementCounterFor(id: String) {
        collections.inventories.findByID(id).update { doc in
            doc?[counterKey].counter?.increment(by: 1)
        }
    }


    //// Subtracts one from the Ditto counter on the Ditto document. This will update the local DB and then automatically sync the change with other peers if it can.
    /// - Parameter id: The id of the document to update
    func decrementCounterFor(id: String)  {
        collections.inventories.findByID(id).update { doc in
            doc?[counterKey].counter?.increment(by: -1)
        }
    }
}
