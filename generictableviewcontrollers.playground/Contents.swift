//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

class DataTemplate<Item, Cell: UITableViewCell> {
    typealias CellConfiguration = (Cell, Item) -> ()
    let reuseIdentifier: String
    let configureClosure: CellConfiguration
    
    init(reuseIdentifier: String = "\(Cell.self)", configure: CellConfiguration) {
        self.reuseIdentifier = reuseIdentifier
        configureClosure = configure
    }
    
    func register(tableView: UITableView) {
        tableView.register(Cell.self, forCellReuseIdentifier: reuseIdentifier)
    }
    
    private func dequeReusableCell(tableView: UITableView,
                           for indexPath: IndexPath) -> Cell {
        return tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,
                                             for: indexPath) as! Cell
    }
    
    private func configure(cell: Cell, item: Item) {
        configureClosure(cell, item)
    }
    
    func configuredCell(tableView: UITableView, for indexPath: IndexPath, with item: Item) -> Cell {
        let cell = dequeReusableCell(tableView: tableView, for: indexPath)
        configure(cell: cell, item: item)
        return cell
    }
}

class ItemsViewController<
    Item,
    Cell: UITableViewCell,
    DataTemplateType: DataTemplate<Item, Cell>
>: UITableViewController {
    let items: [Item]
    let dataTemplate: DataTemplateType
    
    init(items: [Item], dataTemplate: DataTemplateType) {
        self.items = items
        self.dataTemplate = dataTemplate
        super.init(style: .plain)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataTemplate.register(tableView: tableView)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        return dataTemplate.configuredCell(tableView: tableView, for: indexPath,with: item)
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
let configure = { (cell: MyCell, item: Row) -> () in
    cell.textLabel?.text = item.title
    cell.detailTextLabel?.text = item.value
}

let dataTemplate = DataTemplate(configure: configure)
let vc = ItemsViewController(items: items, dataTemplate: dataTemplate)

vc.title = "Rows"

let nav = UINavigationController(rootViewController: vc)

PlaygroundPage.current.liveView = nav
