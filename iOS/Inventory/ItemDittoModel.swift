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

struct ItemDittoModel {

    // MARK: - Collection Name

    static let collectionName = "inventories"

    // MARK: - Properties

    let _id: Int
    let counter: Double

    // MARK: - Initialization

    init(_ doc: [String: Any?]) {
        self._id = doc["_id"] as! Int
        if doc["counter"] != nil {
            if let firstUnwrap = doc["counter"]
                ,let secondWrap = firstUnwrap
               ,let doubleValue = secondWrap as? Double {
                self.counter = doubleValue
            }
            else {
                self.counter = 0.0
            }
        } else {
            // Handle nil case
            self.counter = 0.0
        }
    }

}
