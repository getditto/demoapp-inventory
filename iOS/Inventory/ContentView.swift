//
//  ContentView.swift
//  Inventory
//
//  Created by Erik Everson on 9/3/24.
//  Copyright © 2024 Ditto. All rights reserved.
//

import SwiftUI
import DittoAllToolsMenu
import DittoSwift

struct ContentView: View {
    @ObservedObject var dittoManager = DittoManager.shared

    // Items to initially populate data. These will not be used after data has been populated.
    private var viewItems: [ItemDittoModel] {
        return [
            ItemDittoModel(_id: "coke", counter: DittoCounter(), itemId: 0, imageName: "coke", title: "Coca-Cola", price: 2.50, detail: "A Can of Coca-Cola"),
            ItemDittoModel(_id: "drpepper", counter: DittoCounter(), itemId: 1, imageName: "drpepper", title: "Dr. Pepper", price: 2.50, detail: "A Can of Dr. Pepper"),
            ItemDittoModel(_id: "lays", counter: DittoCounter(), itemId: 2, imageName: "lays", title: "Lay's Classic", price: 3.99, detail: "Original Classic Lay's Bag of Chips"),
            ItemDittoModel(_id: "brownies", counter: DittoCounter(), itemId: 3, imageName: "brownies", title: "Brownies", price: 6.50, detail: "Brownies, Diet Sugar Free Version"),
            ItemDittoModel(_id: "blt", counter: DittoCounter(), itemId: 4, imageName: "blt", title: "Classic BLT Egg", price: 2.50, detail: "Contains Egg, Meats and Dairy")
        ]
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(dittoManager.items) { item in
                    RowItem(dittoManager: dittoManager, item: item, count: item.counter.value)
                }
            }
#if os(tvOS)
            .listStyle(.grouped)
#else
            .listStyle(.insetGrouped)
#endif
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        AllToolsMenu(ditto: DittoManager.shared.ditto)
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .onAppear {
                dittoManager.prepopulateItemsIfAbsent(items: viewItems)
                dittoManager.subscribeAllInventoryItems()
            }
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    ContentView()
}
