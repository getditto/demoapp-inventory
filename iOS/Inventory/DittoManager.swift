//
//  DittoManager.swift
//  Inventory
//
//  Created by Shunsuke Kondo on 2023/01/19.
//  Copyright © 2023 Ditto. All rights reserved.
//

import Combine
import DittoSwift
import Foundation

public enum SyncEvent {
    case initial
    case update
}

// MARK: - Class Implementation
final class DittoManager {

    // MARK: - Models for Views
    struct Models {
        var items = [ItemDittoModel]()
    }
    
    private(set) var models = Models()

    // MARK: - Singleton object
    static let shared = DittoManager()

    // MARK: - Private Ditto properties
    private var ditto: Ditto!

    private var subscription: DittoSyncSubscription?
    private var storeObserver: DittoStoreObserver?

    // MARK: - Combine Subjects (to be observed from outside of this class)
    let itemsUpdated = PassthroughSubject<
        (indices: IndexSet, event: SyncEvent), Never
    >()

    // constructor is private because this is a singleton class
    private init() {
        startDitto()
    }

    /// Performs cleanup of Ditto resources
    ///
    /// This method handles the graceful shutdown of Ditto components by:
    /// - Cancelling any active subscriptions
    /// - Cancelling store observers
    /// - Stopping the Ditto sync process
    ///
    deinit {
        if ditto.isSyncActive {
            ditto.stopSync()
        }
        subscription?.cancel()
        subscription = nil
        storeObserver?.cancel()
        storeObserver = nil
    }

    private func startDitto() {
        DittoLogger.minimumLogLevel = .debug

        do {
            // Initialize Ditto
            // https://docs.ditto.live/sdk/latest/install-guides/swift#integrating-and-initializing-sync
            ditto = Ditto(
                identity:
                    .onlinePlayground(
                        appID: Env.APP_ID,
                        token: Env.ONLINE_AUTH_TOKEN,
                        enableDittoCloudSync: false
                    )
            )

            // Disable sync with V3 Ditto
            try ditto.disableSyncWithV3()
            Task {
                // Disable avoid_redundant_bluetooth
                // https://docs.ditto.live/sdk/latest/sync/managing-redundant-bluetooth-le-connections#disabling-redundant-connections
                try await ditto.store.execute(
                    query:
                        "ALTER SYSTEM SET mesh_chooser_avoid_redundant_bluetooth = false"
                )

                // disable strict mode - allows for DQL with counters and objects as CRDT maps, must be called before startSync
                // TODO - insert doc link
                try await ditto.store.execute(
                    query: "ALTER SYSTEM SET DQL_STRICT_MODE = false"
                )
                try ditto.startSync()
            }
        } catch {
            let dittoErr = (error as? DittoSwiftError)?.errorDescription
            assertionFailure(dittoErr ?? error.localizedDescription)
        }
    }

    var dittoInfoView: DittoInfoViewController {
        DittoInfoViewFactory.create(ditto: ditto)
    }
}

// MARK: - Upsert Methods

extension DittoManager {

