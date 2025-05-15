//
//  MainViewController.swift
//  Inventory
//
//  Created by Ditto on 6/27/18.
//  Copyright © 2018 Ditto. All rights reserved.
//

import UIKit
import Cartography
import Combine

final class MainViewController: UIViewController {

    // MARK: - Properties

    private let tableView = UITableView()
    private var searchController: UISearchController!

    private let dittoManager = DittoManager.shared
    private var cancellables = Set<AnyCancellable>()

    private var viewItems: [ItemViewModel] {
        return [
            ItemViewModel(itemId: 0, image: UIImage(named: "coke"), title: "Coca-Cola", price: 2.50, detail: "A Can of Coca-Cola"),
            ItemViewModel(itemId: 1, image: UIImage(named: "drpepper"), title: "Dr. Pepper", price: 2.50, detail: "A Can of Dr. Pepper"),
            ItemViewModel(itemId: 2, image: UIImage(named: "lays"), title: "Lay's Classic", price: 3.99, detail: "Original Classic Lay's Bag of Chips"),
            ItemViewModel(itemId: 3, image: UIImage(named: "brownies"), title: "Brownies", price: 6.50, detail: "Brownies, Diet Sugar Free Version"),
            ItemViewModel(itemId: 4, image: UIImage(named: "blt"), title: "Classic BLT Egg", price: 2.50, detail: "Contains Egg, Meats and Dairy")
        ]
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupNavBar()
        populateItems()
        observeItems()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }

    // MARK: - Private Functions

    private func populateItems() {
        dittoManager.prepopulateItemsIfAbsent(itemIds: viewItems.indexes)
    }

    private func observeItems() {

        dittoManager.subscribeAllInventoryItems()

        dittoManager.itemsUpdated
            .sink { [weak self] indices, event in
                guard let self = self else { return }

                DispatchQueue.main.async {

                    switch event {
                    case .initial:
                        self.tableView.reloadData()

                    case .update:
                        self.updateViewFor(indices: indices)

                    @unknown default: break
                    }
                }

            }.store(in: &cancellables)
    }

    private func updateViewFor(indices: IndexSet) {
        let indexPaths = indices.map { IndexPath(row: $0, section: 0) }
        UIView.performWithoutAnimation {
            tableView.reloadRows(at: indexPaths, with: .automatic)
        }
        indexPaths.forEach { indexPath in
            let cell = tableView.cellForRow(at: indexPath) as? ItemTableViewCell
            cell?.animateBackground()
        }
    }

    private func setupNavBar() {
        title = "Inventory"

        let infoButton = UIButton(type: .infoLight)
        infoButton.addTarget(self, action: #selector(pushToInfoPage), for: .touchUpInside)
        let barButtonItem = UIBarButtonItem(customView: infoButton)
        navigationItem.leftBarButtonItem = barButtonItem
    }

    private func setupTableView() {
        view.addSubview(tableView)
        constrain(tableView) { (tableView) in
            tableView.left == tableView.superview!.left
            tableView.right == tableView.superview!.right
            tableView.bottom == tableView.superview!.bottom
            tableView.top == tableView.superview!.top
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ItemTableViewCell.self, forCellReuseIdentifier: ItemTableViewCell.REUSE_ID)
    }

    @objc private func pushToInfoPage() {
        navigationController?.pushViewController(dittoManager.dittoInfoView, animated: true)
    }
}

// MARK: - ItemTableViewCellDelegate

extension MainViewController: ItemTableViewCellDelegate {

    func plusButtonDidClick(itemId: Int) {
        dittoManager.incrementCounterFor(id: itemId)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func minusButtonDidClick(itemId: Int) {
        dittoManager.decrementCounterFor(id: itemId)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

}


// MARK: - UITableViewDataSource

extension MainViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ItemTableViewCell.REUSE_ID, for: indexPath) as! ItemTableViewCell
        let item = viewItems[indexPath.row]
        item.count = Int(dittoManager.models.items[indexPath.row].counter)
        cell.setup(item: item)
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dittoManager.models.items.count
    }

}

// MARK: - UITableViewDelegate

extension MainViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ItemTableViewCell.HEIGHT
    }

}
