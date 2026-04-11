import Combine
import DittoSwift
import Foundation
import UIKit

final class AssetDittoManager {

    // MARK: - Singleton

    static let shared = AssetDittoManager()

    // MARK: - Published state

    private(set) var assets: [Asset] = []
    let assetsUpdated = PassthroughSubject<Void, Never>()

    // MARK: - Ditto

    private var ditto: Ditto!
    private var subscription: DittoSyncSubscription?
    private var storeObserver: DittoStoreObserver?

    private init() {
        startDitto()
    }

    deinit {
        if ditto.isSyncActive { ditto.stopSync() }
        subscription?.cancel()
        storeObserver?.cancel()
    }

    private func startDitto() {
        DittoLogger.minimumLogLevel = .debug
        do {
            ditto = Ditto(
                identity: .offlinePlayground(appID: "2e9a634e-58fc-4919-b606-33a78369fbb9")
            )
            try ditto.disableSyncWithV3()
            try ditto.setOfflineOnlyLicenseToken("o2d1c2VyX2lkbkRpdHRvU0VEZW1vT3JnZmV4cGlyeXgYMjAyNi0xMi0wMlQwNDo1OTo1OS45OTlaaXNpZ25hdHVyZXhYTDVMVk5YUUxoWXhHcUovUVBwT3BvZ29iZTE5dXBMcEk0a2hmWkhGRVdDelVtaWVTa0Nia3U5QXlPbWtyMCtleUZWREhJZmI5NDZrR01OcFBqMUlKL0E9PQ==")
            Task {
                do {
                    try await ditto.store.execute(
                        query: "ALTER SYSTEM SET DQL_STRICT_MODE = false"
                    )
                    try ditto.startSync()
                    print("✅ Ditto startSync succeeded")
                } catch {
                    print("❌ Ditto startSync failed: \(error)")
                }
            }
        } catch {
            let msg = (error as? DittoSwiftError)?.errorDescription ?? error.localizedDescription
            assertionFailure(msg)
        }
    }

    // MARK: - Subscription

    func subscribeAssets() {
        let query = "SELECT * FROM assets ORDER BY createdAt DESC"
        do {
            subscription = try ditto.sync.registerSubscription(query: query)
            storeObserver = try ditto.store.registerObserver(query: query) { [weak self] results in
                do {
                    let decoder = JSONDecoder()
                    self?.assets = try results.items.compactMap {
                        try decoder.decode(Asset.self, from: $0.jsonData())
                    }
                    self?.assetsUpdated.send()
                } catch {
                    print("AssetDittoManager observer error: \(error)")
                }
            }
        } catch {
            print("AssetDittoManager subscribeAssets error: \(error)")
        }
    }

    // MARK: - Insert

    func insertAsset(nsn: String, condition: String, notes: String, image: UIImage?) {
        var doc: [String: Any] = [
            "_id":       UUID().uuidString,
            "nsn":       nsn,
            "condition": condition,
            "notes":     notes,
            "createdAt": ISO8601DateFormatter().string(from: Date()),
            "deviceId":  UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        ]

        if let img = image {
            let thumb = img.resizedTo(maxDimension: 640)
            doc["photoJpegBase64"] = thumb.jpegData(compressionQuality: 0.65)?.base64EncodedString()
        }

        Task {
            do {
                try await ditto.store.execute(
                    query: "INSERT INTO assets DOCUMENTS (:doc)",
                    arguments: ["doc": doc]
                )
            } catch {
                let msg = (error as? DittoSwiftError)?.errorDescription ?? error.localizedDescription
                print("insertAsset error: \(msg)")
            }
        }
    }

    // MARK: - Delete

    func deleteAsset(id: String) {
        Task {
            do {
                try await ditto.store.execute(
                    query: "DELETE FROM assets WHERE _id = :id",
                    arguments: ["id": id]
                )
            } catch {
                let msg = (error as? DittoSwiftError)?.errorDescription ?? error.localizedDescription
                print("deleteAsset error: \(msg)")
            }
        }
    }

    // MARK: - Info view

    var dittoInfoView: DittoInfoViewController {
        DittoInfoViewController.create(ditto: ditto)
    }
}
