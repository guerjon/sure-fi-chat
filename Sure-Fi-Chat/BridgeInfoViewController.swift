//
//  BridgeInfoViewController.swift
//  Sure-Fi-Chat
//
//  Created by Sure-Fi Inc. on 11/21/17.
//  Copyright © 2017 Sure-Fi Inc. All rights reserved.
//

import UIKit
import CoreBluetooth

class BridgeInfoViewController: UIViewController {

    var device : CBPeripheral!
    var centralManager: CBCentralManager!
    
    @IBOutlet weak var connected_label: UILabel!
    @IBOutlet weak var success_label: UIImageView!
    @IBOutlet weak var activity_indicator: UIActivityIndicatorView!
    
    var timer = Timer()
    var connect_timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activity_indicator.startAnimating()
        notificationFeedbackGenerator.prepare()
        startConnectTimer()
        startTimer()
    }

    func startConnectTimer() {
        connect_timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(BridgeInfoViewController.tryToConnect), userInfo: nil, repeats: true)
    }
    
    @objc func tryToConnect(){
        centralManager.connect(device)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func startTimer(){
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(BridgeInfoViewController.checkConnectionStatus), userInfo: nil, repeats: true)
    }
    
    private func stopTimer(){
        timer.invalidate()
    }
    
    private func stopConnectTimer(){
        connect_timer.invalidate()
    }
    
    private func handleConnection(){
        print("Conneted")
        stopConnectTimer()
        connected_label.text = "Connected !"
        connected_label.textColor = UIColor.green
        success_label.isHidden = false
        activity_indicator.stopAnimating()
        activity_indicator.isHidden = true
        notificationFeedbackGenerator.notificationOccurred(.success)
        stopTimer()
        
        Util.setTimeOut(function: moveToNextScreen, time: 2)
    }
    
    private func moveToNextScreen() {
        print("BridgeInfoViewController - MoveToNextScreen()")
        /*let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "chat_view_controller") as! ChatViewController
        controller.device = self.device
        controller.centralManager = self.centralManager

        self.navigationController?.pushViewController(controller, animated: true)*/
    }
    
    @objc private func checkConnectionStatus(){
        print("checkConnectionStatus()", device.bluetooth_connection)
        if(device.bluetooth_connection == 1){
            handleConnection()
        }
    }
}
