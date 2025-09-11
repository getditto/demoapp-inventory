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
            }, receiveValue: { itemModels in
                self.itemModels = itemModels
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

struct InventoryListView: View {
    @Environment(ErrorRouter.self) private var errorRouter
    @Bindable var viewModel: InventoryListViewModel
    @State private var navigationPath = NavigationPath()
    @State private var dittoInstance: Ditto?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                if !viewModel.itemModels.isEmpty {
                    // List for some reason interferes with touch interaction.. using scrollview instead
                    ScrollView {
                        LazyVStack {
                            ForEach(viewModel.itemModels) { model in
                                VStack {
                                    InventoryListRowView(model: model) { count in
                                        Task {
                                            do {
                                                try await viewModel.incrementCount(listItem: model, rowCount: count)
                                            } catch {
                                                errorRouter.setError(AppError.message(error.localizedDescription))
                                            }
                                        }
                                    }
                                    if let lastItem = viewModel.itemModels.last, model != lastItem {
                                        Divider()
                                    }
                                }
                                .padding(.horizontal, 6)
                            }
                        }
                    }
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
