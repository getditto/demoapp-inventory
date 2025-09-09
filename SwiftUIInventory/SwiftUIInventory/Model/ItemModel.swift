//
//  Items.swift
//  SwiftUIInventory
//
//  Created by Alexander on 2025-09-09.
//

import Foundation

struct ItemCompositeKey: Codable {
    let id: String
    let title: String
    let price: Double
}

struct ItemModel: Codable {
    let id: ItemCompositeKey
    let imageName: String
    let title: String
    let price: Double
    let detail: String
    var count: Double

    init(id: String, imageName: String, title: String, price: Double, detail: String, count: Double = 0.0) {
        self.id = ItemCompositeKey(id: id, title: title, price: price)
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
}
