//
//  MultiDeviceLoginViewController.swift
//  TuyaAppSDKSample-iOS-Swift
//
//  Created by AI Assistant on 2024
//

import UIKit

// MARK: - Protocol
protocol DeviceLogoutVerificationDelegate: AnyObject {
    func didCompleteVerification()
    func didCompleteAccountVerification(with authModel: ThingSmartAccountAuthenticationModel)
}

class MultiDeviceLoginViewController: UIViewController {
    
    // MARK: - Properties
    private var loginTerminals: [ThingSmartLoginTerminalModel] = []
    private var isVerificationCompleted: Bool = false
    private var authModel: ThingSmartAccountAuthenticationModel?
    
    // MARK: - UI Elements
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(LoginDeviceCell.self, forCellReuseIdentifier: "LoginDeviceCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return refreshControl
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadLoginTerminals()
        setupNotificationObserver()
    }
    
    func dealloc() {
        removeNotificationObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Multi-Device Login Management"
        view.backgroundColor = .systemGroupedBackground
        
        // Add navigation bar button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshData)
        )
        
        // Add description text
        let descriptionLabel = UILabel()
        descriptionLabel.text = "Your account has been logged in on the following devices. You can remove devices. After removal, security verification will be required when logging in on that device."
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add table view
        view.addSubview(descriptionLabel)
        view.addSubview(tableView)
        tableView.addSubview(refreshControl)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Data Loading
    private func loadLoginTerminals() {
        ThingSmartUser.sharedInstance().getLoginTerminalList { [weak self] terminals in
            DispatchQueue.main.async {
                self?.loginTerminals = terminals ?? []
                self?.tableView.reloadData()
            }
        } failure: { [weak self] error in
            DispatchQueue.main.async {
                self?.showErrorAlert(message: "Failed to get login device list: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    @objc private func refreshData() {
        loadLoginTerminals()
        refreshControl.endRefreshing()
    }
    
    // MARK: - Notification Observer
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(registDeviceTokenForLogout),
            name: NSNotification.Name("kNotificationLogout"),
            object: nil
        )
    }
    
    private func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("kNotificationLogout"), object: nil)
    }
    
    @objc private func registDeviceTokenForLogout() {
        // Handle logout notification
        print("Received logout notification, returning to home page")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateInitialViewController()
        self.window?.rootViewController = vc
    }
    
    // MARK: - Alert Methods
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    private func logoutDevice(at indexPath: IndexPath) {
        let terminal = loginTerminals[indexPath.row]
        
        let alert = UIAlertController(
            title: "Confirm Logout",
            message: "Are you sure you want to log out from device \"\(terminal.platform ?? "Unknown Device")\"?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { [weak self] _ in
            self?.performLogout(terminal: terminal, at: indexPath)
        })
        
        present(alert, animated: true)
    }
    
    private func performLogout(terminal: ThingSmartLoginTerminalModel, at indexPath: IndexPath) {
        // Use the logout code from the stored authModel
        let logoutCode = self.authModel?.logoutCode
        
        // Terminate device session using logout code
        ThingSmartUser.sharedInstance().terminateSession(
            onDevice: terminal.terminalId,
            logoutCode: logoutCode ?? ""
        ) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.loginTerminals.remove(at: indexPath.row)
                    self?.tableView.deleteRows(at: [indexPath], with: .fade)
                    
                    let alert = UIAlertController(
                        title: "Logout Successful",
                        message: "Successfully logged out from device \"\(terminal.platform ?? "Unknown Device")\"",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                } else {
                    self?.showErrorAlert(message: "Failed to log out from device")
                }
            }
        } failure: { [weak self] error in
            DispatchQueue.main.async {
                self?.showErrorAlert(message: "Failed to log out from device: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension MultiDeviceLoginViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loginTerminals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LoginDeviceCell", for: indexPath) as! LoginDeviceCell
        cell.configure(with: loginTerminals[indexPath.row], isVerificationCompleted: isVerificationCompleted)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MultiDeviceLoginViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Device can only be deleted after verification is completed
        if isVerificationCompleted {
            logoutDevice(at: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        
        let label = UILabel()
        label.text = "Logged In Devices"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.backgroundColor = .clear
        
        let logoutButton = UIButton(type: .system)
        logoutButton.setTitle("Log Out Device", for: .normal)
        logoutButton.setTitleColor(.systemRed, for: .normal)
        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        logoutButton.backgroundColor = .systemBackground
        logoutButton.layer.cornerRadius = 8
        logoutButton.layer.borderWidth = 1
        logoutButton.layer.borderColor = UIColor.systemRed.cgColor
        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add right arrow icon
        let arrowImageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrowImageView.tintColor = .systemRed
        arrowImageView.translatesAutoresizingMaskIntoConstraints = false
        
        footerView.addSubview(logoutButton)
        logoutButton.addSubview(arrowImageView)
        
        NSLayoutConstraint.activate([
            logoutButton.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 16),
            logoutButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -16),
            logoutButton.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 16),
            logoutButton.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -16),
            logoutButton.heightAnchor.constraint(equalToConstant: 50),
            
            arrowImageView.trailingAnchor.constraint(equalTo: logoutButton.trailingAnchor, constant: -16),
            arrowImageView.centerYAnchor.constraint(equalTo: logoutButton.centerYAnchor),
            arrowImageView.widthAnchor.constraint(equalToConstant: 12),
            arrowImageView.heightAnchor.constraint(equalToConstant: 12)
        ])
        
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 82
    }
    
    @objc private func logoutButtonTapped() {
        // Navigate to verification page
        let verificationVC = DeviceLogoutVerificationViewController()
        verificationVC.delegate = self
        navigationController?.pushViewController(verificationVC, animated: true)
    }
}

