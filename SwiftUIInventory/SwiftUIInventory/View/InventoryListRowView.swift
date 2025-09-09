//
//  InventoryListRowView.swift
//  SwiftUIInventory
//
//  Created by Alexander on 2025-09-09.
//

import SwiftUI

struct InventoryListRowView: View {
    let item: ItemModel
    @State private var count = 0

    var body: some View {
        HStack {
            Image("coke")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 100)
            VStack(alignment: .leading) {
                HStack {
                    Text(item.title)
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()

                }
                Text(item.detail)
                    .font(.body)
                    .fontWeight(.light)
                let localCurrencyCode = Locale.current.currency?.identifier ?? "USD"
                Text(item.price, format: .currency(code: localCurrencyCode))
                    .font(.title)

            }
            VStack {
                Text("Quantity:")
                    .font(.headline)
                CustomStepper(value: $count)
            }
        }
        .onAppear {
            count = Int(item.count)
        }
    }
}

#Preview {
    InventoryListRowView(
        item: ItemModel(
            id: UUID().uuidString,
            imageName: "coke",
            title: "Coca-Cola",
            price: 2.50,
            detail: "A can of Coca-Cola",
            count: 3
        )
    )
}
