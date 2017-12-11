//
//  ViewController.swift
//  YouTube Example
//
//  Created by Sean Allen on 4/28/17.
//  Copyright © 2017 Sean Allen. All rights reserved.
//

import UIKit
import SafariServices
import CoreBluetooth

class ChatViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var addMessageTextField: UITextField!
    
    var centralManager: CBCentralManager!
    var messages: [Message] = []
    var device : CBPeripheral!
    var chatCurrentPacket: Int = -1
    var chatCompleted: Bool = false
    var chatBigPackage: Bool  = false
    var chatTextBytes: [UInt8] = []
    var chatReceiveLength: Int = -1
    var chatReceiveBytes: [UInt8] = []
    var chatFileBytes: [UInt8] = []
    var chatFileSendByteCount: Int = 0
    var chatFileReceiveByteCount: Int = 0
    var chatFilePages: Int = 0
    var chatFileReceiving: Bool = false
    var chatPacketCount: Int = -1
    var selectedDeviceType: Int = -1
    var chatSendingNormalPackage: Bool = false
    var chatReceiveMessageLenght : Int!
    var chatReceiveMessage: String = ""
    var characteristic:CBCharacteristic!
    var currentCommand: String = ""
    var connect_timer:Timer!
    var connection_status_timer = Timer()
    var send_message_status: Int = 0 {
        didSet{
            if send_message_status == 1{
                
            }
        }
    }
    
    private func startConnectionStatusTimer(){
        connection_status_timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(checkConnectionStatus), userInfo: nil, repeats: true)
    }
    
    private func stopConnectionStatusTimer(){
        connection_status_timer.invalidate()
    }
    
    @objc private func checkConnectionStatus(){
        print("checkConnectionStatus()", device.bluetooth_connection)
        if(device.bluetooth_connection == 1){
            handleConnection()
        }
    }

    private func handleConnection(){
        print("handleConnection()")
        connect_timer.invalidate()
        stopConnectionStatusTimer()
    }
    
    var chatItems: [Double:NSMutableDictionary] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.send_message_status = btController.send_message_status
        startConnectionStatusTimer()
        btController.chat_vc = self
    }
    
    @IBAction func sendButton(_ sender: Any) {
        sendMessage()
    }
    
    func sendMessage() {
        
        let message = Message(message: addMessageTextField.text!, peripheral_id: device.device_id)
        
        drawMessage(message: message)
        sendChatMessage(textToSend: message.message)
    }
    
    func sendChatMessage(textToSend: String) {
        print("sendChatMessage()")
        chatCurrentPacket = 0
        chatTextBytes = [UInt8](textToSend.utf8)
        
        
        print("Byte Length:\(chatTextBytes.count) Packet Count:\(chatPacketCount)")
        var messageBytes: Data = Data([0x30]);
        
        let n = chatTextBytes.count
        var st = String(format:"%2X", n)
        st += " is the hexadecimal representation of \(n)"
        
        messageBytes.append(UInt8(n))
        print("Chat SFBridgeController - BLE Cmd:\(messageBytes.hexStringFromData())");
        
        currentCommand = "send_chat"
        
        if(chatTextBytes.count >= 19){
            chatBigPackage = true
        }else{
            chatBigPackage = false
        }
        
        if(device != nil){
            if(btController.SUREFI_CMD_WRITE_UUID != nil){
                device.writeValue(messageBytes, for: btController.SUREFI_CMD_WRITE_UUID, type: .withResponse);
            }else{
                print("Error: The characteristic on ChatViewController sendChatMessage() its empty.")
            }
        }else{
            print("Error: device is nil on ChatViewController - sendChatMessage()")
        }
    }

    func sendNormalPackage() {
        print("sendNormalPackage()")
        var messageBytes: Data = Data([0x31]);
        var index = 0
        let finalIndex = chatTextBytes.count
        
        while index < finalIndex{
            messageBytes.append(chatTextBytes[index])
            index += 1
        }
        
        chatSendingNormalPackage = true
        print("Chat SFBridgeController - BLE Cmd:\(messageBytes.hexStringFromData())");
        device.writeValue(messageBytes, for: btController.SUREFI_CMD_WRITE_UUID, type: .withResponse)
        chatTextBytes = []
    }
    
    func sendBigPackage(){
        var messageBytes: Data = Data([0x31])
        let size = chatTextBytes.count
        print("sendBigPackage() \(size) - Array: \(chatTextBytes)")
        if(size > 0){
            if(size > 19){
                let limit = size - 1
                let bytesToWrite: [UInt8] = Array ( chatTextBytes[0...18]) // 19 its the max size for the pages since we waste a space on the command  0x30
                
                print("bytesToWrite: \(bytesToWrite)")
                let newChatTextBytes: [UInt8] = Array( chatTextBytes[19...limit] )
                
                print("newChatTextBytes: \(newChatTextBytes)")
                messageBytes = appendBytes(bytes: messageBytes, chatTextBytes: bytesToWrite)
                
                print("messageBytes: \(messageBytes)")
                chatTextBytes = newChatTextBytes
            }else{
                if chatTextBytes.count > 0{
                    chatBigPackage = false
                    sendNormalPackage()
                }
            }
            print("Chat SFBridgeController - BLE Cmd:\(messageBytes.hexStringFromData())");
            device.writeValue(messageBytes, for: btController.SUREFI_CMD_WRITE_UUID, type: .withResponse)
        }
    }
    
    func appendBytes(bytes: Data,chatTextBytes: [UInt8]) -> Data{
        var index = 0
        var new_bytes : Data = bytes
        while(index < chatTextBytes.count){
            new_bytes.append(chatTextBytes[index])
            index += 1
        }
        return new_bytes
    }
   
    func finishChatMessage() {
        print("finishChatMessage()")
        let messageBytes: Data = Data([0x32]);
        print("Chat SFBridgeController - BLE Cmd:\(messageBytes.hexStringFromData())");
        currentCommand = ""
        chatSendingNormalPackage = false
        device.writeValue(messageBytes, for: btController.SUREFI_CMD_WRITE_UUID, type: .withResponse);
        //Util.setTimeOut(function:anotherFunction , time: 2)
    }
    
    func drawMessage(message: Message){
        
        if addMessageTextField.text!.isEmpty {
            print("Add Video Text Field is empty")
        }
        
        messages.append(message)
        
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        
        tableView.beginUpdates()
        tableView.insertRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
        
        addMessageTextField.text = ""
        view.endEditing(true)
    }
    
    func drawReceiveMessage(){
        
        print("drawReceiveMessage() \(chatReceiveMessage)")
        
        let message = Message(message: chatReceiveMessage, peripheral_id: "0")

        chatReceiveMessage = ""
        chatReceiveMessageLenght = 0

        
        if addMessageTextField.text!.isEmpty {
            print("Add Video Text Field is empty")
        }
        messages.append(message)
        
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        
        tableView.beginUpdates()
        tableView.insertRows(at: [indexPath], with: .automatic)
        tableView.endUpdates()
        
        addMessageTextField.text = ""
        view.endEditing(true)
    }
    
   
    func finishMessageSending(){
        print("finishMessageSending()")

        let messageBytes: Data = Data([0x32])
        print("Chat SFBridgeController - BLE Cmd:\(messageBytes.hexStringFromData())");
        device.writeValue(messageBytes, for: btController.SUREFI_CMD_WRITE_UUID, type: .withResponse)
    }
    
    func recieveMessage(){
    
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("didWriteValueFor on ChatViewController  \(characteristic.uuid.uuidString)")
        if characteristic.uuid == Constants.SUREFI_CMD_WRITE_UUID {
            print("Ahuevo")
        }
    }
    
    func saveChatItems() {
        
        let chats: NSMutableArray = NSMutableArray()
        
        for (timestamp,chatItem) in chatItems {
            let chat = NSMutableDictionary()
            chat.setValue(timestamp, forKey: "timestamp")
            chat.setValue(chatItem, forKey: "chat")
            chats.add(chat)
        }
        let documentsDirectory =  try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fileUrl = documentsDirectory.appendingPathComponent("chats.txt")
        if chats.write(to: fileUrl as URL, atomically: true) {
            print("Chats saved")
        } else {
            print("Chats NOT saved")
        }
    }
}


extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message = messages[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell") as! MessageCell
        let other_cell = tableView.dequeueReusableCell(withIdentifier: "OtherGuyMessageCell") as! OtherGuyMessageCell
        
        cell.message_title.layer.cornerRadius = 5
        cell.message_title.layer.borderColor = UIColor.init(red:66/255.0, green:134/255.0, blue:244/255.0, alpha: 1.0).cgColor

        cell.message_title.text = message.message
        other_cell.otherGuyMessageTitle.text = message.message
        
        return cell
    }
}
