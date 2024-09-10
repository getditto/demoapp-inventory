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
    We store all of the data into Ditto even though the only data that will change is the counter.
    For this case, Ditto could also only sync its ID and counter.
    Separating models for Ditto and views could make sync performance better.
 */


/// The item model that ditto will be replicated between Ditto Peers.
struct ItemDittoModel: Identifiable {
    // MARK: - Properties
    var id: String { _id }

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
        self._id = doc[_idKey].stringValue
        self.counter = doc[counterKey].counter ?? DittoCounter()
        self.itemId = doc[itemIdKey].intValue
        self.imageName = doc[imageNameKey].stringValue
        self.title = doc[titleKey].stringValue
        self.price = doc[priceKey].doubleValue
        self.detail = doc[detailKey].stringValue
    }

    func document() -> [String: Any?] {
        return [
            _idKey: _id,
            counterKey: counter,
            itemIdKey: itemId,
            imageNameKey: imageName,
            titleKey: title,
            priceKey: price,
            detailKey: detail,
        ]
    }
}
