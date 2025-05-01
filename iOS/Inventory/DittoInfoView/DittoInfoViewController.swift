//
//  DittoInfoViewController.swift
//  ToDo
//
//  Created by kndoshn on 2020/07/02.
//  Copyright © 2020 DittoLive Incorporated. All rights reserved.
//

import UIKit
import DittoSwift
import DittoAllToolsMenu
import SwiftUI

public struct DittoInfoViewFactory {
    private init() {}
    static func create(ditto: Ditto, bundle: Bundle = Bundle.main) -> DittoInfoViewController {
        let vc = DittoInfoViewController.instantiate()
        vc.ditto = ditto
        vc.bundle = bundle
        return vc
    }
}

fileprivate enum CellInfo: String, CaseIterable {
    case dittoTools = "Ditto Tools"
    case sdkInfo = "Ditto SDK Info"

    var index: Int {
        return CellInfo.allCases.firstIndex(of: self)!
    }

    var accessoryType: UITableViewCell.AccessoryType {
        switch self {
        case .dittoTools, .sdkInfo:
            return .disclosureIndicator
        }
    }
}

final class DittoInfoViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    fileprivate var ditto: Ditto!
    fileprivate var bundle: Bundle!

    fileprivate static func instantiate() -> Self {
        let sb = UIStoryboard(name: String(describing: "DittoInfoView"), bundle: Bundle(for: DittoInfoViewController.self))
        let vc = sb.instantiateViewController(withIdentifier: String(describing: self))
        return vc as! Self

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
            self.navigationItem.largeTitleDisplayMode = .never
            self.navigationController?.navigationBar.prefersLargeTitles = false
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
        }
    }
}

extension DittoInfoViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CellInfo.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dittoInfoCell", for: indexPath)
        let info = toInfo(indexPath)
        cell.textLabel?.text = info.rawValue
        cell.accessoryType = info.accessoryType

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let info = toInfo(indexPath)
        switch info {
        case .dittoTools:
            let vc = UIHostingController(rootView: AllToolsMenu(ditto: ditto))
            navigationController?.pushViewController(vc, animated: true)
        case .sdkInfo:
            let storyboard = UIStoryboard(name: "DittoInfoView", bundle: Bundle(for: DittoInfoViewController.self))
            let destination = storyboard.instantiateViewController(withIdentifier: "DittoSDKInfoViewController") as! DittoSDKInfoViewController
            destination.ditto = ditto
            navigationController?.pushViewController(destination, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UILabel()
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        footer.text = "App Version: \(version)(\(build))"
        footer.textAlignment = .center
        footer.textColor = .darkGray
        return footer
    }

    private func toInfo(_ indexPath: IndexPath) -> CellInfo {
        return CellInfo.allCases[indexPath.row]
    }
}
