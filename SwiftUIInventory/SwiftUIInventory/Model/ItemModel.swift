//
//  Items.swift
//  SwiftUIInventory
//
//  Created by Alexander on 2025-09-09.
//

import Foundation

struct ItemCompositeKey: Codable, Hashable {
    let id: String
    let title: String
    let price: String
}

struct ItemModel: Codable, Hashable {
    let id: ItemCompositeKey
    let imageName: String
    let title: String
    let price: Double
    let detail: String
    var count: Double

    init(id: String, imageName: String, title: String, price: Double, detail: String, count: Double = 0.0) {
        self.id = ItemCompositeKey(id: id, title: title, price: String(price))
        self.imageName = imageName
        self.title = title
        self.price = price
        self.detail = detail
        self.count = count
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case imageName
        case title
        case price
        case detail
        case count
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(imageName, forKey: .imageName)
        try container.encode(title, forKey: .title)
        try container.encode(price, forKey: .price)
        try container.encode(detail, forKey: .detail)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(price)
        hasher.combine(count)
    }
}

extension ItemModel {
    static var initialModels: [ItemModel] {
        [
            ItemModel(id: UUID().uuidString, imageName: "coke", title: "Coca-Cola", price: 2.50, detail: "A Can of Coca-Cola"),
            ItemModel(id: UUID().uuidString, imageName: "drpepper", title: "Dr. Pepper", price: 2.50, detail: "A Can of Dr. Pepper"),
            ItemModel(id: UUID().uuidString, imageName: "lays", title: "Lay's Classic", price: 3.99, detail: "Original Classic Lay's Bag of Chips"),
            ItemModel(id: UUID().uuidString, imageName: "brownies", title: "Brownies", price: 6.50, detail: "Brownies, Diet Sugar Free Version"),
            ItemModel(id: UUID().uuidString, imageName: "blt", title: "Classic BLT Egg", price: 2.50, detail: "Contains Egg, Meats and Dairy")
        ]
    }
}
