//
//  CTArchiveItemCell.swift
//  Cosmonaut
//
//  Created by J Manuel Zaragoza on 8/19/22.
//

import Foundation
import UIKit

class CTArchiveItemCell: UICollectionViewCell {
    static let reuseIdentifier = "CTArchiveItemCell"
    
    public var item: Item? {
        didSet {
            self.configureForItem()
        }
    }

    private lazy var containerView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    public lazy var imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private lazy var dateLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .white
        return label
    }()
    
    // MARK: - Life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}

// MARK: - Configuration
extension CTArchiveItemCell {
    private func layoutViews(){
        self.contentView.addSubview(containerView)
        self.contentView.addSubview(imageView)
        self.contentView.addSubview(dateLabel)
        
        containerView.pinTo(contentView)
        imageView.pinTo(containerView)
        
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor,constant: 10),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0)
        ])
    }
    
    
    private func configureForItem(){
        guard let item = self.item else {
            return
        }
        
        dateLabel.text = item.date
    }
    
    public func updateWithImage(_ image: UIImage){
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }
}
