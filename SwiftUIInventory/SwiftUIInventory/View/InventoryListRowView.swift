//
//  InventoryListRowView.swift
//  SwiftUIInventory
//
//  Created by Alexander on 2025-09-09.
//

import SwiftUI

struct InventoryListRowView: View {
    var model: ItemModel
    @State private var count = 0
    @State private var flashAnimation = false
    @State private var animationDirection: CustomStepper.AnimationDirection = .none

    var countDidChange: (Int) -> Void

    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                Image(model.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipped()
                VStack(alignment: .leading) {
                    Text(model.title)
                        .font(.system(size: 25, weight: .bold))
                    Text(model.detail)
                        .font(.system(size: 18, weight: .light))
                    let localCurrencyCode = Locale.current.currency?.identifier ?? "USD"
                    Text(model.price, format: .currency(code: localCurrencyCode))
                        .font(.system(size: 18))
                }
                Spacer()
                VStack {
                    Text("Quantity:")
                        .font(.system(size: 18, weight: .light))
                    CustomStepper(value: $count, externalDirection: animationDirection)
                }
            }
        }
        .background(flashAnimation ? Color.gray.opacity(0.3) : Color.clear)
        .animation(.easeInOut(duration: 0.3), value: flashAnimation)
        .task {
            count = Int(model.stock)
        }
        .onChange(of: model.stock, { oldValue, newValue in
            animationDirection = oldValue < newValue ? .up : .down
            count = Int(newValue)
            flashAnimation = true
            toggleFlashOff()
        })
        .onChange(of: count) { _, newValue in
            guard count != Int(model.stock) else { return }
            countDidChange(newValue)
        }
    }

    private func toggleFlashOff() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            flashAnimation = false
        }
    }
}

#Preview {
    InventoryListRowView(
        model: ItemModel(
                id: "0",
                imageName: "coke",
                title: "Coca-Cola",
                price: 2.50,
                detail: "A can of Coca-Cola",
                stock: 3
            )
    ) { _ in }
}
