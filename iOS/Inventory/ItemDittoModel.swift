//
//  InventoryItem.swift
//  Inventory
//
//  Created by Shunsuke Kondo on 2023/01/19.
//  Copyright © 2023 Ditto. All rights reserved.
//

import Foundation
import DittoSwift

/*
    This is a model to store in Ditto database.
    We don't store as `ItemViewModel` because some of the data don't need to be transmitted.
    For this case, Ditto only syncs its ID and counter.
    Separating models for Ditto and views could make sync performance better.
 */

struct ItemDittoModel: Identifiable {
    var id: String { _id }

    // MARK: - Collection Name

    static let collectionName = "inventories"

    // MARK: - Properties

    let _id: String
    let counter: DittoCounter
    let itemId: Int
    let imageName: String
    let title: String
    let price: Double
    let detail: String
}

extension ItemDittoModel {
    // MARK: - Initialization from Ditto object

    init(_ doc: DittoDocument) {
        self._id = doc["_id"].stringValue
        self.counter = doc["counter"].counter ?? DittoCounter()
        self.itemId = doc["itemId"].intValue
        self.imageName = doc["imageName"].stringValue
        self.title = doc["title"].stringValue
        self.price = doc["price"].doubleValue
        self.detail = doc["detail"].stringValue
    }

    func document() -> [String: Any?] {
        return [
            "_id": _id,
            "counter": counter,
            "itemId": itemId,
            "imageName": imageName,
            "title": title,
            "price": price,
            "detail": detail,
        ]
    }
}
