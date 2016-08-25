//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

class ItemsViewController<Item, Cell: UITableViewCell>: UITableViewController {
    typealias CellConfiguration = (Cell, Item) -> ()
    
    let items: [Item]
    let reuseIdentifier = "Cell"
    let configure: CellConfiguration
    
    init(items: [Item], configure: CellConfiguration) {
        self.items = items
        self.configure = configure
        super.init(style: .plain)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(Cell.self, forCellReuseIdentifier: reuseIdentifier)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! Cell
        configure(cell, items[indexPath.row])
        return cell
    }
}

class MyCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct Row {
    let title: String
    let value: String
}

let items = (0...10).map { Row(title:"Row \($0)", value: "\($0 * 10)") }

let vc = ItemsViewController(items: items) { (cell: MyCell, item) in
    cell.textLabel?.text = item.title
    cell.detailTextLabel?.text = item.value
}
vc.title = "Rows"

let nav = UINavigationController(rootViewController: vc)

PlaygroundPage.current.liveView = nav
