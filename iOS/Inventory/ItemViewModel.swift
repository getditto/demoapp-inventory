//
//  ItemTableViewCell.swift
//  Inventory
//
//  Created by Ditto on 6/27/18.
//  Copyright © 2018 Ditto. All rights reserved.
//

import UIKit
import Cartography

final class ItemViewModel: Identifiable {

    let itemId: Int
    let image: UIImage?
    let title: String
    let price: Double
    let detail: String
    var count: Int = 0

    init(itemId: Int, image: UIImage?, title: String, price: Double, detail: String) {
        self.itemId = itemId;
        self.image = image
        self.title = title
        self.price = price
        self.detail = detail
    }
}
