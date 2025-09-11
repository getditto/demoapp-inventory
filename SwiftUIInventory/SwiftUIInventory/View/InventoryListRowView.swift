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
                    CustomStepper(value: $count)
                }
            }
        }
        .task {
            count = Int(model.stock)
        }
        .onChange(of: count) { _, newValue in
            countDidChange(newValue)
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
