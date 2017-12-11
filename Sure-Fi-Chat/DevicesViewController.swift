//
//  DevicesViewController.swift
//  Sure-Fi-Chat
//
//  Created by Sure-Fi Inc. on 12/6/17.
//  Copyright © 2017 Sure-Fi Inc. All rights reserved.
//

import UIKit
import SafariServices
import CoreBluetooth

class DevicesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var timer = Timer()
    var connect_timer = Timer()
    var connection_status_timer = Timer()
    @IBOutlet var staring_label: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var table_devices: DevicesTableViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startScan()
        Util.setTimeOut(function: startTimer, time: 2)
        activityIndicator.startAnimating()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return known_devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let device = known_devices[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "device_cell", for: indexPath)
        cell.textLabel?.text = device.device_id
        return cell
    }

    @objc func tryToConnect(_ timer: Timer){
        print("TryToConnect")
        let device = timer.userInfo as? CBPeripheral
        print("Device:  \(device?.device_id)")
        btController.centralManager.connect(device!)
    }
    
    private func startConnectTimer(device:CBPeripheral) {
        print("startConnectTimer()")
        connect_timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(tryToConnect(_:)), userInfo: device, repeats: true)
    }
    
    private func stopConnectTimer(){
        print("stopConnectTimer()")
        connect_timer.invalidate()
    }

    private func checkKnowDevices(devices: [CBPeripheral]){
        print("checkKnowDevices()")
        var device_on_range = false
        var selected_device: CBPeripheral!
        if(known_devices != nil){ //we have known devices
           //know devices are the devices saved on file
            table_devices.isHidden = false
            let saved_device = known_devices[0]
            
            for device in devices
            {
                print("Saved device id : \(saved_device.device_id)")
                print("Found it device id: \(device.device_id)")
                if(saved_device.device_id.uppercased() == device.device_id.uppercased()){
                    stopTimer()
                    device_on_range = true
                    selected_device = device
                    break
                }
            }
            
            if(device_on_range){
                
                startConnectTimer(device: selected_device)
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
                controller.device = selected_device
                controller.connect_timer = connect_timer
                controller.centralManager = btController.centralManager
                self.navigationController?.pushViewController(controller, animated: true)
                //devices_table.isHidden = false
            }
        }else{
            // we don't hava any devices and need goes to the scan to start scanning
            print("There are  not devices.")
            goToScanQrCodeView()
            stopTimer()
        }
    }

    
    func goToScanQrCodeView(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "ScanQrViewController") as! ScanQrViewController
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    private func startTimer(){
        print("startTimer()")
        self.timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(DevicesViewController.checkForDevices), userInfo: nil, repeats: true)
    }
    
    private func stopTimer(){
        print("stopTimer()")
        self.timer.invalidate()
    }
    
    private func startScan(){
        print("startScan()")
        btController.startScan()
    }

    @objc private func checkForDevices(){
        print("checkForDevices() \(String(btController.devices.count) )")
        if btController.devices.count > 0 {
            checkKnowDevices(devices: btController.devices)
        }
    }
}
