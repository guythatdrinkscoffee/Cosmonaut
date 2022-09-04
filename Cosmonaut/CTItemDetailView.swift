//
//  CTItemDetailView.swift
//  Cosmonaut
//
//  Created by J Manuel Zaragoza on 8/17/22.
//

import Foundation
import UIKit
import Combine

class CTItemDetailView: UIViewController {
    // MARK: - Properties
    @Published var downloadHDPhoto: Bool = false
    var item: Item
    var itemImage: UIImage
    private var downloadService = DownloadService()
    private var cancellables = Set<AnyCancellable>()
    // MARK: - UI Elements
    private lazy var detailsScrollView : UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var contentView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = self.itemImage
        imageView.backgroundColor = .gray.withAlphaComponent(0.2)
        return imageView
    }()
    
    private lazy var titleLabel : UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 0
        label.text = item.title
        return label
    }()
    
    private lazy var copyrightLabel : UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .white
        label.text = item.copyright
        return label
    }()
    
    private lazy var dateLabel : UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .systemGray
        label.text = item.date
        return label
    }()
    
    private lazy var detailLabelsStackView : UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, copyrightLabel, dateLabel, explanationLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 5
        return stackView
    }()
    
    private lazy var explanationLabel : UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.text = item.explanation
        view.numberOfLines = 0
        view.textAlignment = .natural
        view.lineBreakMode = .byWordWrapping
        view.font = .preferredFont(forTextStyle: .body)
        return view
    }()
    
    // MARK: - Life cycle
    init(item: Item, itemImage: UIImage){
        self.item = item
        self.itemImage = itemImage
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configuration
        self.configureViewController()
        self.configureNavigationBar()
        
        // Layout
        self.layoutScrollView()
        self.layoutImageView()
        self.layoutDetailStackView()
    }
}

// MARK: - Configuration
extension CTItemDetailView {
    private func configureViewController(){
        self.view.backgroundColor = .systemBackground
        self.navigationItem.largeTitleDisplayMode = .never
      
    }
    
    private func configureNavigationBar(){
        let shareButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(shareImage))
        let downloadButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down"), style: .plain, target: self, action: #selector(downloadImageToPhotos))
        navigationItem.rightBarButtonItems = [shareButton, downloadButton]
    }
}

// MARK: - Layout
extension CTItemDetailView {
    private func layoutScrollView(){
        view.addSubview(detailsScrollView)
        detailsScrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            detailsScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            detailsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            detailsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            detailsScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                        
            contentView.topAnchor.constraint(equalTo: detailsScrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: detailsScrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: detailsScrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: detailsScrollView.contentLayoutGuide.bottomAnchor),
            
            contentView.centerXAnchor.constraint(equalTo: detailsScrollView.centerXAnchor),
            contentView.widthAnchor.constraint(equalTo: detailsScrollView.widthAnchor),
            contentView.heightAnchor.constraint(equalToConstant: 1000)
        ])
    }
    
    private func layoutImageView(){
        contentView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.heightAnchor.constraint(equalTo:view.heightAnchor, multiplier: 0.4)
        ])
    }
    
    private func layoutDetailStackView(){
        contentView.addSubview(detailLabelsStackView)
        
        NSLayoutConstraint.activate([
            detailLabelsStackView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            detailLabelsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            detailLabelsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
    
    private func presentPhotoHDAlert() {
        let alertController = UIAlertController(title: "HD Image Available", message: "The photo has a High Definition version. Would you like to download the HD version instead? ", preferredStyle: .alert)
        
        let downloadHDVersionAction = UIAlertAction(title: "Download HD", style: .default) { _ in
            self.downloadHDImage()
        }
        
        let originalVersionAction = UIAlertAction(title: "Save Original", style: .default) { _ in
            self.saveImage(self.itemImage)
        }
        
        alertController.addAction(originalVersionAction)
        alertController.addAction(downloadHDVersionAction)
        
        self.present(alertController, animated: true)
    }
    
    func saveImage(_ image: UIImage){
        UIImageWriteToSavedPhotosAlbum(image,self,  #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    func downloadHDImage(){
        self.downloadService
            .downloadHDImage(for: item)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                
            } receiveValue: { hdImage in
                self.saveImage(hdImage)
            }
            .store(in: &cancellables)
    }
}


// MARK: - Selector Methods
extension CTItemDetailView {
    @objc
    func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
           if let error = error {
               print("failed to save image: \(error.localizedDescription)")
           } else {
               print("successfully saved image")
           }
       }
    
    @objc
    private func shareImage(){
        let ac = UIActivityViewController(activityItems: [itemImage], applicationActivities: nil)
        self.present(ac, animated: true)
    }
    
    @objc
    private func downloadImageToPhotos(){
        downloadService
            .checkHasHDPhoto(for: item)
            .sink { hasHDImage in
                if hasHDImage {
                    self.presentPhotoHDAlert()
                } else {
                    self.saveImage(self.itemImage)
                }
            }
            .store(in: &cancellables)
    }
}
