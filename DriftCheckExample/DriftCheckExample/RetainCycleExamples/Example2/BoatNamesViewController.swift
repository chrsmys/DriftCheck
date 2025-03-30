import UIKit

struct Boat: Hashable {
    let id = UUID()
    let name: String
}

class BoatNamesViewController: UIViewController {
    
    private let tableView = UITableView()
    private var dataSource: UITableViewDiffableDataSource<Int, Boat>!
    
    private let items: [Boat] = [
        Boat(name: "Seas Optional"),
        Boat(name: "Dispatch Ahoy"),
        Boat(name: "Main Thread Mariner"),
        Boat(name: "Sea Optional"),
        Boat(name: "ARCade Floater"),
        Boat(name: "Set Sail()"),
        Boat(name: "Swift Tide"),
        Boat(name: "BuoyantController"),
        Boat(name: "The Retainin’ Sea"),
        Boat(name: "Weak Self, Strong Current"),
        Boat(name: "IBOutSea"),
        Boat(name: "Nil on Arrival"),
        Boat(name: "FloatyPoint"),
        Boat(name: "The Great Deinitializer"),
        Boat(name: "The Leak Finder"),
        Boat(name: "NSSeafarer"),
        Boat(name: "async & anchor"),
        Boat(name: "OceanQueue"),
        Boat(name: "Objective-Sea"),
        Boat(name: "Sail Sync"),
        Boat(name: "The Real Delegate"),
        Boat(name: "The Singleton"),
        Boat(name: "S.S. Beta Crash"),
        Boat(name: "Thread Safe Harbor"),
        Boat(name: "Just One More Build"),
        Boat(name: "SeaError(.timeout)"),
        Boat(name: "The Interface Buoy"),
        Boat(name: "Payload Pirate"),
        Boat(name: "Core Paddle"),
        Boat(name: "Live Preview")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "iOS Boat Names"
        view.backgroundColor = .systemBackground
        setupTableView()
        configureDataSource()
        applySnapshot()
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
    }
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: self.configureCell)
    }
    
    private func configureCell(tableView: UITableView, indexPath: IndexPath, boat: Boat) -> UITableViewCell? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.text = boat.name
        return cell
    }
    
    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Boat>()
        snapshot.appendSections([0])
        snapshot.appendItems(items.sorted{$0.name.lowercased() < $1.name.lowercased()}, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    @objc private func close() {
        navigationController?.popViewController(animated: true)
    }
}
