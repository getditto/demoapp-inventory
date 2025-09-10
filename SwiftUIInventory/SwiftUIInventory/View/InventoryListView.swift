//
//  ContentView.swift
//  SwiftUIInventory
//
//  Created by Alexander on 2025-09-08.
//

import Combine
import SwiftUI

@Observable final class InventoryListViewModel {
    let dittoProvider: DittoProvider

    var items: [InventoryListItemRowViewModel] = []

    @ObservationIgnored private(set) var inventoryObserver: AnyCancellable?

    init(dittoProvider: DittoProvider) {
        self.dittoProvider = dittoProvider
    }

    func observeInventories() async {
        self.inventoryObserver = await dittoProvider.dittoManager.inventoryPublisher
            .receive(on: DispatchQueue(label: "inventory-observer"))
            .tryMap { [weak self] items -> [InventoryListItemRowViewModel] in
                guard let self else { throw AppError.message("") }
                var updatedRows: [InventoryListItemRowViewModel] = []
                
                for item in items {
                    if let existingRow = self.items.first(where: { $0.item.id == item.id }) {
                        existingRow.updateItem(item)
                        updatedRows.append(existingRow)
                    } else {
                        let newRow = InventoryListItemRowViewModel(item: item)
                        updatedRows.append(newRow)
                    }
                }

                return updatedRows
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("Observer failed with error: \(error)")
                }
            }, receiveValue: { items in
                self.items = items
            })
    }

    func initializeInventory() async throws {
        for item in ItemModel.initialModels {
            try await dittoProvider.insertInitialModel(model: item)
        }
    }

    deinit {
        inventoryObserver?.cancel()
        inventoryObserver = nil
    }
}

struct InventoryListView: View {
    @Environment(ErrorRouter.self) private var errorRouter
    @Bindable var viewModel: InventoryListViewModel

    var body: some View {
        VStack {
            if !viewModel.items.isEmpty {
                List(viewModel.items) { item in
                    InventoryListRowView(viewModel: item)
                }
                .listStyle(.plain)
            } else {
                Text("No items found")
            }
        }
        .padding()
        .task {
            do {
                await viewModel.dittoProvider.dittoManager.initializeSubscription()
                try await viewModel.dittoProvider.dittoManager.setObserver()
                try await viewModel.dittoProvider.dittoManager.startSync()
                await viewModel.observeInventories()
                try await viewModel.initializeInventory()
            } catch {
                errorRouter.setError(AppError.message(error.localizedDescription))
            }
        }
    }
}
