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
                identity: .onlinePlayground(
                    appID: Env.DITTO_APP_ID,
                    token: Env.DITTO_PLAYGROUND_TOKEN,
                    enableDittoCloudSync: false
                )
            )
            try ditto.disableSyncWithV3()
            Task {
                try await ditto.store.execute(
                    query: "ALTER SYSTEM SET DQL_STRICT_MODE = false"
                )
                try ditto.startSync()
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

    // MARK: - Info view

    var dittoInfoView: DittoInfoViewController {
        DittoInfoViewController.create(ditto: ditto)
    }
}
