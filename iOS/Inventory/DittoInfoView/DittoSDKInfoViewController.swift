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

        let sdkVersion = Ditto.version
        let platform = sdkVersion.prefix(4)
        let versions = sdkVersion.dropFirst(4).split(separator: "_")
        let semVer = String(versions[0])
        let commitHash = String(versions[1])

        textView.text = """
        Platform: \(platform)
        SDK Version: \(semVer)
        Commit Hash: \(commitHash)
        """

    }
}
