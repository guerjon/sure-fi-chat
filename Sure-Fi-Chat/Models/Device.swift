//
//  Device.swift
//  Sure-Fi-Chat
//
//  Created by Sure-Fi Inc. on 12/6/17.
//  Copyright © 2017 Sure-Fi Inc. All rights reserved.
//

import Foundation

struct PropertyKey {
    static let id = "id"
    static let name = "name"
    static let device_id = "device_id"
    static let advertisement_state =  "advertisement_state"
    static let paired_id = "paired_id"
    static let bluetooth_connection = "bluetooth_connection"
}


/*
 static let id: String!
 static let name: String!
 static let device_id: String!
 static let advertisement_state : String!
 static let paired_id : String!
 static let bluetooth_connection : Int! {
 */

/*
    class used to save the bridge like a persistent data
*/

import UIKit
import os.log


class Device : NSObject, NSCoding {
    
    var id: String!
    var name: String!
    var device_id: String!
    var advertisement_state : String!
    var paired_id : String!
    var bluetooth_connection : Int!
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("devices")
    
    init(id:String, name:String?, device_id:String?,advertisement_state:String?,paired_id:String?,bluetooth_connection: Int?){
        self.id = id
        self.name = name
        self.device_id = device_id
        self.advertisement_state = advertisement_state
        self.paired_id = paired_id
        self.bluetooth_connection = bluetooth_connection 
    }
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id,forKey: PropertyKey.id)
        aCoder.encode(name,forKey: PropertyKey.name)
        aCoder.encode(device_id,forKey: PropertyKey.device_id)
        aCoder.encode(advertisement_state,forKey: PropertyKey.advertisement_state)
        aCoder.encode(paired_id,forKey: PropertyKey.paired_id)
        aCoder.encode(bluetooth_connection,forKey: PropertyKey.bluetooth_connection)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let id = aDecoder.decodeObject(forKey: PropertyKey.id) as? String else {
            os_log("Unable to decode the id for a Decoder object.", log: OSLog.default, type: .debug)
            return nil
        
            
        }
        guard let device_id = aDecoder.decodeObject(forKey: PropertyKey.device_id) as? String else{
            os_log("Unable to decode the device_id for Device object.", log: OSLog.default, type : .debug)
            return nil
        }
        
        let name = aDecoder.decodeObject(forKey: PropertyKey.name) as? String
        let advertisement_state = aDecoder.decodeObject(forKey: PropertyKey.advertisement_state) as? String
        let paired_id = aDecoder.decodeObject(forKey : PropertyKey.paired_id) as? String
        
        //let bluetooth_connection = aDecoder.decodeInteger(forKey: PropertyKey.bluetooth_connection)
        
        self.init(
            id:id,
            name:name,
            device_id: device_id,
            advertisement_state:advertisement_state,
            paired_id:paired_id,
            bluetooth_connection : 0
        )
    }
}
