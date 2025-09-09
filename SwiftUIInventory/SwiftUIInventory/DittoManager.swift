//
//  DittoManager.swift
//  SwiftUIInventory
//
//  Created by Alexander on 2025-09-09.
//

import DittoSwift
import SwiftUI

final actor DittoManager {
    private(set) var dittoInstance: Ditto
    private var subscriptions = [DittoSyncSubscription]()

    init() async throws {
        guard let authURL = URL(string: Env.AUTH_URL) else { throw AppError.message("Auth URL not found") }
        let config = DittoConfig(databaseID: Env.APP_ID, connect: .server(url: authURL))
        let ditto = try await Ditto.open(config: config)
        self.dittoInstance = ditto

        ditto.auth?.expirationHandler = { [weak self] ditto, secondsRemaining in
            guard let self else { return }
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

    func initializeSubscription() -> DittoSyncSubscription? {
        do {
            let sub = try dittoInstance.sync.registerSubscription(query: "SELECT * FROM inventories")
            subscriptions.append(sub)
            return sub
        } catch {
            print("Subscription failed to register: \(error)")
            return nil
        }
    }

    func startSync() throws {
        try dittoInstance.sync.start()
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
}