    /// Subscribes to all inventory items in the "inventories" collection.
    ///
    /// This method registers a subscription to the "inventories" collection using a DQL query.
    /// It also sets up an observer to monitor changes in the database, calculating the differences
    /// between syncs using a DittoDiffer. The observer sends updates to the `itemsUpdated` subject
    /// based on the type of change (initial load or update).
    ///
    /// - Note: This method should be called to start monitoring inventory items for changes.
    func subscribeAllInventoryItems() {
        let query = "SELECT * FROM inventories"
        do {
            // Create Subscription
            // https://docs.ditto.live/sdk/latest/sync/syncing-data#creating-subscriptions
            self.subscription = try ditto.sync.registerSubscription(
                query: query
            )

            // DittoDiffer - used to calculate the delta changes between syncs
            // TODO put in link to docs that describes the differ
            let dittoDiffer = DittoDiffer()

            // Register Observer to see changes in the database from sync
            // https://docs.ditto.live/sdk/latest/crud/observing-data-changes
            storeObserver = try ditto.store.registerObserver(query: query) {
                [weak self] results in
                
                let allItems = results.items.compactMap{ ItemDittoModel($0.jsonString()) }
                self?.models.items = allItems
                let diff = dittoDiffer.diff(results.items)

                // NOTE:  if you are curious on why we don't handle deletions - the app code
                // currently does not allow deleting of inventory items, so there is no reason to handle
                // checking the count of deletions.

                // if the insertions count is greater than zero and others are empty
                // assume initial load
                if diff.insertions.count > 0 && diff.deletions.isEmpty
                    && diff.updates.isEmpty
                {
                    let event = SyncEvent.initial
                    self?.itemsUpdated.send(
                        (indices: diff.insertions, event: event)
                    )

                } else {
                    let event = SyncEvent.update
                    self?.itemsUpdated.send(
                        (indices: diff.updates, event: event)
                    )
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }

    /// Prepopulates the "inventories" collection with new items if they do not already exist.
    ///
    /// This method executes a DQL query to insert new documents into the "inventories" collection.
    /// It uses the "INSERT INTO inventories INTIAL DOCUMENTS" statement to ensure that the documents
    /// are only inserted if they do not already exist, matching the behavior of `.insertDefaultIfAbsent`.
    ///
    /// - Parameter itemIds: An array of integers representing the IDs of the items to be inserted.
    func prepopulateItemsIfAbsent(itemIds: [Int]) {

        // CREATE new items using the INSERT INTO xxx INTIAL statement - must use
        // initial for first time seeding of documents so sync doesn't screw up
        // between peers - this matches .insertDefaultIfAbsent in QueryBuilder
        let query = "INSERT INTO inventories INTIAL DOCUMENTS (:item)"

        Task {
            // Create a transaction to run inserts into with DQL - this is the equvilant to scoped transaction using store.write
            // TODO insert doc link to transactions with DQL
            do {
                try await ditto.store.transaction { transaction in
                    for itemId in itemIds {
                        do {
                            try await transaction.execute(
                                query: query,
                                arguments: [
                                    "item":
                                        [
                                            "_id": itemId,
                                            "counter": 0.0
                                        ]
                                ]
                            )
                        } catch {
                            let dittoErr = (error as? DittoSwiftError)?
                                .errorDescription
                            assertionFailure(
                                dittoErr ?? error.localizedDescription
                            )
                            return .rollback
                        }
                    }
                    return .commit
                }
            } catch {
                let dittoErr = (error as? DittoSwiftError)?
                    .errorDescription
                assertionFailure(dittoErr ?? error.localizedDescription)
            }
        }
    }

    func incrementCounterFor(id: Int) {
        // UPDATE Counter using DQL PN_INCREMENT function
        // TODO insert URL to documenation link
        let query =
            "UPDATE inventories APPLY counter PN_INCREMENT BY 1.0 WHERE _id = :id"
        Task {
            do {
                try await ditto.store.execute(query: query, arguments: ["id": id])
            } catch {
                let dittoErr = (error as? DittoSwiftError)?
                    .errorDescription
                assertionFailure(dittoErr ?? error.localizedDescription)
            }
        }
    }

    func decrementCounterFor(id: Int) {
        // UPDATE Counter using DQL PN_INCREMENT function
        // TODO insert URL to documenation link
        let query =
            "UPDATE inventories APPLY counter PN_INCREMENT BY -1.0 WHERE _id = :id"
        Task {
            do {
                try await ditto.store.execute(query: query, arguments: ["id": id])
            } catch {
                let dittoErr = (error as? DittoSwiftError)?
                    .errorDescription
                assertionFailure(dittoErr ?? error.localizedDescription)
            }
        }
    }
}
