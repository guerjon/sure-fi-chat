//
//  NavigationController.swift
//  Sure-Fi-Chat
//
//  Created by Sure-Fi Inc. on 12/7/17.
//  Copyright © 2017 Sure-Fi Inc. All rights reserved.
//

import UIKit
import CoreBluetooth
import AudioToolbox.AudioServices

let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
var lastBridgeScanned: Int!
var btController: BluetoothController!
var known_devices : [Device]!

class NavigationController: UINavigationController {

    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initBluetoothController()
        checkForSavedDevices()
    }
    
    private func initBluetoothController(){
        print("initBluetoothController()")
        btController = BluetoothController()
    }
    
    private func checkForSavedDevices(){
        print("checkForSavedDevices()")
        known_devices = NSKeyedUnarchiver.unarchiveObject(withFile: Device.ArchiveURL.path) as? [Device]
    }
}
