//
//  SwiftUIInventoryApp.swift
//  SwiftUIInventory
//
//  Created by Alexander on 2025-09-08.
//

import SwiftUI

@main
struct SwiftUIInventoryApp: App {
    @State private var listViewModel: InventoryListViewModel?
    @State private var dittoProvider: DittoProvider?
    @State private var errorRouter = ErrorRouter()

    var body: some Scene {
        WindowGroup {
            Group {
                if let listViewModel {
                    InventoryListView(viewModel: listViewModel)
                        .alert(isPresented: $errorRouter.presentError, error: errorRouter.error, actions: {
                            Button {
                                errorRouter.clearError()
                            } label: {
                                Text("OK")
                            }
                        })
                        .environment(errorRouter)
                } else {
                    Image("inventory_launch")
                }
            }
            .task {
                do {
                    let dittoProvider = try await DittoProvider()
                    self.dittoProvider = dittoProvider
                    self.listViewModel = InventoryListViewModel(dittoProvider: dittoProvider)
                } catch let error as AppError {
                    errorRouter.setError(error)
                } catch {
                    errorRouter.setError(AppError.message(error.localizedDescription))
                }
            }
        }
    }
}
