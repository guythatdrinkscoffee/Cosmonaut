//
//  CTItemCell.swift
//  Cosmonaut
//
//  Created by J Manuel Zaragoza on 8/17/22.
//

import UIKit

class CTItemCell: UICollectionViewCell {
    // MARK: - Properties
    static let reuseIdentifer = "CTItemCell"
    
    public var item: Item? {
        didSet {
            self.configureForItem()
        }
    }
    
    private lazy var itemImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    public lazy var activityIndicator : UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .whiteLarge)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var gradient : CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.frame = contentView.bounds
        layer.colors = [UIColor.black.withAlphaComponent(0.7).cgColor,
                        UIColor.black.withAlphaComponent(0).cgColor]
        return layer
    }()
    
    private lazy var titleLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = .systemGray
        return label
    }()
    
    private lazy var copyrightLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .systemGray
        return label
    }()
    
    private lazy var dateLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .systemGray
        return label
    }()
    
    private lazy var labelsStackView : UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, copyrightLabel, dateLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 2
        return stackView
    }()
    
    // MARK: - Life cycle
    override init(frame: CGRect) {
        print(#function)
        super.init(frame: frame)
        self.layoutViews()
     
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        copyrightLabel.text = nil
        dateLabel.text = nil
        itemImageView.image = nil
        activityIndicator.startAnimating()
    }

}

// MARK: - Layout
extension CTItemCell {
    public func layoutViews(){
        contentView.addSubview(itemImageView)
        contentView.addSubview(activityIndicator)
        contentView.layer.insertSublayer(gradient, at: 1)
        contentView.addSubview(labelsStackView)
        backgroundColor = .black.withAlphaComponent(0.2)
        
        NSLayoutConstraint.activate([
            itemImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            itemImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            itemImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            itemImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            labelsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            labelsStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor, constant: 5),
            labelsStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
         
        ])
    }
}

// MARK: - Configuration
extension CTItemCell {
    public func updateWithImage(_ image: UIImage){
        DispatchQueue.main.async {
            self.itemImageView.image = image
            self.configureForItem()
            self.activityIndicator.stopAnimating()
        }
    }
    
    private func configureForItem(){
        guard let item = self.item else {
            return
        }
        
        titleLabel.text = item.title
        copyrightLabel.text = item.copyright
        dateLabel.text = item.date
    }
}
