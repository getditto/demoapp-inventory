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
    @State private var startAnimation: Bool = false

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

struct RowItem: View {
    @ObservedObject var dittoManager: DittoManager
    var item: ItemDittoModel
    @State private var shouldAnimate = false
    @State private var backgroundColor = Color.white
    var count: Double

    var body: some View {
        HStack(alignment: .top) {
            Image(item.imageName, bundle: .main)
                .resizable()
                .scaledToFit()
                .cornerRadius(5)
                .padding(5)
#if os(tvOS)
                .frame(maxWidth: 225, maxHeight: 225)
#else
                .frame(maxWidth: 100, maxHeight: 100)
#endif

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

            ZStack {
                Rectangle()
                    .foregroundColor(backgroundColor)
                    .frame(width: 200, height: 200)
                    .onAppear {
                        animateBackground()
                    }
                    .animation(.easeInOut(duration: 0.25), value: backgroundColor) // Animation on value change

                VStack(alignment: .center) {
                    Text("Quantity")
                        .fontWeight(.ultraLight)
                    HStack {
                        if dittoManager.items.isEmpty {
                            Text("0")
                                .font(.title3)
                                .bold()
                                .padding(.bottom, 10)
                        } else {
                            Text("\(Int(count))")
                                .font(.title3)
                                .bold()
                                .padding(.bottom, 10)
                        }
                    }

                    HStack {
                        Button {
                            dittoManager.decrementCounterFor(id: item._id)
#if !os(tvOS)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
#endif
                        } label: {
                            Text("-")
                                .bold()
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            dittoManager.incrementCounterFor(id: item._id)
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
        .onAppear {
            self.shouldAnimate = true
        }
    }

    // Function that animates the background color with a delay
    func animateBackground() {
        // First animation
        withAnimation(.easeInOut(duration: 0.25)) {
            self.backgroundColor = Color(Constants.Colors.lightHighlightColor)
        }

        // Delay the second animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeInOut(duration: 0.25)) {
                self.backgroundColor = Color.white
            }
        }
    }
}

#Preview {
    let item = ItemDittoModel(_id: UUID().uuidString, counter: DittoCounter(), itemId: 0, imageName: "coke", title: "Coca-Cola", price: 2.50, detail: "A Can of Coca-Cola")
    RowItem(
        dittoManager: DittoManager.shared,
        item: item,
        count: item.counter.value
    )
}
