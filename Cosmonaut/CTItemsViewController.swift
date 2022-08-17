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
    private var items: [Item] = Array(Item.initFromJsonFile().reversed())
    private var datasource: UICollectionViewDiffableDataSource<AnyHashable,Item>!
    private var imageService = ImageService()
    private var cancellables = Set<AnyCancellable>()
    private lazy var discoverCollectionView : UICollectionView = {
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: configureFlowLayout())
        collectionView.register(CTItemCell.self, forCellWithReuseIdentifier: CTItemCell.reuseIdentifer)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = datasource
        collectionView.delegate = self
        return collectionView
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.updateCollectionView(items)
    }
}

// MARK: - Configuration
extension CTItemsViewController {
    private func configureViewController() {
        self.view.backgroundColor = .black
        self.tabBarItem = UITabBarItem(title: "Discover", image: UIImage(systemName: "moon.stars"), tag: 0)
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
        
        NSLayoutConstraint.activate([
            discoverCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            discoverCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            discoverCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            discoverCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
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
        
        datasource.apply(snapshot)
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
