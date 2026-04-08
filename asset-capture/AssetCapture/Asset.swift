import Foundation
import UIKit

struct Asset: Codable {
    let id: String
    var nsn: String
    var condition: String
    var notes: String
    var createdAt: String
    var deviceId: String
    var photoJpegBase64: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case nsn, condition, notes, createdAt, deviceId, photoJpegBase64
    }

    var photo: UIImage? {
        guard let b64 = photoJpegBase64,
              let data = Data(base64Encoded: b64) else { return nil }
        return UIImage(data: data)
    }

    var conditionEnum: Constants.Condition {
        Constants.Condition(rawValue: condition) ?? .usable
    }

    var formattedDate: String {
        let iso = ISO8601DateFormatter()
        guard let date = iso.date(from: createdAt) else { return createdAt }
        let display = DateFormatter()
        display.dateStyle = .short
        display.timeStyle = .short
        return display.string(from: date)
    }
}

extension UIImage {
    func resizedTo(maxDimension: CGFloat) -> UIImage {
        let scale = maxDimension / max(size.width, size.height)
        if scale >= 1 { return self }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
