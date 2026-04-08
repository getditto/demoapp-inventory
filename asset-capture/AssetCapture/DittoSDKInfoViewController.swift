import UIKit
import DittoSwift

final class DittoSDKInfoViewController: UIViewController {

    private let textView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        tv.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        return tv
    }()

    private var ditto: Ditto!

    static func create(ditto: Ditto) -> DittoSDKInfoViewController {
        let vc = DittoSDKInfoViewController()
        vc.ditto = ditto
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        let sdkVersion = ditto.sdkVersion
        let platform   = String(sdkVersion.prefix(4))
        let rest       = sdkVersion.dropFirst(4).split(separator: "_")
        let semVer     = rest.count > 0 ? String(rest[0]) : "?"
        let commitHash = rest.count > 1 ? String(rest[1]) : "?"

        textView.text = """
        Platform:     \(platform)
        SDK Version:  \(semVer)
        Commit Hash:  \(commitHash)
        """
    }
}
