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
        if ditto.sync.isActive {
            ditto.sync.stop()
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
            // https://docs.ditto.live/sdk/latest/install-guides/swift
            guard let serverURL = URL(string: Env.DITTO_SERVER_URL) else {
                fatalError("DITTO_SERVER_URL is missing or invalid: \"\(Env.DITTO_SERVER_URL)\". Set it in .env before building.")
            }
            let config = DittoConfig(
                databaseID: Env.DITTO_DATABASE_ID,
                connect: .server(url: serverURL)
            )
            ditto = try Ditto.openSync(config: config)

            // The expiration handler logs in with the development token on initial
            // auth and ahead of token expiry.
            // https://docs.ditto.live/sdk/latest/auth-and-authorization
            ditto.auth?.expirationHandler = { expiredDitto, _ in
                expiredDitto.auth?.login(
                    token: Env.DITTO_DEVELOPMENT_TOKEN,
                    provider: .development
                ) { _, error in
                    if let error {
                        print("Ditto auth failed: \(error)")
                    }
                }
            }

            // DQL strict mode is off, so objects are treated as CRDT MAPs and
            // non-REGISTER types like COUNTER don't require collection definitions
            // on UPDATE/SELECT. https://docs.ditto.live/dql/strict-mode
            try ditto.sync.start()
        } catch {
            let dittoErr = (error as? DittoError)?.errorDescription
            assertionFailure(dittoErr ?? error.localizedDescription)
        }
    }

    var dittoInfoView: DittoInfoViewController {
        DittoInfoViewFactory.create(ditto: ditto)
    }
}

// MARK: - Upsert Methods

extension DittoManager {

    /// Subscribes to all inventory items in the "inventory" collection.
    ///
    /// This method registers a subscription to the "inventory" collection using a DQL query.
    /// It also sets up an observer to monitor changes in the database, calculating the differences
    /// between syncs using a DittoDiffer. The observer sends updates to the `itemsUpdated` subject
    /// based on the type of change (initial load or update).
    ///
    /// - Note: This method should be called to start monitoring inventory items for changes.
    func subscribeAllInventoryItems() {
        let query = "SELECT * FROM inventory"
        do {
            // Create Subscription
            // https://docs.ditto.live/sdk/latest/sync/syncing-data#creating-subscriptions
            self.subscription = try ditto.sync.registerSubscription(
                query: query
            )

            // DittoDiffer - used to calculate the delta changes between syncs
            // https://docs.ditto.live/sdk/latest/crud/read#diffing-results
            let dittoDiffer = DittoDiffer()

            // Register Observer to see changes in the database from sync
            // https://docs.ditto.live/sdk/latest/crud/observing-data-changes
            storeObserver = try ditto.store.registerObserver(query: query) {
                [weak self] results in
                
                do {
                    let diff = dittoDiffer.diff(results.items)
                    let decoder = JSONDecoder()
                    let allItems = try results.items.compactMap { item -> ItemDittoModel? in
                        let model = try decoder.decode(ItemDittoModel.self, from: item.jsonData())
                        // Free native memory backing the result item — do not use it after this.
                        item.dematerialize()
                        return model
                    }
                    self?.models.items = allItems

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
                } catch {
                    print("Error: \(error)")
                }
            }
        } catch {
            print("Error: \(error)")
        }
    }

    /// Prepopulates the "inventory" collection with new items if they do not already exist.
    ///
    /// This method executes a DQL query to insert new documents into the "inventory" collection.
    /// It uses INITIAL DOCUMENTS to ensure that the documents are only inserted if they do not
    /// already exist. The COUNTER type declaration ensures the counter field is created as a
    /// COUNTER CRDT (not a REGISTER), which supports INCREMENT operations and is compatible
    /// with the MongoDB connector.
    /// https://docs.ditto.live/dql/types-and-definitions
    ///
    /// - Parameter itemIds: An array of integers representing the IDs of the items to be inserted.
    func prepopulateItemsIfAbsent(itemIds: [Int]) {

        // INSERT with COUNTER type declaration — the collection definition is required on INSERT
        // so the counter field is created as a COUNTER CRDT, not a plain REGISTER.
        // https://docs.ditto.live/dql/insert#insert-with-initial-documents
        let query = "INSERT INTO COLLECTION inventory (counter COUNTER) INITIAL DOCUMENTS (:item)"

        Task {
            // Run the inserts inside a single DQL transaction.
            // https://docs.ditto.live/sdk/latest/crud/transactions
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
                                            "counter": 0
                                        ]
                                ]
                            )
                        } catch {
                            let dittoErr = (error as? DittoError)?
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
                let dittoErr = (error as? DittoError)?
                    .errorDescription
                assertionFailure(dittoErr ?? error.localizedDescription)
            }
        }
    }

    func incrementCounterFor(id: Int) {
        // Increment the COUNTER using APPLY — no collection definition needed on UPDATE
        // with DQL_STRICT_MODE = false (https://docs.ditto.live/dql/strict-mode)
        // https://docs.ditto.live/dql/types-and-definitions
        let query =
            "UPDATE inventory APPLY counter INCREMENT BY 1 WHERE _id = :id"
        Task {
            do {
                try await ditto.store.execute(query: query, arguments: ["id": id])
            } catch {
                let dittoErr = (error as? DittoError)?
                    .errorDescription
                assertionFailure(dittoErr ?? error.localizedDescription)
            }
        }
    }

    func decrementCounterFor(id: Int) {
        // Decrement the COUNTER using APPLY — no collection definition needed on UPDATE
        // with DQL_STRICT_MODE = false (https://docs.ditto.live/dql/strict-mode)
        // https://docs.ditto.live/dql/types-and-definitions
        let query =
            "UPDATE inventory APPLY counter INCREMENT BY -1 WHERE _id = :id"
        Task {
            do {
                try await ditto.store.execute(query: query, arguments: ["id": id])
            } catch {
                let dittoErr = (error as? DittoError)?
                    .errorDescription
                assertionFailure(dittoErr ?? error.localizedDescription)
            }
        }
    }
}
