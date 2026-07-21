//
//  DittoSDKInfoViewController.swift
//  ToDo
//
//  Created by kndoshn on 2020/07/02.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import UIKit
import DittoSwift

final class DittoSDKInfoViewController: UIViewController {
    @IBOutlet private weak var textView: UITextView!
    var ditto: Ditto!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Ditto.version is the SDK semantic version (e.g. "5.0.2"); it no longer
        // embeds a platform prefix or commit hash.
        let sdkVersion = Ditto.version
        let parts = sdkVersion.split(separator: "_")
        let semVer = parts.first.map(String.init) ?? sdkVersion
        let commitHash = parts.count > 1 ? String(parts[1]) : "n/a"

        textView.text = """
        Platform: iOS
        SDK Version: \(semVer)
        Commit Hash: \(commitHash)
        """

    }
}