// MARK: - Data Models
// Use ThingSmartLoginTerminalModel instead of custom LoginDevice

// MARK: - Custom Cell
class LoginDeviceCell: UITableViewCell {
    
    private let deviceIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let deviceNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let deviceTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loginTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let currentDeviceLabel: UILabel = {
        let label = UILabel()
        label.text = "Current Device"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(deviceIconImageView)
        contentView.addSubview(deviceNameLabel)
        contentView.addSubview(deviceTypeLabel)
        contentView.addSubview(loginTimeLabel)
        contentView.addSubview(locationLabel)
        contentView.addSubview(currentDeviceLabel)
        
        NSLayoutConstraint.activate([
            deviceIconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            deviceIconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            deviceIconImageView.widthAnchor.constraint(equalToConstant: 40),
            deviceIconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            deviceNameLabel.leadingAnchor.constraint(equalTo: deviceIconImageView.trailingAnchor, constant: 12),
            deviceNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            deviceNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: currentDeviceLabel.leadingAnchor, constant: -8),
            
            deviceTypeLabel.leadingAnchor.constraint(equalTo: deviceNameLabel.leadingAnchor),
            deviceTypeLabel.topAnchor.constraint(equalTo: deviceNameLabel.bottomAnchor, constant: 2),
            deviceTypeLabel.trailingAnchor.constraint(lessThanOrEqualTo: currentDeviceLabel.leadingAnchor, constant: -8),
            
            loginTimeLabel.leadingAnchor.constraint(equalTo: deviceNameLabel.leadingAnchor),
            loginTimeLabel.topAnchor.constraint(equalTo: deviceTypeLabel.bottomAnchor, constant: 2),
            loginTimeLabel.trailingAnchor.constraint(lessThanOrEqualTo: currentDeviceLabel.leadingAnchor, constant: -8),
            
            locationLabel.leadingAnchor.constraint(equalTo: deviceNameLabel.leadingAnchor),
            locationLabel.topAnchor.constraint(equalTo: loginTimeLabel.bottomAnchor, constant: 2),
            locationLabel.trailingAnchor.constraint(lessThanOrEqualTo: currentDeviceLabel.leadingAnchor, constant: -8),
            locationLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            
            currentDeviceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            currentDeviceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with terminal: ThingSmartLoginTerminalModel, isVerificationCompleted: Bool = false) {
        deviceNameLabel.text = terminal.platform ?? "Unknown Device"
        
        // Format login time
        let loginDate = Date(timeIntervalSince1970: terminal.loginTime)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd a h:mm"
        formatter.locale = Locale(identifier: "en_US")
        let timeString = formatter.string(from: loginDate)
        deviceTypeLabel.text = timeString
        
        // Hide other labels
        loginTimeLabel.isHidden = true
        locationLabel.isHidden = true
        
        // Show different labels based on verification status
        if isVerificationCompleted {
            currentDeviceLabel.text = "Tap to Delete"
            currentDeviceLabel.textColor = .systemRed
        } else {
            currentDeviceLabel.text = "Logged In Device"
            currentDeviceLabel.textColor = .systemBlue
        }
        currentDeviceLabel.isHidden = false
        
        // Set device icon
        switch terminal.os.lowercased() {
        case "ios":
            deviceIconImageView.image = UIImage(systemName: "iphone")
        case "ipados":
            deviceIconImageView.image = UIImage(systemName: "ipad")
        case "macos":
            deviceIconImageView.image = UIImage(systemName: "laptopcomputer")
        case "android":
            deviceIconImageView.image = UIImage(systemName: "phone")
        default:
            deviceIconImageView.image = UIImage(systemName: "device.iphone")
        }
        
        deviceIconImageView.tintColor = .systemBlue
    }
}

// MARK: - DeviceLogoutVerificationDelegate
extension MultiDeviceLoginViewController: DeviceLogoutVerificationDelegate {
    func didCompleteVerification() {
        // Refresh device list after verification is completed
        loadLoginTerminals()
    }
    
    func didCompleteAccountVerification(with authModel: ThingSmartAccountAuthenticationModel) {
        // Account verification completed, set status to true and store authModel
        isVerificationCompleted = true
        self.authModel = authModel
        
        // Refresh table view to make device rows clickable
        tableView.reloadData()
        
//        // Show success alert
//        let alert = UIAlertController(
//            title: "Verification Successful",
//            message: "You can now tap a device to delete it",
//            preferredStyle: .alert
//        )
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
    }
}
