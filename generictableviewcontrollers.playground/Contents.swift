//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

protocol IDataTemplate {
    associatedtype Item
    associatedtype Cell: UITableViewCell
    
    func register(tableView: UITableView)
    func configuredCell(tableView: UITableView, for indexPath: IndexPath, with item: Item) -> Cell
}

struct DataTemplate<Item, Cell: UITableViewCell>: IDataTemplate {
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

//struct DataTemplateSelector<Item>: IDataTemplate {
//    typealias DataTemplateType = DataTemplate<AnyObject, UITableViewCell>
//    typealias DataTemplateDictionary = [String: DataTemplateType]
//    typealias Selector = (Item) -> String
//    
//    var dataTemplates: DataTemplateDictionary
//    var selector: Selector
//    
//    init(dataTemplates: [String: DataTemplateType], selector: Selector) {
//        self.dataTemplates = dataTemplates
//        self.selector = selector
//    }
//    
//    func register(tableView: UITableView) {
//        dataTemplates.forEach { $0.1.register(tableView: tableView) }
//    }
//
//    func selectDataTemplate(item: Item) -> DataTemplateType {
//        return dataTemplates[selector(item)]!
//    }
//    
//    func configuredCell(tableView: UITableView, for indexPath: IndexPath, with item: Item) -> UITableViewCell {
//        return UITableViewCell()
//    }
//}

class ItemsViewController<
    Item,
    DataTemplate: IDataTemplate
    where DataTemplate.Item == Item
>: UITableViewController {
    let items: [Item]
    let dataTemplate: DataTemplate
    
    init(items: [Item], dataTemplate: DataTemplate) {
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
    let isRed: Bool
}

let items = (0...10).map { Row(title:"Row \($0)", value: "\($0 * 10)", isRed: ($0 % 2 == 0)) }

let dataTemplate1 = DataTemplate { (cell: MyCell, item: Row) -> () in
    cell.textLabel?.text = item.title
    cell.detailTextLabel?.text = item.value
    cell.textLabel?.textColor = UIColor.red()
}

let dataTemplate2 = DataTemplate { (cell: MyCell, item: Row) -> () in
    cell.textLabel?.text = item.title
    cell.detailTextLabel?.text = item.value
    cell.textLabel?.textColor = UIColor.blue()
}

struct DataTemplateSelector: IDataTemplate {
    typealias DataTemplateType = DataTemplate<Row, MyCell>
    let templates: [DataTemplateType]
    
    func register(tableView: UITableView) {
        templates.forEach { $0.register(tableView: tableView) }
    }
    
    func configuredCell(tableView: UITableView,
                        for indexPath: IndexPath,
                        with item: Row) -> UITableViewCell {
        return templates[item.isRed ? 0 : 1].configuredCell(tableView: tableView, for: indexPath, with: item)
    }
}

//let dataTemplates = ["1": dataTemplate1, "2": dataTemplate2] as!
//    [String: DataTemplate<AnyObject, UITableViewCell>]
//let dataTemplateSelector = DataTemplateSelector(dataTemplates: dataTemplates) { (item: Row) -> () in
//    return "1"
//}

let selector = DataTemplateSelector(templates:[dataTemplate1, dataTemplate2])
let vc = ItemsViewController(items: items, dataTemplate: selector)

vc.title = "Rows"

let nav = UINavigationController(rootViewController: vc)

PlaygroundPage.current.liveView = nav
