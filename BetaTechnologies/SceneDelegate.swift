//
//  SceneDelegate.swift
//  BetaTechnologies
//
//  Copyright (c) 2014-2021 Thing Inc. (https://developer.tuya.com/)

import UIKit
import ThingSmartBaseKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
//        guard let _ = (scene as? UIWindowScene) else { return }
        
        if let windowScene = scene as? UIWindowScene {
            self.window = UIWindow(windowScene: windowScene)
            
            if ThingSmartUser.sharedInstance().isLogin {
                if let mainVC = AppRouter.mainAppTabBar() {
                    self.window?.rootViewController = mainVC
                }
            } else {
                if let loginVC = AppRouter.loginViewController() {
                    self.window?.rootViewController = loginVC
                }
            }
            
            self.window?.makeKeyAndVisible()
        }
    }
}

