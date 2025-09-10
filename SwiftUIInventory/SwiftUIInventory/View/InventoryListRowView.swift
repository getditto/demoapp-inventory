//
//  InventoryListRowView.swift
//  SwiftUIInventory
//
//  Created by Alexander on 2025-09-09.
//

import SwiftUI

@Observable final class InventoryListItemRowViewModel: Identifiable, Hashable, Equatable {
    let id: UUID
    private(set) var item: ItemModel
    var count: Int

    init(item: ItemModel) {
        self.id = UUID()
        self.item = item
        self.count = Int(item.count)
    }

    func updateItem(_ item: ItemModel) {
        self.item = item
        self.count = Int(item.count)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(item)
    }

    public static func == (lhs: InventoryListItemRowViewModel, rhs: InventoryListItemRowViewModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.item == rhs.item
    }
}

struct InventoryListRowView: View {
    @Bindable var viewModel: InventoryListItemRowViewModel

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
                CustomStepper(value: $viewModel.count)
            }
        }
    }
}

#Preview {
    InventoryListRowView(
        viewModel: InventoryListItemRowViewModel(
            item: ItemModel(
                id: UUID().uuidString,
                imageName: "coke",
                title: "Coca-Cola",
                price: 2.50,
                detail: "A can of Coca-Cola",
                count: 3
            )
        )
    )
}
