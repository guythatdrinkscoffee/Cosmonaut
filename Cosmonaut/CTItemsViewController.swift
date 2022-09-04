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
    private var fetchDayRange = -30
    
    private lazy var discoverCollectionView : UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: configureFlowLayout())
        collectionView.register(CTItemCell.self, forCellWithReuseIdentifier: CTItemCell.reuseIdentifer)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = datasource
        collectionView.prefetchDataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()
    
    private lazy var activityIndicator : UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = self.calendar
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    

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
        self.view.backgroundColor = .systemBackground
        self.title = "Discover"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.edgesForExtendedLayout = .all
    }
    
    private func configureDataSource() {
        datasource = UICollectionViewDiffableDataSource<AnyHashable,Item>(collectionView: self.discoverCollectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CTItemCell.reuseIdentifer, for: indexPath) as! CTItemCell
            return cell
        })
    }
    
    private func configureFlowLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { section, layoutEnvironment in            
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0) ,
                heightDimension: .fractionalHeight(1))
            
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalHeight(0.8))
            
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = discoverCollectionView.cellForItem(at: indexPath) as? CTItemCell,
              let itemImage = cell.itemImageView.image else { return }
        
        let item = items[indexPath.row]
        let detailViewController = CTItemDetailView(item: item, itemImage: itemImage)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

// MARK: - UICollectionViewPrefetching
extension CTItemsViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
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
}

// MARK: - ScrollviewDelegate
extension CTItemsViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yOffset = scrollView.contentOffset.y
        
        if yOffset > (discoverCollectionView.contentSize.height - 300) - scrollView.frame.size.height {
            guard !isFetching else {
                return
            }

            fetchNextWeek()
        }
    }
}
