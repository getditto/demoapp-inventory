//
//  InventoryListViewModel.swift
//  SwiftUIInventory
//
//  Created by Alexander on 2025-09-11.
//

import SwiftUI
import Combine
//import DittoSwift

@Observable final class InventoryListViewModel {
    let dittoProvider: DittoProvider

    var itemModels: [ItemModel] = []

    @ObservationIgnored private(set) var inventoryObserver: AnyCancellable?

    init(dittoProvider: DittoProvider) {
        self.dittoProvider = dittoProvider
    }

    func observeInventories() async {
        self.inventoryObserver = await dittoProvider.dittoManager.inventoryPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("Observer failed with error: \(error)")
                }
            }, receiveValue: { observerResult in
                self.itemModels = observerResult.results
                observerResult.signalNext()
            })
    }

    func initializeInventory() async throws {
        for item in ItemModel.initialModels {
            try await dittoProvider.insertInitialModel(model: item)
        }
    }

    func resetInventory() async throws {
        try await dittoProvider.dittoManager.deleteAllDocuments()
        for item in ItemModel.initialModels {
            try await dittoProvider.insertInitialModel(model: item)
        }
    }

    func incrementCount(listItem: ItemModel, rowCount: Int) async throws {
        let increment = Double(rowCount) - listItem.stock
        print("DEBUG: Incrementing \(listItem.title) - UI stock: \(rowCount), DB stock: \(listItem.stock), increment: \(increment)")
        try await dittoProvider.incrementCount(modelID: listItem.id, increment: increment)
    }

    deinit {
        inventoryObserver?.cancel()
        inventoryObserver = nil
    }
}
