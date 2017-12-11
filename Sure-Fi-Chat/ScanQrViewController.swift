//
//  ScanQrViewController.swift
//  Sure-Fi-Chat
//
//  Created by Sure-Fi Inc. on 12/5/17.
//  Copyright © 2017 Sure-Fi Inc. All rights reserved.
//

import UIKit
import AVFoundation
import CoreBluetooth

class ScanQrViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet var scannerView: UIView!
    @IBOutlet var scannerImageView: UIImageView!
    
    var foundedDevice: CBPeripheral!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var timer = Timer()
    var connect_timer = Timer()
    var connection_status_timer = Timer()
    var scannedDeviceID: String!
    var manualEntry: Bool = false
    var captureSession: AVCaptureSession!
    var sessionOutput: AVCapturePhotoOutput!
    var sessionOutputSetting = AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecType.jpeg])
    var previewLayer: AVCaptureVideoPreviewLayer!
    var cameraDevice: AVCaptureDevice!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Scan QR Code"
    }

    @objc func tryToConnect(){
        btController.centralManager.connect(foundedDevice)
    }
    
    private func startConnectTimer() {
        connect_timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ScanQrViewController.tryToConnect), userInfo: nil, repeats: true)
    }

    private func stopConnectTimer(){
        connect_timer.invalidate()
    }
    
    private func startTimer(){
        print("startTimer()")
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(ScanQrViewController.checkForDevices), userInfo: nil, repeats: true)
    }
    
    private func stopTimer(){
        print("stopTimer()")
        timer.invalidate()
    }
    
    private func startConnectionStatusTimer(){
        connection_status_timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(ScanQrViewController.checkConnectionStatus), userInfo: nil, repeats: true)
    }
    
    private func stopConnectionStatusTimer(){
        connection_status_timer.invalidate()
    }
    
    private func handleConnection(){
        print("handleConnection()")
        stopConnectTimer()
        stopTimer()
        stopConnectionStatusTimer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        captureSession = AVCaptureSession()
        sessionOutput = AVCapturePhotoOutput()
        previewLayer = AVCaptureVideoPreviewLayer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let scannerViewFrame = CGRect(x: scannerView.frame.origin.x - 1, y: scannerView.frame.origin.y - 1, width: scannerView.frame.size.width + 2, height: scannerView.frame.size.width + 2)
        
        scannerView.frame = scannerViewFrame
        scannerView.clipsToBounds = true
        scannerView.isHidden = false
        scannerImageView.frame = scannerViewFrame
        scannerImageView.layer.borderColor = UIColor.gray.cgColor
        scannerImageView.layer.borderWidth = 1
        scannerImageView.clipsToBounds = true
        scannerImageView.isHidden = false
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInTelephotoCamera,AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
     
        for device in (deviceDiscoverySession.devices) {
            if(device.position == AVCaptureDevice.Position.back){
                do{
                    if device.isFocusModeSupported(.continuousAutoFocus) {
                        try! device.lockForConfiguration()
                        device.focusMode = .continuousAutoFocus
                        device.unlockForConfiguration()
                    }
                    
                    let input = try AVCaptureDeviceInput(device: device)
                    if(captureSession.canAddInput(input)){
                        captureSession.addInput(input);
                        
                        let captureMetadataOutput = AVCaptureMetadataOutput()
                        captureSession.addOutput(captureMetadataOutput)
                        
                        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                        captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
                        
                        if(captureSession.canAddOutput(sessionOutput)){
                            captureSession.addOutput(sessionOutput);
                            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession);
                            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill;
                            previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait;
                            scannerView.layer.addSublayer(previewLayer);
                            previewLayer.frame = scannerView.bounds
                            captureSession.startRunning()
                        }
                    }
                }
                catch{
                    print("exception!");
                }
            }
        }
    }
    

    @objc private func checkForDevices(){
        print("checkForDevices() \(String(btController.devices.count) )")
        if btController.devices.count > 0 {
            
        }
    }
    
    private func compareDevices(device_1: CBPeripheral,device_2: CBPeripheral) -> Bool{
        print("compareDevices()")
        if(device_1.device_id == device_2.device_id){
            return true
        }
        return false
    }
    
    @objc private func checkConnectionStatus(){
        print("checkConnectionStatus()", foundedDevice.bluetooth_connection)
        if(foundedDevice.bluetooth_connection == 1){
            handleConnection()
        }
    }
    
    private func goToChatViewController(device: CBPeripheral){
        print("goToChatViewController()")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        
        controller.device = device
        controller.centralManager = btController.centralManager
        
        self.navigationController?.popViewController(animated: true)
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection){
        //print("metadataOutput()")
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if(foundedDevice == nil){

            if  metadataObjects.count == 0 {
                print("No QR code is detected")
                return
            }
            
            // Get the metadata object.
            let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            scannedDeviceID = metadataObj.stringValue!
            if scannedDeviceID.uppercased().range(of: "HTTPS://ADMIN.SURE-FI.COM") != nil {
                scannedDeviceID = scannedDeviceID.cutStringOnRange(from: 45, to: scannedDeviceID.count - 1)
            }
            
            if scannedDeviceID != nil {
                for device in btController.devices{
                    if(device.device_id.uppercased() == scannedDeviceID.uppercased()){
                        print(" \(device.device_id.uppercased() ) - \(scannedDeviceID.uppercased())")
                        foundedDevice = device
                        startConnectTimer()
                        startConnectionStatusTimer()
                        goToChatViewController(device:device)
                        print("founded_device \(foundedDevice.device_id)")
                        btController.saveDeviceOnMemory(device: foundedDevice)
                    }
                }
            }
        }
    }
}
