//
//  Util.swift
//  Sure-Fi-Chat
//
//  Created by Sure-Fi Inc. on 11/17/17.
//  Copyright © 2017 Sure-Fi Inc. All rights reserved.
//

import Foundation


class Util: NSObject {
    typealias GeneralFunction = ()  -> Void
    
    static func toByteArray<T>(_ value: T) -> [UInt8] {
        var value = value
        return withUnsafeBytes(of: &value) { Array($0) }
    }
    
    static func fromByteArray<T>(_ value: [UInt8], _: T.Type) -> T {
        return value.withUnsafeBytes {
            $0.baseAddress!.load(as: T.self)
        }
    }
    
    
    static func setTimeOut(function: @escaping GeneralFunction, time: Double){
        let when = DispatchTime.now() + time // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            function()
        }
    }
    
    static func getCurrentDateString() -> String{
        let date = Date()
        let calendar = Calendar.current
        let nano_seconds = calendar.component(.nanosecond, from: date)
        let seconds = calendar.component(.second, from: date)
        let minutes = calendar.component(.minute,from: date)
        let hour = calendar.component(.hour, from: date)
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
     
        return "\(year)/\(month)/\(day)/\(hour)/\(minutes)/\(seconds)/\(nano_seconds) "
    }
    
}

extension Data {
    func hexStringFromData() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
    func crc16() -> UInt16 {
        
        let byteArray = [UInt8](self)
        let crcController = CRC16()
        let crc = crcController.getCRCResult(data: byteArray)
        return crc;
    }
}

extension String {

    var drop0xPrefix:          String { return hasPrefix("0x") ? String(characters.dropFirst(2)) : self }
    var drop0bPrefix:          String { return hasPrefix("0b") ? String(characters.dropFirst(2)) : self }
    var hexaToDecimal:            Int { return Int(drop0xPrefix, radix: 16) ?? 0 }
    var hexaToBinaryString:    String { return String(hexaToDecimal, radix: 2) }
    var decimalToHexaString:   String { return String(Int(self) ?? 0, radix: 16) }
    var decimalToBinaryString: String { return String(Int(self) ?? 0, radix: 2) }
    var binaryToDecimal:          Int { return Int(drop0bPrefix, radix: 2) ?? 0 }
    var binaryToHexaString:    String { return String(binaryToDecimal, radix: 16) }

    
    func cutStringOnRange(from: Int,to: Int) -> String{
        var character_array = [Character]()
        var cut_string = ""
        
        if(from < 0){
            return "Error the from should be bigger as 0"
        }
    
        if(to > self.count){
            return "Error the to parameter should be smaller as String size"
        }
    
        if(from > to){
            return "Error the from parameter should be smaller as to parameter"
        }
        
        for character in self {
            character_array.append(character)
        }
        
        for index in from...to{
            cut_string.append(character_array[index])
        }
        
        return cut_string
    }
    
    func getMD5() -> Data {
        let messageData = self.data(using:.utf8)!
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        
        return digestData
    }
    
    
    
    func dataFromHexString() -> NSData? {
        guard let chars = cString(using: String.Encoding.utf8) else { return nil}
        var i = 0
        let length = characters.count
        
        let data = NSMutableData(capacity: length/2)
        var byteChars: [CChar] = [0, 0, 0]
        
        var wholeByte: CUnsignedLong = 0
        
        while i < length {
            byteChars[0] = chars[i]
            i+=1
            byteChars[1] = chars[i]
            i+=1
            wholeByte = strtoul(byteChars, nil, 16)
            data?.append(&wholeByte, length: 1)
        }
        
        return data
    }
}
