//
//  CTCalendarCell.swift
//  Cosmonaut
//
//  Created by J Manuel Zaragoza on 8/18/22.
//

import UIKit

class CTCalendarCell: UICollectionViewCell {
    static let reuseIdentifier = "CTCalendarCell"
    
    private lazy var textLabel : UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .blue
        label.textAlignment = .center
        return label
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layoutViews()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Layout
extension CTCalendarCell {
    private func layoutViews(){
        self.contentView.addSubview(textLabel)
        textLabel.pinTo(contentView)
    }
}

// MARK: - Configuration
extension CTCalendarCell {
    public func configureWithText(_ text: String){
        textLabel.text = text
    }
}
