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

    init(item: ItemModel) {
        self.item = item
    }

    func updateItem(_ item: ItemModel) {
        self.item = item
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: InventoryListItemRowViewModel, rhs: InventoryListItemRowViewModel) -> Bool {
        lhs.id == rhs.id
    }
}

struct InventoryListRowView: View {
//    var viewModel: InventoryListItemRowViewModel
    var viewModel: ItemModel
    @State private var count = 0

    var countDidChange: (Int) -> Void

    var body: some View {
        HStack {
            Image(viewModel.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 100)
            VStack(alignment: .leading) {
                Text(viewModel.title)
                    .font(.title)
                    .fontWeight(.bold)
                Text(viewModel.detail)
                    .font(.body)
                    .fontWeight(.light)
                let localCurrencyCode = Locale.current.currency?.identifier ?? "USD"
                Text(viewModel.price, format: .currency(code: localCurrencyCode))
                    .font(.title)
            }
            VStack {
                Text("Quantity:")
                    .font(.headline)
                CustomStepper(value: $count)
            }
        }
        .task {
            count = Int(viewModel.stock)
        }
        .onChange(of: count) { _, newValue in
            countDidChange(newValue)
        }
    }
}

#Preview {
    InventoryListRowView(
//        viewModel: InventoryListItemRowViewModel(
        viewModel: ItemModel(
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
