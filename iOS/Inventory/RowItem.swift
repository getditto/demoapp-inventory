//
//  RowItem.swift
//  Inventory
//
//  Created by Erik Everson on 9/6/24.
//  Copyright © 2024 Ditto. All rights reserved.
//

import Foundation
import SwiftUI
import DittoSwift

struct RowItem: View {
    @ObservedObject var dittoManager: DittoManager
    var item: ItemDittoModel
    @State private var shouldAnimate = false
    @State private var backgroundColor = Color.white
    var count: Double

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(backgroundColor)
                .cornerRadius(10)
                .onChange(of: count) { _ in
                    animateBackground()
                }
                .animation(.easeInOut(duration: 0.25), value: backgroundColor) // Animation on value change

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

                VStack(alignment: .center) {
                    Text("Quantity")
                        .fontWeight(.ultraLight)
                    HStack {
                        Text("\(Int(count))")
                            .font(.title3)
                            .bold()
                            .padding(.bottom, 10)
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

    /// Animates the background color with a delay
    func animateBackground() {
        // First animation
        withAnimation(.easeInOut(duration: 0.25)) {
            self.backgroundColor = Color(Constants.Colors.lightHighlightColor)
        }

        // Delay the second animation to cancel out first
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
