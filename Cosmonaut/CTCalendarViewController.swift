//
//  CTCalendarViewController.swift
//  Cosmonaut
//
//  Created by J Manuel Zaragoza on 8/18/22.
//

import UIKit
import Combine

class CTCalendarViewController: UIViewController {
    var selectedDateSub = PassthroughSubject<Date, Never>()
    var fetchMonthSub = PassthroughSubject<Date,Never>()

    
    public lazy var datePicker : UIDatePicker = {
        let pickerView = UIDatePicker()
        pickerView.maximumDate = Date()
        pickerView.minimumDate = minDate
        pickerView.datePickerMode = .date
        pickerView.preferredDatePickerStyle = .inline
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        return pickerView
    }()
    
    private lazy var fetchMonthButton : UIButton = {
        let title = NSAttributedString(string: "Get Month", attributes: [ .font : UIFont.preferredFont(forTextStyle: .headline)])
        let button = UIButton(type: .system)
        button.setAttributedTitle(title, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(fetchMonth(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var fetchDateButton : UIButton = {
        let title = NSAttributedString(string: "Get Selected Date", attributes: [.font: UIFont.preferredFont(forTextStyle: .headline)])
        let button = UIButton(type: .system)
        button.setAttributedTitle(title, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(singleDateSelection(_:)), for: .touchUpInside)
        return button
    }()
    
    public var minDate: Date!
    
    override func viewDidLoad() {
     
        
        super.viewDidLoad()

        // Configuration
        self.configureViewController()
        
        // Layout
        self.layoutButtons()
        self.layoutPicker()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

// MARK: - Configuration
extension CTCalendarViewController {
    private func configureViewController(){
        self.view.backgroundColor = .systemBackground
        self.view.translatesAutoresizingMaskIntoConstraints = false
    }
}

// MARK: - Layout
extension CTCalendarViewController {
    private func layoutButtons(){
        self.view.addSubview(fetchMonthButton)
        self.view.addSubview(fetchDateButton)
        
        NSLayoutConstraint.activate([
            fetchMonthButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 5),
            fetchMonthButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
            
            fetchDateButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 5),
            fetchDateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
        ])
    }
    
    private func layoutPicker(){
        self.view.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: fetchMonthButton.bottomAnchor),
            datePicker.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            datePicker.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
    }
}

// MARK: - Selector Methods
extension CTCalendarViewController {
    @objc
    private func singleDateSelection(_ sender: UIButton){
        let date = datePicker.date
        
        selectedDateSub.send(date)
        self.dismiss(animated: true)
    }
    
    @objc
    private func fetchMonth(_ sender: UIButton){
        fetchMonthSub
            .send(datePicker.date)
        self.dismiss(animated: true)
    }
    
    @objc
    private func dateChanged(_ sender: UIDatePicker){
    }
}
