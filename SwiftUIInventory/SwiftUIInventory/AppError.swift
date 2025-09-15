//
//  AppError.swift
//  SwiftUIInventory
//
//  Created by Alexander on 2025-09-09.
//

import Foundation

enum AppError: LocalizedError {
    case message(String)

    var localizedDescription: String {
        switch self {
        case .message(let message):
            return message
        }
    }

    var errorDescription: String? {
        localizedDescription
    }

    var debugDescription: String {
        localizedDescription
    }
}
