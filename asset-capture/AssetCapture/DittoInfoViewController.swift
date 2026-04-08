import UIKit
import DittoSwift
import DittoAllToolsMenu
import SwiftUI

final class DittoInfoViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var ditto: Ditto!

    private enum Row: String, CaseIterable {
        case dittoTools = "Ditto Tools"
        case sdkInfo    = "Ditto SDK Info"
    }

    static func create(ditto: Ditto) -> DittoInfoViewController {
        let vc = DittoInfoViewController()
        vc.ditto = ditto
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ditto Info"
        view.backgroundColor = .systemGroupedBackground

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
    }
}

extension DittoInfoViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Row.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = Row.allCases[indexPath.row].rawValue
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Row.allCases[indexPath.row] {
        case .dittoTools:
            let vc = UIHostingController(rootView: AllToolsMenu(ditto: ditto))
            navigationController?.pushViewController(vc, animated: true)
        case .sdkInfo:
            navigationController?.pushViewController(DittoSDKInfoViewController.create(ditto: ditto), animated: true)
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let label = UILabel()
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build   = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        label.text = "App Version: \(version) (\(build))"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = UIFont.systemFont(ofSize: 13)
        return label
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 60 }
}
