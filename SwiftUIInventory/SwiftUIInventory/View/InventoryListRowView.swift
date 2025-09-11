//
//  InventoryListRowView.swift
//  SwiftUIInventory
//
//  Created by Alexander on 2025-09-09.
//

import SwiftUI

@Observable final class InventoryListItemRowViewModel: Identifiable, Hashable, Equatable {
    var id: String {
        item.id.id
    }
    private(set) var item: ItemModel
    var stock: Int

    init(item: ItemModel) {
        self.item = item
        self.stock = Int(item.stock)
    }

    func updateItem(_ item: ItemModel) {
        self.item = item
//        self.stock = Int(item.stock)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
//        hasher.combine(item)
//        hasher.combine(stock)
    }

    public static func == (lhs: InventoryListItemRowViewModel, rhs: InventoryListItemRowViewModel) -> Bool {
        lhs.id == rhs.id
//        lhs.item == rhs.item &&
//        lhs.stock == rhs.stock
    }
}

struct InventoryListRowView: View {
    var viewModel: InventoryListItemRowViewModel
    @State private var count = 0

    var countDidChange: (Int) -> Void

    var body: some View {
        HStack {
            Image(viewModel.item.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 100)
            VStack(alignment: .leading) {
                Text(viewModel.item.title)
                    .font(.title)
                    .fontWeight(.bold)
                Text(viewModel.item.detail)
                    .font(.body)
                    .fontWeight(.light)
                let localCurrencyCode = Locale.current.currency?.identifier ?? "USD"
                Text(viewModel.item.price, format: .currency(code: localCurrencyCode))
                    .font(.title)

            }
            VStack {
                Text("Quantity:")
                    .font(.headline)
                CustomStepper(value: $count)
            }
        }
        .task {
            count = Int(viewModel.item.stock)
        }
        .onChange(of: count) { _, newValue in
            countDidChange(newValue)
        }
    }
}

#Preview {
    InventoryListRowView(
        viewModel: InventoryListItemRowViewModel(
            item: ItemModel(
                id: "0",
                imageName: "coke",
                title: "Coca-Cola",
                price: 2.50,
                detail: "A can of Coca-Cola",
                stock: 3
            )
        )
    ) { _ in }
}
