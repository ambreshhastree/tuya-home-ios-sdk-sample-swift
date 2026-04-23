//
//  AppRouter.swift
//  BetaTechnologies
//
//  Copyright (c) 2014-2021 Thing Inc. (https://developer.tuya.com/)

import UIKit

struct AppRouter {
    static func mainAppTabBar() -> UITabBarController? {
        let storyboard = UIStoryboard(name: "ThingSmartMain", bundle: nil)
        
        // Create Home Tab
        guard let homeNavController = storyboard.instantiateInitialViewController() as? UINavigationController,
              let homeVC = homeNavController.topViewController as? ThingSmartMainTableViewController else { return nil }
        homeVC.displayMode = .home
        homeNavController.tabBarItem = UITabBarItem(title: NSLocalizedString("Home", comment: ""), image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
        
        // Create Profile Tab
        guard let profileNavController = storyboard.instantiateInitialViewController() as? UINavigationController,
              let profileVC = profileNavController.topViewController as? ThingSmartMainTableViewController else { return nil }
        profileVC.displayMode = .profile
        profileNavController.tabBarItem = UITabBarItem(title: NSLocalizedString("Profile", comment: ""), image: UIImage(systemName: "person.crop.circle"), selectedImage: UIImage(systemName: "person.crop.circle.fill"))
        
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [homeNavController, profileNavController]
        
        return tabBarController
    }
    
    static func loginViewController() -> UIViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateInitialViewController()
    }
    
    static func transitionToMainApp() {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        window.rootViewController = mainAppTabBar()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
    
    static func transitionToLogin() {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        window.rootViewController = loginViewController()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
}
