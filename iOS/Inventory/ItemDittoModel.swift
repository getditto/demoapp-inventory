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
    
}

extension ItemDittoModel {
    /// Convenience initializer returns instance from `QueryResultItem.value`
    init(_ value: [String: Any?]) {
        self._id = value["_id"] as! Int
        if (value["counter"] != nil){
            self.counter = value["counter"] as! Double
        } else {
            self.counter = 0.0
        }
    }
}

extension ItemDittoModel: Identifiable {
    /// Required for SwiftUI List view
    var id: Int {
        return _id
    }
}

// MARK: - Codable
extension ItemDittoModel: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(Int.self, forKey: ._id)
        counter = try container.decodeIfPresent(Double.self, forKey: .counter) ?? 0.0
    }
    
    private enum CodingKeys: String, CodingKey {
        case _id
        case counter
    }
}


