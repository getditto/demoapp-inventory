//
//  ContentView.swift
//  Inventory
//
//  Created by Erik Everson on 9/3/24.
//  Copyright © 2024 Ditto. All rights reserved.
//

import SwiftUI
import DittoAllToolsMenu

struct ContentView: View {
    @ObservedObject var dittoManager = DittoManager.shared
    private var viewItems: [ItemViewModel] {
        return [
            ItemViewModel(itemId: 0, image: UIImage(named: "coke"), title: "Coca-Cola", price: 2.50, detail: "A Can of Coca-Cola"),
            ItemViewModel(itemId: 1, image: UIImage(named: "drpepper"), title: "Dr. Pepper", price: 2.50, detail: "A Can of Dr. Pepper"),
            ItemViewModel(itemId: 2, image: UIImage(named: "lays"), title: "Lay's Classic", price: 3.99, detail: "Original Classic Lay's Bag of Chips"),
            ItemViewModel(itemId: 3, image: UIImage(named: "brownies"), title: "Brownies", price: 6.50, detail: "Brownies, Diet Sugar Free Version"),
            ItemViewModel(itemId: 4, image: UIImage(named: "blt"), title: "Classic BLT Egg", price: 2.50, detail: "Contains Egg, Meats and Dairy")
        ]
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(viewItems) { item in
                    HStack(alignment: .top) {
                        if let image = item.image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(5)
                                .padding(5)
#if os(tvOS)
                                .frame(maxWidth: 225, maxHeight: 225)
#else
                                .frame(maxWidth: 100, maxHeight: 100)
#endif

                        } else {
                            Image(.inventoryLaunch)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(5)
                                .padding(5)
                                .frame(maxWidth: 100, maxHeight: 100)
                        }

                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.title3)
                                .bold()
                            Text(item.detail)
                                .fontWeight(.ultraLight)
                                .font(.footnote)
                            Text(String(format: "$%.02f", item.price))
                        }
                        .padding(5)

                        Spacer()

                        VStack(alignment: .center) {
                            Text("Quantity")
                                .fontWeight(.ultraLight)
                            if dittoManager.models.items.isEmpty {
                                Text("0")
                                    .font(.title3)
                                    .bold()
                                    .padding(.bottom, 10)
                            } else {
                                Text("\(Int(dittoManager.models.items[item.itemId].counter.value))")
                                    .font(.title3)
                                    .bold()
                                    .padding(.bottom, 10)
                            }

                            HStack {
                                Button {
                                    dittoManager.decrementCounterFor(id: item.itemId)
#if !os(tvOS)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
#endif
                                } label: {
                                    Text("-")
                                        .bold()
                                }
                                .buttonStyle(.borderedProminent)

                                Button {
                                    dittoManager.incrementCounterFor(id: item.itemId)
#if !os(tvOS)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
#endif
                                } label: {
                                    Text("+")
                                        .bold()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding(5)
                    }
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
                dittoManager.prepopulateItemsIfAbsent(itemIds: viewItems.indexes)
                dittoManager.subscribeAllInventoryItems()
            }
        }
        .navigationViewStyle(.stack)
    }

//    func animateBackground() {
//        UIView.animate(withDuration: 0.25, delay: 0, options: [.allowUserInteraction, .transitionCrossDissolve], animations: {
//            self.backgroundColor = Constants.Colors.lightHighlightColor
//        }, completion: nil)
//        UIView.animate(withDuration: 0.25, delay: 0.25, options: [.allowUserInteraction, .transitionCrossDissolve], animations: {
//            self.backgroundColor = .white
//        }, completion: nil)
//    }
}

#Preview {
    ContentView()
}
