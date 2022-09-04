//
//  CTArchiveViewController.swift
//  Cosmonaut
//
//  Created by J Manuel Zaragoza on 8/18/22.
//

import UIKit
import Combine
class CTArchiveViewController: UIViewController {
    // MARK: - Properties
    @Published var singleDateSelection: Date?
    @Published var monthBaseDate : Date?
    
    private var calendar = Calendar.current
    private var cancellables =   Set<AnyCancellable>()
    private var apodService = ApodService()
    private var dataSource: UICollectionViewDiffableDataSource<AnyHashable, Item>!
    private var imageService = ImageService()

    private var items: [Item] = []{
        didSet {
            self.updateCollectionView(items)
        }
    }
    
    private var isSelectedDateInTodayPublisher: AnyPublisher<Bool,Never>{
        $singleDateSelection
            .map { selectedDate -> Bool in
                if let selectedDate = selectedDate,
                   self.calendar.isDate(selectedDate, equalTo: Date(),toGranularity:  .month){
                    return true
                }
                return false
            }
            .eraseToAnyPublisher()
    }
    
    private var isMonthBaseDateInCurrentMonthPublisher: AnyPublisher<Bool,Never>{
        $monthBaseDate
            .map { monthBaseDate -> Bool in
                if let baseDate = monthBaseDate,
                   self.calendar.isDate(baseDate, equalTo: Date(), toGranularity: .year){
                    return true
                }
                return false
            }
            .eraseToAnyPublisher()
    }
    
    
    private var enableResetButtonPublisher: AnyPublisher<Bool,Never> {
        Publishers.CombineLatest(isSelectedDateInTodayPublisher, isMonthBaseDateInCurrentMonthPublisher)
            .map { isInToday, isMonthInCurrentMonth in
                if isInToday {
                    return true
                } else if isMonthInCurrentMonth {
                    return true
                }
                return false
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - UI Elements
    private lazy var itemsCollectionView : UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: configureLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(CTArchiveItemCell.self, forCellWithReuseIdentifier: CTArchiveItemCell.reuseIdentifier)
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        return collectionView
    }()
    
    private lazy var dateFormatter : DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = self.calendar
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var monthLabel : UILabel = {
        let label = UILabel(frame: CGRect(x: .zero, y: .zero, width: view.bounds.width * 0.5, height: 25))
        label.textAlignment = .center
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }()
    
    private lazy var resetButton : UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(systemName: "arrow.counterclockwise"), style: .plain, target: self, action: #selector(resetToCurrentMonth(_:)))
        return button
    }()
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Configuration
        self.configureViewController()
        self.configureNavigationBar()
        self.configureDataSource()
        
        // Layout
        self.layoutItemsCollectionView()
        self.layoutActivityIndcatorView()
        
        
        $singleDateSelection
            .sink { date in
                if let date = date {
                    self.fetchForSelectedDate(date)
                }
            }
            .store(in: &cancellables)
        
        $monthBaseDate
            .sink { fetchMonthDate in
                if let monthDate = fetchMonthDate {
                    self.fetchMonth(forBaseDate: monthDate)
                }
            }
            .store(in: &cancellables)
        
        enableResetButtonPublisher
            .receive(on: DispatchQueue.main)
            .print()
            .assign(to: \.resetButton.isEnabled, on: self)
            .store(in: &cancellables)
        
        self.fetchMonth()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
}

// MARK: - Configuration
extension CTArchiveViewController {
    private func configureViewController(){
        self.title = "Archive"
        self.view.backgroundColor = .systemBackground
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.titleView = monthLabel
    }
    
    private func configureNavigationBar(){
        let calendarButton = UIBarButtonItem(image: UIImage(systemName: "calendar"), style: .plain, target: self, action: #selector(toggleCalendar(_:)))
        navigationItem.rightBarButtonItems = [calendarButton, resetButton]
    }
    
    private func configureLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { section, layoutEnvironment in
            if self.items.count == 1 {
                let mainItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1.0)))

                mainItem.contentInsets = NSDirectionalEdgeInsets(
                  top: 2,
                  leading: 2,
                  bottom: 2,
                  trailing: 2)
                
                let group = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)), subitems: [mainItem])
                let section = NSCollectionLayoutSection(group: group)
                return section
            } else {
                let mainItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(2/3), heightDimension: .fractionalHeight(1.0)))

                mainItem.contentInsets = NSDirectionalEdgeInsets(
                  top: 2,
                  leading: 2,
                  bottom: 2,
                  trailing: 2)


                let pairItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.5)))

                pairItem.contentInsets = NSDirectionalEdgeInsets(
                  top: 2,
                  leading: 2,
                  bottom: 2,
                  trailing: 2)


                let trailingGroup = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalHeight(1.0)), subitem: pairItem, count: 1)

                let mainWithPair = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(4/9)), subitems: [mainItem,trailingGroup])

                let mainWithPairReversedGroup = NSCollectionLayoutGroup.horizontal(
                  layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalWidth(4/9)),
                  subitems: [trailingGroup, mainItem])


                let nestedGroup = NSCollectionLayoutGroup.vertical(
                  layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalWidth(16/9)),
                  subitems: [
                    mainWithPair,
                    mainWithPairReversedGroup
                  ]
                )


                let section = NSCollectionLayoutSection(group: nestedGroup)
                return section
            }
        }
        
        return layout
    }
    
    private func configureDataSource(){
        self.dataSource = UICollectionViewDiffableDataSource<AnyHashable,Item>(collectionView: itemsCollectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CTArchiveItemCell.reuseIdentifier, for: indexPath) as! CTArchiveItemCell
            cell.item = itemIdentifier
            return cell
        })
    }
}

