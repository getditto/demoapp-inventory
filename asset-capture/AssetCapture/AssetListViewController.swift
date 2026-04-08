import UIKit
import Combine

final class AssetListViewController: UIViewController {

    private let tableView = UITableView()
    private let dittoManager = AssetDittoManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupTableView()
        observeAssets()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }

    // MARK: - Setup

    private func setupNavBar() {
        title = "Asset Capture"

        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(pushToInfoPage), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: infoButton)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addAsset)
        )
    }

    private func setupTableView() {
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
        tableView.register(AssetListCell.self, forCellReuseIdentifier: AssetListCell.reuseID)
        tableView.rowHeight = AssetListCell.height

        let emptyLabel = UILabel()
        emptyLabel.text = "No assets captured yet.\nTap + to add one."
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.font = UIFont.systemFont(ofSize: 17)
        tableView.backgroundView = emptyLabel
    }

    // MARK: - Ditto

    private func observeAssets() {
        dittoManager.subscribeAssets()
        dittoManager.assetsUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.tableView.backgroundView?.isHidden = !self.dittoManager.assets.isEmpty
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func addAsset() {
        let nav = UINavigationController(rootViewController: NewAssetViewController())
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    @objc private func pushToInfoPage() {
        navigationController?.pushViewController(dittoManager.dittoInfoView, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension AssetListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dittoManager.assets.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AssetListCell.reuseID, for: indexPath) as! AssetListCell
        cell.configure(asset: dittoManager.assets[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AssetListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        AssetListCell.height
    }
}
