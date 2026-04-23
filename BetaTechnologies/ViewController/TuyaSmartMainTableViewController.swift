//
//  ThingSmartMainTableViewController.swift
//  BetaTechnologies
//
//  Copyright (c) 2014-2021 Thing Inc. (https://developer.tuya.com/)

import UIKit
import ThingSmartBaseKit

class ThingSmartMainTableViewController: UITableViewController {
    
    enum DisplayMode {
        case home
        case profile
    }
    
    var displayMode: DisplayMode = .home
    
    // MARK: - IBOutlet
    @IBOutlet weak var logoutButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch displayMode {
        case .home:
            self.title = NSLocalizedString("Home", comment: "Home Tab Title")
        case .profile:
            self.title = NSLocalizedString("Profile", comment: "Profile Tab Title")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - IBAction
    @IBAction func logoutTapped(_ sender: UIButton) {
        let alertViewController = UIAlertController(title: nil, message: NSLocalizedString("You're going to log out this account.", comment: "User tapped the logout button."), preferredStyle: .actionSheet)
        let logoutAction = UIAlertAction(title: NSLocalizedString("Logout", comment: "Confirm logout."), style: .destructive) { [weak self] (action) in
            guard let self = self else { return }
            ThingSmartUser.sharedInstance().loginOut {
                AppRouter.transitionToLogin()
            } failure: {
                [weak self] (error) in
                   guard let self = self else { return }
                   Alert.showBasicAlert(on: self, with: NSLocalizedString("Failed to Log Out", comment: "Failed to Log Out"), message: error?.localizedDescription ?? "")
            }
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel)
        
        alertViewController.popoverPresentationController?.sourceView = sender
        
        alertViewController.addAction(logoutAction)
        alertViewController.addAction(cancelAction)
        
        self.present(alertViewController, animated: true, completion: nil)
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSectionVisible(section) {
            return super.tableView(tableView, numberOfRowsInSection: section)
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if isSectionVisible(section) {
            return super.tableView(tableView, heightForHeaderInSection: section)
        } else {
            return 0.01 // Use 0.01 to effectively hide the header in Grouped style
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSectionVisible(section) {
            return super.tableView(tableView, titleForHeaderInSection: section)
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if isSectionVisible(section) {
            return super.tableView(tableView, heightForFooterInSection: section)
        } else {
            return 0.01
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if isSectionVisible(section) {
            return super.tableView(tableView, titleForFooterInSection: section)
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isSectionVisible(indexPath.section) {
            return super.tableView(tableView, heightForRowAt: indexPath)
        } else {
            return 0 // Hidden
        }
    }
    
    private func isSectionVisible(_ section: Int) -> Bool {
        switch displayMode {
        case .home:
            // Home shows everything EXCEPT User Management (section 0)
            return section != 0
        case .profile:
            // Profile shows ONLY User Management (section 0)
            return section == 0
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 && indexPath.row == 1 {
            // FaceID Login setting 
            let vc = FaceIDLoginViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.section == 0 && indexPath.row == 2 {
            // Multi-device Login Management
            let vc = MultiDeviceLoginViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.section == 0 && indexPath.row == 3 {
            // Logout button row tapped
            logoutTapped(UIButton())
        }
        else if indexPath.section == 3 && indexPath.row == 1 {
            guard let current = ThingSmartFamilyBiz.sharedInstance().getCurrentFamily() as? ThingSmartHomeModel else {return}
            guard let home = ThingSmartHome(homeId: current.homeId) else {return}
            let vc = DeviceDetailKitVC(home: home)
            self.navigationController?.pushViewController(vc, animated: true)
        }else if indexPath.section == 3 && indexPath.row == 2 {
            guard let current = ThingSmartFamilyBiz.sharedInstance().getCurrentFamily() as? ThingSmartHomeModel else {return}
            guard let home = ThingSmartHome(homeId: current.homeId) else {return}
            let vc = OtaDevicesVc(home: home)
            self.navigationController?.pushViewController(vc, animated: true)
        } else if indexPath.section == 7 && indexPath.row == 0 {
            // Device Control Demo
            let vc = DeviceControlDemoViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
