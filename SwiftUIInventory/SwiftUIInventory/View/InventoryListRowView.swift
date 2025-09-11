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
        HStack {
            Image(model.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 100)
            VStack(alignment: .leading) {
                Text(model.title)
                    .font(.title)
                    .fontWeight(.bold)
                Text(model.detail)
                    .font(.body)
                    .fontWeight(.light)
                let localCurrencyCode = Locale.current.currency?.identifier ?? "USD"
                Text(model.price, format: .currency(code: localCurrencyCode))
                    .font(.title)
            }
            VStack {
                Text("Quantity:")
                    .font(.headline)
                CustomStepper(value: $count)
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
//        viewModel: InventoryListItemRowViewModel(
        model: ItemModel(
//            item: ItemModel(
                id: "0",
                imageName: "coke",
                title: "Coca-Cola",
                price: 2.50,
                detail: "A can of Coca-Cola",
                stock: 3
            )
//        )
    ) { _ in }
}
