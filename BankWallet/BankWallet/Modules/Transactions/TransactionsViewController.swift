import UIKit
import SnapKit
import GrouviActionSheet

class TransactionsViewController: UITableViewController {

    let delegate: ITransactionsViewDelegate

    private let cellName = String(describing: TransactionCell.self)

    private let emptyLabel = UILabel()
    private let filterHeaderView = TransactionCurrenciesHeaderView()

    init(delegate: ITransactionsViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        tabBarItem = UITabBarItem(title: "transactions.tab_bar_item".localized, image: UIImage(named: "transactions.tab_bar_item"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "transactions.title".localized

        filterHeaderView.onSelectCoin = { [weak self] coin in
            self?.delegate.onFilterSelect(coin: coin)
        }

        tableView.backgroundColor = AppTheme.controllerBackground
        tableView.tableFooterView = UIView(frame: .zero)

        tableView.registerCell(forClass: TransactionCell.self)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: .greatestFiniteMagnitude, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 0
        tableView.delaysContentTouches = false

        let emptyView = UIView()
        emptyView.backgroundColor = .clear
        tableView.backgroundView = emptyView

        emptyLabel.text = "transactions.empty_text".localized
        emptyLabel.numberOfLines = 0
        emptyLabel.font = .systemFont(ofSize: 14)
        emptyLabel.textColor = .cryptoGray
        emptyLabel.textAlignment = .center
        emptyView.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(50)
            maker.trailing.equalToSuperview().offset(-50)
        }

        delegate.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate.onViewAppear()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    func bind(at indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? TransactionCell {
            let item = delegate.item(forIndex: indexPath.row)
            cell.bind(item: item)
        }
    }

}

extension TransactionsViewController: ITransactionsView {

    func show(filters: [Coin?]) {
        filterHeaderView.reload(filters: filters)
    }

    func reload() {
        tableView.reloadData()
    }

    func reload(indexes: [Int]) {
        tableView.reloadData()
//        for index in indexes {
//            bind(at: IndexPath(row: index, section: 0))
//        }
    }

    func reload(with diff: [IndexChange]) {
        tableView.reloadData()
//        var updateIndexes = [Int]()
//        var insertIndexes = [Int]()
//        var moveIndexes = [(Int, Int)]()
//        for change in diff {
//            switch change {
//            case .update(let index):
//                updateIndexes.append(index)
//            case .insert(let index):
//                insertIndexes.append(index)
//            case .move(let fromIndex, let toIndex):
//                updateIndexes.append(toIndex)
//                moveIndexes.append((fromIndex, toIndex))
//            }
//        }
//
//        guard !insertIndexes.isEmpty || !moveIndexes.isEmpty else {
//            reload(indexes: updateIndexes)
//            return
//        }
//
//        tableView.performBatchUpdates({ [weak self] in
//            self?.tableView.insertRows(at: insertIndexes.map {
//                IndexPath(row: $0, section: 0)
//            }, with: .automatic)
//            for movedIndex in moveIndexes {
//                self?.tableView.moveRow(at: IndexPath(row: movedIndex.0, section: 0), to: IndexPath(row: movedIndex.1, section: 0))
//            }
//        }, completion: { [weak self] _ in
//            self?.reload(indexes: updateIndexes)
//        })
    }

}

extension TransactionsViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = delegate.itemsCount

        emptyLabel.isHidden = count > 0

        return count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: cellName, for: indexPath)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? TransactionCell {
            cell.bind(item: delegate.item(forIndex: indexPath.row))
        }

        if indexPath.row >= self.tableView(tableView, numberOfRowsInSection: 0) - 1 {
            delegate.onBottomReached()
        }
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate.onTransactionItemClick(index: indexPath.row)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TransactionsTheme.cellHeight
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return filterHeaderView.filters.isEmpty ? 0 : TransactionsFilterTheme.filterHeaderHeight
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return filterHeaderView
    }

}
