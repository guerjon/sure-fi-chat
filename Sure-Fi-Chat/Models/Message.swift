//
//  Message.swift
//  Sure-Fi-Chat
//
//  Created by Sure-Fi Inc. on 11/27/17.
//  Copyright © 2017 Sure-Fi Inc. All rights reserved.
//

import Foundation
import CoreBluetooth

class Message {

    var message:String!
    var peripheral_id:String!
    var time:String
    
    init(message: String,peripheral_id:String) {
        self.message = message
        self.peripheral_id = peripheral_id
        self.time = Util.getCurrentDateString()
    }
    
}
