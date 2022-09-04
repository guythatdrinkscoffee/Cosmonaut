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
        self.configureViewControllers()
        
        selectedIndex = 0
    }
}

// MARK: - Configuration
extension CTMainTabVC {
    private func configureViewControllers(){
        self.viewControllers = [
            configureItemsViewController(),
            configureArchiveViewController()
        ]
    }
    
    private func configureItemsViewController() -> UINavigationController {
        let itemsViewController = CTItemsViewController()
        itemsViewController.tabBarItem = UITabBarItem(title: "Discover", image: UIImage(systemName: "moon.stars"), tag: 0)
        return UINavigationController(rootViewController: itemsViewController)
    }
    
    private func configureArchiveViewController() -> UINavigationController {
        let archiveViewController = CTArchiveViewController()
        archiveViewController.tabBarItem = UITabBarItem(title: "Archive", image: UIImage(systemName: "archivebox"), tag: 1)
        return UINavigationController(rootViewController: archiveViewController)
    }

}
