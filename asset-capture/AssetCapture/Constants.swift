import UIKit

struct Constants {

    struct Colors {
        static let accent       = UIColor(red: 0/255,   green: 122/255, blue: 255/255, alpha: 1)
        static let usable       = UIColor(red: 52/255,  green: 199/255, blue: 89/255,  alpha: 1)
        static let repairable   = UIColor(red: 255/255, green: 149/255, blue: 0/255,   alpha: 1)
        static let scrap        = UIColor(red: 255/255, green: 59/255,  blue: 48/255,  alpha: 1)
    }

    enum Condition: String, CaseIterable {
        case usable     = "Usable"
        case repairable = "Repairable"
        case scrap      = "Scrap"

        var color: UIColor {
            switch self {
            case .usable:     return Colors.usable
            case .repairable: return Colors.repairable
            case .scrap:      return Colors.scrap
            }
        }
    }
}
