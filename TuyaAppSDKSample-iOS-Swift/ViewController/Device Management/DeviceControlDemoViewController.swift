//
//  DeviceControlDemoViewController.swift
//  ThingAppSDKSample-iOS-Swift
//
//  Created by AppWeLove on 2026-04-23.
//

import UIKit
import ThingSmartDeviceKit
import SVProgressHUD

class DeviceControlDemoViewController: UIViewController {

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let deviceHeaderLabel = UILabel()
    
    private let consoleTextView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .black
        tv.textColor = .green
        tv.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        tv.isEditable = false
        tv.layer.cornerRadius = 8
        return tv
    }()

    private var targetDevice: ThingSmartDevice?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        detectDevice()
    }

    private func setupUI() {
        title = "Device Control Demo"
        view.backgroundColor = .systemGroupedBackground
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        // Device Detection Header
        deviceHeaderLabel.numberOfLines = 0
        deviceHeaderLabel.font = .systemFont(ofSize: 14, weight: .medium)
        deviceHeaderLabel.textColor = .systemBlue
        stackView.addArrangedSubview(deviceHeaderLabel)
        
        addSection(title: "1. Light Control (Standard DPs)", items: [
            DemoItem(name: "Switch", dp: "1", type: .bool, value: "true", description: "Standard Power Switch"),
            DemoItem(name: "Brightness", dp: "20", type: .int, value: "500", description: "Range: 10-1000"),
            DemoItem(name: "Color Temp", dp: "21", type: .int, value: "300", description: "Range: 0-1000")
        ])
        
        addSection(title: "2. Fan Control (Standard DPs)", items: [
            DemoItem(name: "Switch", dp: "1", type: .bool, value: "true", description: "Power Switch"),
            DemoItem(name: "Fan Speed", dp: "3", type: .enum, value: "\"mid\"", description: "low, mid, high")
        ])
        
        addSection(title: "3. AC Control (Standard DPs)", items: [
            DemoItem(name: "Switch", dp: "1", type: .bool, value: "true", description: "Power Switch"),
            DemoItem(name: "Target Temp", dp: "2", type: .int, value: "24", description: "Target temperature in °C"),
            DemoItem(name: "Mode", dp: "4", type: .enum, value: "\"cool\"", description: "cool, heat, auto, fan")
        ])
        
        addConsoleSection()
    }

    private func detectDevice() {
        logToConsole("Welcome to Device Control Demo!\n")
        
        if let homeModel = Home.current, let home = ThingSmartHome(homeId: homeModel.homeId) {
            home.getDataWithSuccess({ [weak self] _ in
                if let firstDevice = home.deviceList.first {
                    self?.targetDevice = ThingSmartDevice(deviceId: firstDevice.devId)
                    self?.deviceHeaderLabel.text = "🟢 Found Device: \(firstDevice.name)\nID: \(firstDevice.devId)\nCommands will be sent to this real device."
                    self?.logToConsole("Detected real device: \(firstDevice.name)")
                } else {
                    self?.deviceHeaderLabel.text = "🟡 No devices found in current home.\nDemo will operate in SIMULATION mode."
                    self?.logToConsole("No real devices found. Using simulation mode.")
                }
            }, failure: { [weak self] _ in
                self?.deviceHeaderLabel.text = "🔴 Failed to fetch devices.\nDemo will operate in SIMULATION mode."
            })
        } else {
            deviceHeaderLabel.text = "⚪️ No Home selected.\nDemo will operate in SIMULATION mode."
            logToConsole("No home selected. Using simulation mode.")
        }
    }

    private func addSection(title: String, items: [DemoItem]) {
        let sectionLabel = UILabel()
        sectionLabel.text = title.uppercased()
        sectionLabel.font = .systemFont(ofSize: 14, weight: .bold)
        sectionLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(sectionLabel)
        
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 12
        container.clipsToBounds = true
        stackView.addArrangedSubview(container)
        
        let itemStack = UIStackView()
        itemStack.axis = .vertical
        itemStack.spacing = 0
        itemStack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(itemStack)
        
        NSLayoutConstraint.activate([
            itemStack.topAnchor.constraint(equalTo: container.topAnchor),
            itemStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            itemStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            itemStack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        for (index, item) in items.enumerated() {
            let itemView = createItemView(item: item)
            itemStack.addArrangedSubview(itemView)
            
            if index < items.count - 1 {
                let separator = UIView()
                separator.backgroundColor = .separator
                separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                itemStack.addArrangedSubview(separator)
            }
        }
    }

    private func createItemView(item: DemoItem) -> UIView {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: 70).isActive = true
        
        let nameLabel = UILabel()
        nameLabel.text = item.name
        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        
        let descLabel = UILabel()
        descLabel.text = "\(item.description) (DP \(item.dp))"
        descLabel.font = .systemFont(ofSize: 12)
        descLabel.textColor = .secondaryLabel
        
        let labelStack = UIStackView(arrangedSubviews: [nameLabel, descLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 4
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(labelStack)
        
        let button = DemoButton(type: .system)
        button.item = item
        button.setTitle("Send", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        button.backgroundColor = .systemOrange.withAlphaComponent(0.1)
        button.layer.cornerRadius = 15
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            labelStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            labelStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            labelStack.trailingAnchor.constraint(lessThanOrEqualTo: button.leadingAnchor, constant: -8),
            
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        button.addTarget(self, action: #selector(handleSendTapped(_:)), for: .touchUpInside)
        
        return view
    }

    @objc private func handleSendTapped(_ sender: DemoButton) {
        guard let item = sender.item else { return }
        simulatePublish(item: item)
    }

    private func addConsoleSection() {
        let label = UILabel()
        label.text = "LIVE PAYLOAD CONSOLE"
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = .secondaryLabel
        stackView.addArrangedSubview(label)
        
        consoleTextView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        stackView.addArrangedSubview(consoleTextView)
    }

    // MARK: - Logic
    private func simulatePublish(item: DemoItem) {
        let dps = [item.dp: item.value]
        let payload = "{\"\(item.dp)\": \(item.value)}"
        
        if let device = targetDevice {
            logToConsole(">>> [REAL] Sending to \(device.deviceModel.name ?? ""): \(payload)")
            
            // Note: In real app, value type should match DP schema (bool, int, string)
            // For this demo we use the string representation which might need parsing
            var val: Any = item.value
            if item.type == .bool { val = (item.value == "true") }
            else if item.type == .int { val = Int(item.value) ?? 0 }
            else if item.type == .enum { val = item.value.replacingOccurrences(of: "\"", with: "") }

            device.publishDps([item.dp: val], success: { [weak self] in
                self?.logToConsole("✅ Success: Command received by device.")
                SVProgressHUD.showSuccess(withStatus: "Command Sent")
            }, failure: { [weak self] error in
                let err: Error? = error
                let msg = err?.localizedDescription ?? "Unknown error"
                self?.logToConsole("❌ Error: \(msg)")
                SVProgressHUD.showError(withStatus: "Failed: \(msg)")
            })
        } else {
            logToConsole(">>> [SIMULATION] publishDps(\(payload))")
            logToConsole("Code: device.publishDps([\"\(item.dp)\": \(item.value)], success: { ... }, failure: { ... })")
            SVProgressHUD.showSuccess(withStatus: "Simulated DP \(item.dp)")
        }
        logToConsole("--------------------------------")
    }

    private func logToConsole(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        
        consoleTextView.text += "[\(timestamp)] \(message)\n"
        
        let range = NSMakeRange(consoleTextView.text.count - 1, 1)
        consoleTextView.scrollRangeToVisible(range)
    }
}

// MARK: - Helper Models
class DemoButton: UIButton {
    var item: DemoItem?
}

struct DemoItem {
    let name: String
    let dp: String
    let type: DPType
    let value: String
    let description: String
}

enum DPType {
    case bool
    case int
    case `enum`
    case string
}
