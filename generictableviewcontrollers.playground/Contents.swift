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
    
    init(reuseIdentifier: String = "\(Cell.self)", configure: @escaping CellConfiguration) {
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

struct AnyDataTemplate<T>: IDataTemplate {
    let reuseIdentifier: String
    
    let _register: (UITableView) -> ()
    let _configure: (UITableView, IndexPath, T) -> UITableViewCell
    
    init<Cell>(base: DataTemplate<T, Cell>) {
        _register = base.register
        _configure = base.configuredCell
        reuseIdentifier = base.reuseIdentifier
    }
    
    private init(register: @escaping (UITableView) -> (),
                 reuseIdentifier: String,
                 configure: @escaping (UITableView, IndexPath, T) -> UITableViewCell) {
        _register = register
        _configure = configure
        self.reuseIdentifier = reuseIdentifier
    }
    
    func register(tableView: UITableView) {
        _register(tableView)
    }
    
    func configuredCell(tableView: UITableView, for indexPath: IndexPath, with item: T) -> UITableViewCell {
        return _configure(tableView, indexPath, item)
    }
    
    func with<U>(item: T) -> AnyDataTemplate<U> {
        return AnyDataTemplate<U>(register: _register,
                                  reuseIdentifier: reuseIdentifier,
                                  configure: { (tableView:UITableView, indexPath:IndexPath, _) -> UITableViewCell in
                                    self._configure(tableView, indexPath, item)
        })
    }
}

extension DataTemplate {
    var erased: AnyDataTemplate<Item> {
        return AnyDataTemplate(base: self)
    }
}

class DataTemplateSelector<Item>: IDataTemplate {
    typealias SelectorType = (Item) -> AnyDataTemplate<Item>
    let selector: SelectorType
    var registered = [String]()
    
    init(selector: @escaping SelectorType) {
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

class ItemsViewController<
    Item,
    DataTemplate: IDataTemplate>: UITableViewController
    where DataTemplate.Item == Item
 {
    let items: [Item]
    let dataTemplate: DataTemplate
    
    init(items: [Item], dataTemplate: DataTemplate) {
        self.items = items
        self.dataTemplate = dataTemplate
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

struct Foo {
    let title: String
    let value: String
    let isRed: Bool
}

struct Bar {
    let title: String
}

enum FooBar {
    case Fuh(Foo)
    case Bur(Bar)
}

let items = (0...100).map { (index) -> FooBar in
    if index % 5 == 0 {
        return FooBar.Fuh(Foo(title:"Foo \(index)", value: "\(index * 10)", isRed: (index % 2 == 0)))
    } else {
        return FooBar.Bur(Bar(title:"Bar \(index)"))
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
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

let dataTemplate1 = DataTemplate { (cell: MyCell, item: Foo) -> () in
    cell.textLabel?.text = item.title
    cell.detailTextLabel?.text = item.value
    cell.textLabel?.textColor = item.isRed ? UIColor.red : UIColor.green
}

let dataTemplate2 = DataTemplate { (cell: MyOtherCell, item: Bar) -> () in
    cell.textLabel?.text = item.title
    cell.detailTextLabel?.text = "Generics & Shit"
}

let dataTemplateSelector = DataTemplateSelector { (item: FooBar) in
    switch item {
    case .Fuh(let foo):
        return dataTemplate1.erased.with(item: foo)
    case .Bur(let bar):
        return dataTemplate2.erased.with(item: bar)
    }
}

let vc = ItemsViewController(items: items, dataTemplate: dataTemplateSelector)
vc.title = "Rows"
let nav = UINavigationController(rootViewController: vc)

PlaygroundPage.current.liveView = nav
