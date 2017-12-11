//
//  NewTableViewController.swift
//  Sure-Fi-Chat
//
//  Created by Sure-Fi Inc. on 11/20/17.
//  Copyright © 2017 Sure-Fi Inc. All rights reserved.
//

import UIKit
import CoreBluetooth

class NewTableViewController: UITableViewController {

    var devices = [CBPeripheral]()
    var centralManager: CBCentralManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let device = devices[indexPath.row]
        cell.textLabel?.text = device.device_id.uppercased()
        if(device.device_id.uppercased() == "100193"){
                cell.textLabel?.text = "--------------- 100193"
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "bridge_connected_info") as! BridgeInfoViewController
        controller.device = devices[indexPath.row]
        controller.centralManager = centralManager
        self.navigationController?.pushViewController(controller, animated: true)   
    }
}
