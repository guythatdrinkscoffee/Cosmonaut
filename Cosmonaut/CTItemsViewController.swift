//
//  CTItemsViewController.swift
//  Cosmonaut
//
//  Created by J Manuel Zaragoza on 8/17/22.
//

import UIKit
import Combine

class CTItemsViewController: UIViewController {
    // MARK: - Properties
    private var items: [Item] = []
    private var datasource: UICollectionViewDiffableDataSource<AnyHashable,Item>!
    private var imageService = ImageService()
    private var cancellables = Set<AnyCancellable>()
    private var apodService = ApodService()
    private var nextStartDate = Date()
    private var calendar = Calendar.current
    private var isFetching = false
    private var fetchDayRange = -3
    
    private lazy var discoverCollectionView : UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: configureFlowLayout())
        collectionView.register(CTItemCell.self, forCellWithReuseIdentifier: CTItemCell.reuseIdentifer)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = datasource
        collectionView.delegate = self
        return collectionView
    }()
    
    private lazy var activityIndicator : UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .whiteLarge)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = self.calendar
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private lazy var displaySegmentedControl : UISegmentedControl = {
        let control = UISegmentedControl(items: [
            UIImage(systemName: "rectangle.portrait")!,
            UIImage(systemName: "square.grid.3x3")!
        ])
        control.frame = CGRect(x: .zero, y: .zero, width: view.bounds.size.width / 2, height: .zero)
        control.selectedSegmentIndex = 0
        return control
    }()
    
    private enum DisplayType {
        case portrait
        case grid
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configuration
        self.configureViewController()
        self.configureDataSource()
        
        // Layout
        self.layoutCollectionView()
        
        self.activityIndicator.startAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

// MARK: - Configuration
extension CTItemsViewController {
    private func configureViewController() {
        self.view.backgroundColor = .black
        self.tabBarItem = UITabBarItem(title: "Discover", image: UIImage(systemName: "moon.stars"), tag: 0)
        self.navigationItem.titleView = displaySegmentedControl
    }
    
    private func configureDataSource() {
        datasource = UICollectionViewDiffableDataSource<AnyHashable,Item>(collectionView: self.discoverCollectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CTItemCell.reuseIdentifer, for: indexPath) as! CTItemCell
            return cell
        })
    }
    
    private func configureFlowLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { section, layoutEnvironment in
            
            
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            
            let section = NSCollectionLayoutSection(group: group)
            
            return section
        }
        
        
        return layout
    }
}

// MARK: - Layout
extension CTItemsViewController {
    private func layoutCollectionView(){
        self.view.addSubview(discoverCollectionView)
        self.discoverCollectionView.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            discoverCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            discoverCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            discoverCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            discoverCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            self.activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            self.activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

// MARK: - Methods
extension CTItemsViewController {
    private func updateCollectionView(_ items: [Item]){
        guard !items.isEmpty else { return }
        var snapshot = NSDiffableDataSourceSnapshot<AnyHashable,Item>()
        snapshot.appendSections(["Main"])
        snapshot.appendItems(items)
        
        datasource.apply(snapshot, animatingDifferences: true)
    }
    
    private func fetchNextWeek(){
        isFetching = true
        let endDate = calendar.date(byAdding: DateComponents(day:fetchDayRange), to: nextStartDate)!
        
        let startDateFormatter = dateFormatter.string(from: nextStartDate)
        let endDateFormatter = dateFormatter.string(from: endDate)
        
        nextStartDate = calendar.date(byAdding: DateComponents(day: -1), to: endDate)!
        
        apodService
            .fetchInDateRange(start: endDateFormatter, end: startDateFormatter)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isFetching = false
                self.activityIndicator.stopAnimating()
            } receiveValue: { items in
                self.items.append(contentsOf: items)
                self.updateCollectionView(self.items)
            }
            .store(in: &cancellables)
    }
}

// MARK: - UICollectionViewDelegate
extension CTItemsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        
        imageService.fetchImageForItem(item)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                
            } receiveValue: { [weak self] image in
                ImageStore.shared.insert(key: NSString(string: item.imageURL.absoluteString), image: image)
                
                if let index = self?.items.firstIndex(of: item) {
                    let idx = IndexPath(item: index, section: 0)
                    if let cell = self?.discoverCollectionView.cellForItem(at: idx) as? CTItemCell {
                        cell.item = item
                        cell.updateWithImage(image)
                    }
                }
            }
            .store(in: &cancellables)
        
    }
}

// MARK: - ScrollviewDelegate
extension CTItemsViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yOffset = scrollView.contentOffset.y
        
        if yOffset > (discoverCollectionView.contentSize.height - 100) - scrollView.frame.size.height {
            guard !isFetching else {
                print("Already fetching")
                return
            }
            
            fetchNextWeek()
        }
    }
}
