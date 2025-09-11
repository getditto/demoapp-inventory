//
//  ContentView.swift
//  SwiftUIInventory
//
//  Created by Alexander on 2025-09-08.
//

import Combine
import SwiftUI
import DittoAllToolsMenu
import DittoSwift

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
    
    func resetInventory() async throws {
        try await dittoProvider.dittoManager.deleteAllDocuments()
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
    @State private var navigationPath = NavigationPath()
    @State private var dittoInstance: Ditto?

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
            .navigationDestination(for: NavigationDestination.self, destination: { destination in
                switch destination {
                case .tools:
                    if let dittoInstance {
                        AllToolsMenu(ditto: dittoInstance)
                    } else {
                        ProgressView("Loading...")
                    }
                }
            })
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            // Sync action
                            print("Sync tapped")
                        }) {
                            Label("Sync", systemImage: "arrow.clockwise")
                        }
                        
                        Button(action: {
                            Task {
                                do {
                                    try await viewModel.dittoProvider.dittoManager.deleteAllDocuments()
                                } catch {
                                    errorRouter.setError(AppError.message(error.localizedDescription))
                                }
                            }
                        }) {
                            Label("Delete All Data", systemImage: "trash")
                        }
                        
                        Button(action: {
                            Task {
                                do {
                                    try await viewModel.resetInventory()
                                } catch {
                                    errorRouter.setError(AppError.message(error.localizedDescription))
                                }
                            }
                        }) {
                            Label("Reset to Default", systemImage: "arrow.triangle.2.circlepath")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            Task {
                                dittoInstance = await viewModel.dittoProvider.ditto
                                navigationPath.append(NavigationDestination.tools)
                            }
                        }) {
                            Label("Ditto Tools", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .task {
            do {
                dittoInstance = await viewModel.dittoProvider.ditto
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
