//
//  BluetoothController.swift
//  Sure-Fi-Chat
//
//  Created by Sure-Fi Inc. on 11/16/17.
//  Copyright © 2017 Sure-Fi Inc. All rights reserved.
//

import Foundation
import CoreBluetooth
import CoreLocation

class BluetoothController: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var surefiMfgStrings: [String:String] = [:]
    var devices = [CBPeripheral]()
    var connection_status = 0
    var centralManager: CBCentralManager!
    var write_chat_package = 0
    var chatTextBytes: [UInt8] = []
    
    var SUREFI_SERVICE_UUID: CBService!
    var SUREFI_RX_UID_UUID : CBCharacteristic!
    var SUREFI_TX_UID_UUID : CBCharacteristic!
    var SUREFI_STATUS_UUID : CBCharacteristic!
    var SUREFI_SEC_SERVICE_UUID : CBService!
    var SUREFI_SEC_HASH_UUID    : CBCharacteristic!
    var SUREFI_CMD_SERVICE_UUID  : CBService!
    var SUREFI_CMD_WRITE_UUID    : CBCharacteristic!
    var SUREFI_CMD_READ_UUID     : CBCharacteristic!
    var send_message_status : Int = 0;
    var chat_vc : ChatViewController!;
    
    private var deviceTxCharacteristic: CBCharacteristic!
    private var deviceRxCharacteristic: CBCharacteristic!
    private var deviceStatusCharacteristic: CBCharacteristic!
    private var deviceSecHashCharacteristic: CBCharacteristic!
    
    var deviceCmdWriteCharacteristic: CBCharacteristic!
    var deviceCmdReadCharacteristic: CBCharacteristic!
    
    public override init(){
        super.init()
    }
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("centralManagerDidUpdateState() \(central.state.rawValue)")
        if (central.state == CBManagerState.poweredOn)
        {
            centralManager!.scanForPeripherals(withServices: [Constants.SUREFI_SERVICE_UUID,Constants.SUREFI_CMD_SERVICE_UUID,Constants.SUREFI_SEC_SERVICE_UUID], options:  [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        }
        else
        {
            print("Bluetooth not available")
        }
    }
    
    func startScan(){
        print("startScan()")
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func stopScan(){
        print("stopScan()")
        centralManager.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnected()")
        peripheral.delegate = self
        peripheral.discoverServices([])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral()")
        connection_status = 0
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("didDiscoverServices()")
        for service in peripheral.services! {
            let thisService = service as CBService
            //print("SFBridgeController - Discovered Service...\(thisService.uuid)")
            if service.uuid == Constants.SUREFI_SERVICE_UUID || service.uuid == Constants.SUREFI_SEC_SERVICE_UUID || service.uuid == Constants.SUREFI_CMD_SERVICE_UUID {
                
                switch (service.uuid){
                case Constants.SUREFI_SERVICE_UUID:
                    //print("Initializate Constants.SUREFI_SERVICE_UUID")
                    self.SUREFI_SERVICE_UUID = service;
                case Constants.SUREFI_SEC_SERVICE_UUID:
                    //print("Initializate Constants.SUREFI_SEC_SERVICE_UUID")
                    self.SUREFI_SEC_SERVICE_UUID = service
                    
                case Constants.SUREFI_CMD_SERVICE_UUID:
                    //print("Initializate Constants.SUREFI_CMD_SERVICE_UUID")
                    self.SUREFI_CMD_SERVICE_UUID = service
                default:
                    print("Error on switch while scanning")
                }
                peripheral.discoverCharacteristics(nil,for: thisService)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateNotificationStateFor \(characteristic.uuid.uuidString)")
        if error != nil{
            print(error!)
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if(error == nil){
            var value = (characteristic.value?.hexStringFromData() ?? "").uppercased()
            
            print("Value update for \(characteristic.uuid.uuidString) characteristic - New Value: \(value)")
            
            if(characteristic.uuid == Constants.SUREFI_CMD_READ_UUID){ // chat receiver
                value = (characteristic.value?.hexStringFromData() ?? "").uppercased()
                
                let response = value.cutStringOnRange(from: 0, to: 1)
                let data = value.cutStringOnRange(from: 2, to: value.count - 1 )
                
                switch(response){
                case "23":
                    chat_vc.chatReceiveMessageLenght = data.hexaToDecimal // the lenght of our final message
                    print("chatReceiveMessageLenght: \(chat_vc.chatReceiveMessageLenght)")
                    
                case "24":
                    
                    let newBytes = [UInt8](data.dataFromHexString() as! Data)
                    let string = String(bytes: newBytes, encoding: .utf8)
                    chat_vc.chatReceiveMessage = chat_vc.chatReceiveMessage + string!
                        
                    print("chat_vc.chatReceiveMessage: \(chat_vc.chatReceiveMessage)")
                    print("chatReceiveMessageLenght: \(chat_vc.chatReceiveMessageLenght!) - chatReceiveMessage: \(chat_vc.chatReceiveMessage.count)")
                    
                    if(chat_vc.chatReceiveMessageLenght == chat_vc.chatReceiveMessage.count ){ // we have all the message on chatReceiveMessage
                        chat_vc.drawReceiveMessage()
                    }
                    
                    break
                default:
                    print("No option found for: \(response) - Data: ( \(data) )")
                }
            }
            
            if characteristic.uuid == Constants.SUREFI_STATUS_UUID {
                value = (characteristic.value?.hexStringFromData() ?? "").uppercased()
                
                let response = value.cutStringOnRange(from: 0, to: 2)
                let data = value.cutStringOnRange(from: 2, to: value.count - 1 )
                
                print("SFBridgeController - BLE Read - Response:\(response) Data:\(data)")
                
                let timestamp = Double(NSDate().timeIntervalSince1970)
                
                //let dict = ["timestamp":"\(timestamp)","type":"read","cmd":response,"data":data]
                
                switch(response){
                case "21":
                    print("Chat Packet Sending")
                    break
                case "22":
                    print("Chat Packet Complete")
                    
                    if chatTextBytes.count > 0 {
                        
                        let time = Date().timeIntervalSince1970
                        if chatTextBytes.count > 0 && chatTextBytes[0] == 0x0E {
                            
                            let chatItem = NSMutableDictionary()
                            chatItem.setValue("success", forKey: "status")
                            chatItem.setValue("Sent", forKey: "state")
                            chatItem.setValue("ping", forKey: "type")
                            if chat_vc.selectedDeviceType == 1 {
                                chatItem.setValue("central", forKey: "source")
                            } else {
                                chatItem.setValue("remote", forKey: "source")
                            }
                            chat_vc.chatItems[time] = chatItem
                            chat_vc.saveChatItems()
                            
                        } else if chatTextBytes.count > 0 && chatTextBytes[0] == 0x0F {
                            
                            chatTextBytes.remove(at: 0)
                            let latBytes = Array(chatTextBytes[0..<4])
                            let longBytes = Array(chatTextBytes[4..<8])
                            //let accuracyBytes = Array(chatTextBytes[8..<10])
                            
                            let lat = Double(Util.fromByteArray(latBytes, UInt32.self)) / 10000000
                            let long = Double(Util.fromByteArray(longBytes, UInt32.self)) / -10000000
                            let accuracy = 0 //Int(Util().fromByteArray(accuracyBytes, UInt16.self))
                            
                            let chatItem = NSMutableDictionary()
                            chatItem.setValue("success", forKey: "status")
                            chatItem.setValue("Sent", forKey: "state")
                            chatItem.setValue("location", forKey: "type")
                            chatItem.setValue("\(lat)", forKey: "latitude")
                            chatItem.setValue("\(long)", forKey: "longitude")
                            chatItem.setValue("\(accuracy)", forKey: "accuracy")
                            if chat_vc.selectedDeviceType == 1 {
                                chatItem.setValue("central", forKey: "source")
                            } else {
                                chatItem.setValue("remote", forKey: "source")
                            }
                            chat_vc.chatItems[time] = chatItem
                            chat_vc.saveChatItems()
                            
                        } else {
                            
                            if let string = String(bytes: chatTextBytes, encoding: .utf8) {
                                let chatItem = NSMutableDictionary()
                                chatItem.setValue(string, forKey: "text")
                                chatItem.setValue("success", forKey: "status")
                                chatItem.setValue("Sent", forKey: "state")
                                chatItem.setValue("message", forKey: "type")
                                if chat_vc.selectedDeviceType == 1 {
                                    chatItem.setValue("central", forKey: "source")
                                } else {
                                    chatItem.setValue("remote", forKey: "source")
                                }
                                chat_vc.chatItems[time] = chatItem
                                chat_vc.saveChatItems()
                            } else {
                                print("not a valid UTF-8 sequence")
                            }
                        }
                        chatTextBytes.removeAll()
                    }
                    break
                case "23":
                    print("Chat Packet Recieved")
                    chat_vc.chatReceiveBytes.removeAll()
                    chat_vc.chatReceiveLength = data.hexaToDecimal //tenemos la longitud de los bytes
                    break
                    
                case "24":
                    print("Chat Packet Piece")
                    let newBytes = [UInt8](data.dataFromHexString() as! Data)
                    chat_vc.chatReceiveBytes += newBytes
                    
                    if chat_vc.chatReceiveBytes.count >= chat_vc.chatReceiveLength {
                        
                        let time = Date().timeIntervalSince1970
                        if chat_vc.chatReceiveBytes.count > 0 && chat_vc.chatReceiveBytes[0] == 0x0E { // sending the ping
                            
                            print(chat_vc.chatReceiveBytes)
                            let chatItem = NSMutableDictionary()
                            chatItem.setValue("success", forKey: "status")
                            chatItem.setValue("Received", forKey: "state")
                            chatItem.setValue("ping", forKey: "type")
                            if chat_vc.selectedDeviceType == 1 {
                                chatItem.setValue("remote", forKey: "source")
                            } else {
                                chatItem.setValue("central", forKey: "source")
                            }
                            chat_vc.chatItems[time] = chatItem
                            chat_vc.saveChatItems()
                            
                        } else if chat_vc.chatReceiveBytes.count > 0 && chat_vc.chatReceiveBytes[0] == 0x0F { // sending the location
                          
                        }  else if chat_vc.chatReceiveBytes.count > 0 && chat_vc.chatReceiveBytes[0] == 0x1F { // recieve other kind of location
                            
                           
                        } else {
                            // this is a normal message
                            if let string = String(bytes: chat_vc.chatReceiveBytes, encoding: .utf8) {
                                
                                let chatItem = NSMutableDictionary()
                                chatItem.setValue(string, forKey: "text")
                                chatItem.setValue("success", forKey: "status")
                                chatItem.setValue("Received", forKey: "state")
                                chatItem.setValue("message", forKey: "type")
                                if chat_vc.selectedDeviceType == 1 {
                                    chatItem.setValue("remote", forKey: "source")
                                } else {
                                    chatItem.setValue("central", forKey: "source")
                                }
                                chat_vc.chatItems[time] = chatItem
                                chat_vc.saveChatItems()
                            } else {
                                print("not a valid UTF-8 sequence")
                            }
                        }
                        chat_vc.chatReceiveBytes.removeAll()
                    }
                    break
                default:
                    print("No options found for \(response)")
                }
            }
        }else{
            print("Error on didUpdateValue for characteristic \(characteristic.uuid.uuidString)")
            print(error)
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didWriteValueFor \(characteristic.uuid.uuidString)")
        
        if(error != nil){
            print("Error")
            print(error!)
        }else{
            
            if characteristic.uuid == Constants.SUREFI_CMD_WRITE_UUID {
                //print("2")
                //print("currentCommand \(chat_vc.currentCommand)")
                if(chat_vc.currentCommand == "send_chat"){
                  //  print("3")
                    if(chat_vc.chatBigPackage){
                    //    print("4")
                        chat_vc.sendBigPackage()
                    }else{ // normal package with 20 or less bytes
                      //  print("5")
                        if(chat_vc.chatSendingNormalPackage){
                        //    print("6")
                            chat_vc.finishChatMessage()
                        }else{
                          //  print("7")
                            chat_vc.sendNormalPackage() // it set chatSendingNormalPackage to true and write the bytes
                        }
                    }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,didDiscoverCharacteristicsFor service: CBService,error: Error?) {
        print("didDiscoverCharacteristicsFor()")
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            switch(thisCharacteristic.uuid){
            case Constants.SUREFI_RX_UID_UUID:
                //print("Initializate Constants.SUREFI_RX_UID_UUID")
                self.SUREFI_RX_UID_UUID = thisCharacteristic
            //peripheral.setNotifyValue(true,for: thisCharacteristic)
            case Constants.SUREFI_TX_UID_UUID:
                //print("Initializate Constants.SUREFI_TX_UID_UUID")
                self.SUREFI_TX_UID_UUID = thisCharacteristic
            //peripheral.setNotifyValue(true,for: thisCharacteristic)
            case Constants.SUREFI_STATUS_UUID:
                //print("Initializate Constants.SUREFI_STATUS_UUID")
                self.SUREFI_STATUS_UUID = thisCharacteristic
            //peripheral.setNotifyValue(true,for: thisCharacteristic)
            case Constants.SUREFI_SEC_HASH_UUID:
                //print("Initializate Constants.SUREFI_SEC_HASH_UUID")
                self.SUREFI_SEC_HASH_UUID = thisCharacteristic
            case Constants.SUREFI_CMD_WRITE_UUID:
                print("Initializate Constants.SUREFI_CMD_WRITE_UUID")
                self.SUREFI_CMD_WRITE_UUID = thisCharacteristic
            //****peripheral.setNotifyValue(true,for: thisCharacteristic)
            case Constants.SUREFI_CMD_READ_UUID:
                //print("Initializate Constants.SUREFI_CMD_READ_UUID")
                self.SUREFI_CMD_READ_UUID = thisCharacteristic
                peripheral.setNotifyValue(true,for: thisCharacteristic)
            default:
                print("Characteristich don't find it \(thisCharacteristic.uuid.uuidString)")
            }
            if(thisCharacteristic.uuid == Constants.SUREFI_SEC_HASH_UUID){
                writeSecurityHash(peripherial: peripheral,characteristic: thisCharacteristic)
            }
        }
    }
    
    func parseMfgString(mfgString: String) -> Array<String>{
        
        let str = mfgString
        let mfgDeviceType   = str.cutStringOnRange(from: 4, to: 5)
        let mfgDeviceStatus = str.cutStringOnRange(from: 10, to: 11)
        let mfgDeviceID     = str.cutStringOnRange(from: 12, to: 17)
        let mfgPairedID     = str.cutStringOnRange(from: 18, to: 23)
        
        return [mfgDeviceType, mfgDeviceStatus, mfgDeviceID ,mfgPairedID]
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        let uuid = peripheral.identifier.uuidString
        var manufacturerString = ""
        let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as! Data
        manufacturerString = manufacturerData.hexStringFromData()
        var info_string = parseMfgString(mfgString: manufacturerString)
        peripheral.device_id = info_string[2]
        peripheral.advertisement_state = info_string[1]
        peripheral.paired_id = info_string[3]
        
        if (devices.index(where : {$0.identifier.uuidString ==  uuid}) == nil) {
            if(peripheral.name != nil){
                devices.append(peripheral)
            }
        }
    }
    
    func writeSecurityHash(peripherial: CBPeripheral,characteristic: CBCharacteristic){
        //print("writeSecurityHash")
        let securityHash = getSecurityHash(peripheral: peripherial)
        //print("SFBridgeController - Writing to Security Characteristic - \(securityHash)")
        peripherial.writeValue(securityHash, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        peripherial.bluetooth_connection = 1
    }
    
    func getSecurityHash(peripheral : CBPeripheral) -> Data {
        //print("getSecurityHash")
        let peripheralRXUUID = peripheral.device_id!
        let peripheralTXUUID = peripheral.paired_id!
        let string = "\(String(peripheralRXUUID.uppercased().characters.reversed()))\(peripheralTXUUID.uppercased())x~sW5-C\"6fu>!!~X"
        //print(string)
        let data = string.getMD5()
        return data
    }
    
    func loadDevices() -> [Device]! {
        print("loadDevices()")
        let path = Device.ArchiveURL.path
        return NSKeyedUnarchiver.unarchiveObject(withFile: path) as? [Device]
    }
    
    func saveDevices(devices:[Device]) -> Bool{
        print("saveDevices()")
        return NSKeyedArchiver.archiveRootObject(devices, toFile: Device.ArchiveURL.path)
    }
    
    private func checkForDeviceOnMemory(device: CBPeripheral,devices: [Device]) -> Bool{
        print("checkForDeviceOnMemory()")
        if devices.count > 0{
            for list_device in devices {
                if(list_device.device_id.uppercased() == device.device_id.uppercased()){
                    return true
                }
            }
        }
        return false
    }
    
    private func createNewDevice(device: CBPeripheral) -> Device {
        
        let new_device = Device(
            id: device.identifier.uuidString,
            name: device.name,
            device_id: device.device_id,
            advertisement_state: device.advertisement_state,
            paired_id: device.paired_id,
            bluetooth_connection: 1
        )
        
        return new_device
    }
    
    private func callSaveDevices(devices: [Device],new_device: Device){
        var new_devices = devices
        new_devices.append(new_device)
        
        if (saveDevices(devices: new_devices)){
            print("Device saved!")
        }else{
            print("Something was wrong while saved the device.")
        }
    }
    
    private func saveAndCreateDevicesFile(device: Device) -> Bool{
        print("saveAndCreateDeviceFile() \(device.device_id) ")
        var devices: [Device] = []
        devices.append(device)
        return NSKeyedArchiver.archiveRootObject(devices, toFile: Device.ArchiveURL.path)
    }
    
    func saveDeviceOnMemory(device: CBPeripheral){
        print("saveDeviceOnMemory()")
        let devices = loadDevices() // leets check if there are any file
        print("device_id - \(device.device_id)")
        let new_device =  createNewDevice(device: device)
        print("new_device - \(new_device.device_id)")
        
        if(devices != nil){
            print("devices: \(devices)")
            if(!checkForDeviceOnMemory(device: device, devices: devices!)){ //
                callSaveDevices(devices: devices!,new_device: new_device)
            }else{
                print("The device was previously saved.")
            }
        }else{
            print("there are not file saved")
            if(saveAndCreateDevicesFile(device: new_device)){
                print("The file has been created")
            }else{
                print("The file can't be created")
            }
        }
    }
}