// MARK: - Selector Methods
extension CTArchiveViewController {
    @objc
    private func resetToCurrentMonth(_ sender: UIButton){
        self.fetchMonth()
        self.singleDateSelection = nil
        self.monthBaseDate = nil
    }
    
    @objc
    private func toggleCalendar(_ sender: UIButton){
        let monthYearViewController = CTCalendarViewController()
        monthYearViewController.minDate = getMinumumArchiveDate()
        
//        if let selectedDate = singleDateSelection {
//            monthYearViewController.datePicker.date = selectedDate
//        } else if let monthBaseDate = monthBaseDate {
//            monthYearViewController.datePicker.date = monthBaseDate
//        }
//
        
        if let sheet = monthYearViewController.sheetPresentationController {
            sheet.detents = [.medium()]
        }
        
        monthYearViewController
            .selectedDateSub
            .compactMap({$0})
            .assign(to: \.singleDateSelection, on: self)
            .store(in: &cancellables)
        
        monthYearViewController
            .fetchMonthSub
            .compactMap({$0})
            .assign(to: \.monthBaseDate, on: self)
            .store(in: &cancellables)
        
        self.present(monthYearViewController, animated: true)
    }
    
}

// MARK: - Layout
extension CTArchiveViewController {
    private func layoutItemsCollectionView(){
        self.view.addSubview(itemsCollectionView)
    
        NSLayoutConstraint.activate([
            itemsCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            itemsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            itemsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            itemsCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func layoutActivityIndcatorView(){
        self.view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

extension UIView {
    public func pinTo(_ parent: UIView, top: CGFloat = 0, leading: CGFloat = 0, trailing: CGFloat = 0, bottom: CGFloat = 0){
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: parent.topAnchor),
            self.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            self.bottomAnchor.constraint(equalTo: parent.bottomAnchor)
        ])
    }
}

// MARK: - Methods
extension CTArchiveViewController {
    private func getMinumumArchiveDate(from today: Date = Date()) -> Date {
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let maxArchiveDate = "1995-06-16"

        
        if let date = dateFormatter.date(from: maxArchiveDate) {
            return date
        } else {
            return Date.now
        }
    }
    
    private func fetchMonth(forBaseDate date:  Date = Date()){
        self.activityIndicator.startAnimating()
        self.items.removeAll()
        
        let startOfMonthComponents = calendar.dateComponents([.year, .month], from: date)
        let startOfMonth = calendar.date(from: startOfMonthComponents)!
        let startOfNextMonth = calendar.date(byAdding: DateComponents(month:1), to: startOfMonth)!
        let endOfCurrentMonth = calendar.date(byAdding: DateComponents(day:-1), to: startOfNextMonth)!
        
        var start: String
        
        let minimumStartDate = getMinumumArchiveDate()
        
        if calendar.isDate(startOfMonth, equalTo: minimumStartDate, toGranularity: .year) {
            start = dateFormatter.string(from: minimumStartDate)
        } else {
            start = dateFormatter.string(from: startOfMonth)
        }
        
        let end: String
        
        if calendar.isDate(date, equalTo: Date(), toGranularity: .month){
            end = dateFormatter.string(from: Date())
        } else {
            end = dateFormatter.string(from: endOfCurrentMonth)
        }
        
        let monthText = getMonthString(date)
        setMonthLabel(monthText)
        
        apodService.fetchInDateRange(start: start, end: end)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.activityIndicator.stopAnimating()
            } receiveValue: { items in
                self.items = items
            }
            .store(in: &cancellables)

    }
    
    private func fetchForSelectedDate(_ baseDate: Date){
        self.activityIndicator.startAnimating()
        self.items.removeAll()
        
        let date = dateFormatter.string(from: baseDate)
        
        let dateString = getDateString(baseDate)
        setMonthLabel(dateString)
        
        apodService.fetchForDate(date: date)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.activityIndicator.stopAnimating()
            } receiveValue: { item in
                self.items.append(item)
            }.store(in: &cancellables)

    }
    
    private func getMonthString(_ baseDate: Date) -> String{
        dateFormatter.dateFormat = "MMM yyyy"
        let currentMonthText = dateFormatter.string(from: baseDate)
        dateFormatter.dateFormat = nil
        return currentMonthText
    }
    
    private func getDateString(_ baseDate: Date) -> String{
        dateFormatter.dateFormat = "MMM dd yyyy"
        let currentMonthText = dateFormatter.string(from: baseDate)
        dateFormatter.dateFormat = nil
        return currentMonthText
    }
    
    private func updateCollectionView(_ items: [Item]){
        var snapshot = NSDiffableDataSourceSnapshot<AnyHashable, Item>()
        snapshot.appendSections(["Main"])
        snapshot.appendItems(items)
        dataSource.apply(snapshot)
    }
    
    private func setMonthLabel(_ text: String){
        DispatchQueue.main.async {
            self.monthLabel.text = text
        }
    }
}

// MARK: - UICollectionViewDelegate
extension CTArchiveViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        
        imageService.fetchImageForItem(item)
            .receive(on: DispatchQueue.main)
            .sink { completion in
 
            } receiveValue: { [weak self] image in
                ImageStore.shared.insert(key: NSString(string: item.imageURL.absoluteString), image: image)

                if let index = self?.items.firstIndex(of: item) {
                    let idx = IndexPath(item: index, section: 0)
                    if let cell = self?.itemsCollectionView
                        .cellForItem(at: idx) as? CTArchiveItemCell {
                        cell.updateWithImage(image)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = itemsCollectionView.cellForItem(at: indexPath) as? CTArchiveItemCell,
              let itemImage = cell.imageView.image else { return }
        
        let item = items[indexPath.row]
        let detailViewController = CTItemDetailView(item: item, itemImage: itemImage)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}
