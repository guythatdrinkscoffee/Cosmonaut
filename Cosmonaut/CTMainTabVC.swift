//
//  CTMainTabVC.swift
//  Cosmonaut
//
//  Created by J Manuel Zaragoza on 8/17/22.
//

import UIKit

class CTMainTabVC: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configuration
        self.configureViewController()
        self.configureViewControllers()
    }
}

// MARK: - Configuration
extension CTMainTabVC {
    private func configureViewController(){
        self.tabBar.tintColor = .systemGray
    }
    
    private func configureViewControllers(){
        self.viewControllers = [configureItemsViewController()]
    }
    
    private func configureItemsViewController() -> UINavigationController {
        let itemsViewController = CTItemsViewController()
        return UINavigationController(rootViewController: itemsViewController)
    }
}
