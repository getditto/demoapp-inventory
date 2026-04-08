import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let navController = UINavigationController(rootViewController: AssetListViewController())
        navController.navigationBar.prefersLargeTitles = true
        window?.tintColor = Constants.Colors.accent
        window!.rootViewController = navController
        window!.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        BackgroundSync.shared.start()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        BackgroundSync.shared.stop()
    }
}
