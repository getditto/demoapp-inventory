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

        textView.text = "Ditto SDK Version: \(Ditto.version)"

    }
}
