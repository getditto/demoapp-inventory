//
//  NavigationDestinations.swift
//  SwiftUIInventory
//
//  Created by Alexander on 2025-09-10.
//

import Foundation
import DittoSwift

enum NavigationDestination: Hashable {
    case tools(Ditto)
}

extension Ditto: @retroactive Equatable, @retroactive Hashable {
    public static func == (lhs: Ditto, rhs: Ditto) -> Bool {
        return lhs.appID == rhs.appID
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(appID)
    }
}
