//
//  ErrorRouter.swift
//  SwiftUIInventory
//
//  Created by Alexander on 2025-09-09.
//

import SwiftUI

@Observable final class ErrorRouter {
    var error: AppError? {
        didSet {
            print("Error occurred: \(error)")
        }
    }
    var presentError = false

    func setError(_ error: AppError) {
        self.error = error
        presentError = true
    }

    func clearError() {
        self.error = nil
        presentError = false
    }
}
