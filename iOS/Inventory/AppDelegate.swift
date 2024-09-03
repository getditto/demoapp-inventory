//
//  AppDelegate.swift
//  Inventory
//
//  Created by Ditto on 6/27/18.
//  Copyright © 2018 Ditto. All rights reserved.
//

import UIKit
import SwiftUI

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.tintColor = Constants.Colors.mainColor
        window!.rootViewController = UIHostingController(rootView: ContentView())
        window!.makeKeyAndVisible()
        return true
    }
}
