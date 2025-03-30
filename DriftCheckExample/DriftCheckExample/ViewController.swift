//
//  ViewController.swift
//  DriftCheckExample
//
//  Created by Chris Mays on 3/22/25.
//

import UIKit
import SwiftUI

import UIKit

import UIKit
import SwiftUI


class MenuViewController: UIViewController {

    struct Row {
        let title: String
        let description: String
        let viewController: () -> UIViewController
        private(set) var navbarCustomization: ((UINavigationController) -> Void)?
    }
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    enum Section: Int, CaseIterable {
        case uikit
        case swiftui
        
        var title: String {
            switch self {
            case .uikit: return "UIKit"
            case .swiftui: return "SwiftUI"
            }
        }
    }
    
    private lazy var uikitExamples: [Row] = [
        .init(title: "Pirate Grog Counter", description: "Example 1 - Track the grog that you drank.", viewController: { GrogCounterViewController() }),
        .init(title: "Boat name ideas", description: "Example 2 - Get inspiration for your next boat name.", viewController: { BoatNamesViewController() }),
        .init(title: "Boat tracker",  description: "Example 3 - Track your boat", viewController: { BoatTrackingViewController() })
    ]
    
    private lazy var swiftUIExamples: [Row] = [
        .init(title: "Go fish", description: "Example 4 - Catch as many fish as you can.", viewController: {
            UIHostingController(rootView: GoFishView())
        }, navbarCustomization: { navigationController in
            navigationController.navigationBar.tintColor = .white
            navigationController.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        })
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Menu"
        view.backgroundColor = .systemBackground
        setupTableView()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
}

extension MenuViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIndex: Int) -> Int {
        guard let section = Section(rawValue: sectionIndex) else { return 0 }
        switch section {
        case .uikit: return uikitExamples.count
        case .swiftui: return swiftUIExamples.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { return UITableViewCell() }
        let item = section == .uikit ? uikitExamples[indexPath.row] : swiftUIExamples[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.secondaryText = item.description
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }
        let item = section == .uikit ? uikitExamples[indexPath.row] : swiftUIExamples[indexPath.row]
        let controller = item.viewController()
        
        let navController = UINavigationController(rootViewController: controller)
        navController.modalPresentationStyle = .fullScreen
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Close", style: .plain, target: self, action: #selector(close))
        item.navbarCustomization?(navController)
        present(navController, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection sectionIndex: Int) -> String? {
        return Section(rawValue: sectionIndex)?.title
    }
    
    @objc func close() {
        presentedViewController?.dismiss(animated: true)
    }
}
