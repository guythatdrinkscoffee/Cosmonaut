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
    
    private lazy var containerView : UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    public lazy var itemImageView : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    
    public lazy var activityIndicator : UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .large)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var copyrightLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .white
        return label
    }()
    
    private lazy var dateLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .headline)
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
    
    private lazy var gradient : CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.black.withAlphaComponent(1).cgColor, UIColor.black
            .withAlphaComponent(0).cgColor]
        layer.frame = contentView.frame
        layer.locations = [0.0, 0.5]
        return layer
    }()
    
    // MARK: - Life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layoutViews()
        activityIndicator.startAnimating()
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
        contentView.addSubview(containerView)
        contentView.addSubview(activityIndicator)
        contentView.layer.insertSublayer(gradient, at: 1)
        contentView.addSubview(labelsStackView)
        containerView.addSubview(itemImageView)
        
        containerView.pinTo(contentView)
        itemImageView.pinTo(containerView)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            labelsStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            labelsStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor, constant: 10),
            labelsStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
        ])
    }
}

// MARK: - Configuration
extension CTItemCell {
    public func updateWithImage(_ image: UIImage){
        DispatchQueue.main.async {
            self.itemImageView.image = image
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
        dateLabel.textColor = .gray
    }
}
