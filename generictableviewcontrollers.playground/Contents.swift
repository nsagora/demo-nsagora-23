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
    let configure: CellConfiguration
    
    init(reuseIdentifier: String = "\(Cell.self)", configure: CellConfiguration) {
        self.reuseIdentifier = reuseIdentifier
        self.configure = configure
    }
    
    func register(tableView: UITableView) {
        tableView.register(Cell.self, forCellReuseIdentifier: reuseIdentifier)
    }
    
    private func dequeReusableCell(tableView: UITableView,
                                   for indexPath: IndexPath) -> Cell {
        return tableView.dequeueReusableCell(withIdentifier: reuseIdentifier,
                                             for: indexPath) as! Cell
    }
    
    func configuredCell(tableView: UITableView, for indexPath: IndexPath, with item: Item) -> Cell {
        let cell = dequeReusableCell(tableView: tableView, for: indexPath)
        configure(cell, item)
        return cell
    }
}

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

class MyOtherCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        print(reuseIdentifier)
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
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


struct AnyDataTemplate<T>: IDataTemplate {
    let _register: (UITableView) -> ()
    let _configure: (UITableView, IndexPath, T) -> UITableViewCell
    let reuseIdentifier: String
    
    init<U>(base: DataTemplate<T,U>) {
        _register = base.register
        _configure = base.configuredCell
        reuseIdentifier = base.reuseIdentifier
    }
    
    func register(tableView: UITableView) {
        _register(tableView)
    }
    
    func configuredCell(tableView: UITableView, for indexPath: IndexPath, with item: T) -> UITableViewCell {
        return _configure(tableView, indexPath, item)
    }
}

class DataTemplateSelector<Item>: IDataTemplate {
    typealias SelectorType = (Item) -> AnyDataTemplate<Item>
    let selector: SelectorType
    var registered = [String]()
    
    init(selector: SelectorType) {
        self.selector = selector
    }
    
    func register(tableView: UITableView) {
        
    }
    
    func configuredCell(tableView: UITableView, for indexPath: IndexPath, with item: Item) -> UITableViewCell {
        let dataTemplate = selector(item)
        let reuseIdentifier = dataTemplate.reuseIdentifier
        if !registered.contains(reuseIdentifier) {
            registered.append(reuseIdentifier)
            dataTemplate.register(tableView: tableView)
        }
        
        return dataTemplate.configuredCell(tableView: tableView, for: indexPath, with: item)
    }
}

let dataTemplate1 = DataTemplate { (cell: MyCell, item: Row) -> () in
    cell.textLabel?.text = item.title
    cell.detailTextLabel?.text = item.value
    cell.textLabel?.textColor = UIColor.red()
}

let dataTemplate2 = DataTemplate { (cell: MyOtherCell, item: Row) -> () in
    cell.textLabel?.text = item.title
    cell.detailTextLabel?.text = item.value
    cell.textLabel?.textColor = UIColor.blue()
}

let dataTemplateSelector = DataTemplateSelector { (item: Row) in
    switch item.isRed {
    case true:
        return AnyDataTemplate(base: dataTemplate1)
        
    case false:
        return AnyDataTemplate(base: dataTemplate2)
    }
}


let vc = ItemsViewController(items: items, dataTemplate: dataTemplateSelector)

//let array: [IDataTemplate] = [dataTemplate1, dataTemplate2]

vc.title = "Rows"

let nav = UINavigationController(rootViewController: vc)

PlaygroundPage.current.liveView = nav
