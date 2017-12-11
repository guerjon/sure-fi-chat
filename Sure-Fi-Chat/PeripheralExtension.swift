//
//  PeripheralExtension.swift
//  Sure-Fi-Chat
//
//  Created by Sure-Fi Inc. on 11/21/17.
//  Copyright © 2017 Sure-Fi Inc. All rights reserved.
//

import Foundation
import CoreBluetooth

private var xoAssociationKey: UInt8 = 0
private var xoAssociationKey_2: UInt8 = 0
private var xoAssociationKey_3: UInt8 = 0
private var xoAssociationKey_4: UInt8 = 0

extension CBPeripheral {
    
    var device_id: String! {
        get {
            return objc_getAssociatedObject(self, &xoAssociationKey) as? String
        }
        set(newValue) {
            objc_setAssociatedObject(self, &xoAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
        
    var advertisement_state : String! {
        get{
            return objc_getAssociatedObject(self, &xoAssociationKey_2) as? String
        }
        
        set(newValue_2) {
            objc_setAssociatedObject(self, &xoAssociationKey_2, newValue_2, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var paired_id : String! {
        get{
            return objc_getAssociatedObject(self, &xoAssociationKey_3) as? String
        }
        
        set(newValue_3) {
            objc_setAssociatedObject(self, &xoAssociationKey_3, newValue_3, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var bluetooth_connection : Int! {
        get{
            return objc_getAssociatedObject(self, &xoAssociationKey_4) as? Int
        }
        
        set(newValue_4) {
            objc_setAssociatedObject(self, &xoAssociationKey_4, newValue_4, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}
