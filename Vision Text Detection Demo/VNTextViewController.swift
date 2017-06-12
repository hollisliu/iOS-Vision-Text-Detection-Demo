//
//  ViewController.swift
//  Vision Text Detection Demo
//
//  Created by Hanjie Liu on 6/12/17.
//  Copyright © 2017 Hanjie Liu. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class VNTextViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var requests = [VNRequest]()
    private let session = AVCaptureSession()
    
    @IBOutlet weak var previewView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
        setupVision()
    }
    
    // MARK: - Vision Setup
    func setupVision() {
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.textDetectionHandler)
        textRequest.reportCharacterBoxes = true
        
        self.requests = [textRequest]
    }
    
    func textDetectionHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results else {print("no result"); return}
        
        let result = observations.map({$0 as? VNTextObservation})
        
        DispatchQueue.main.async() {
            self.previewView.layer.sublayers?.removeSubrange(1...)
            for region in result {
                guard let rg = region else {continue}
                self.drawRegionBox(box: rg)
                if let boxes = region?.characterBoxes {
                    for characterBox in boxes {
                        self.drawTextBox(box: characterBox)
                    }
                }
            }
        }
    }
    
    // MARK: - Draw
    func drawRegionBox(box: VNTextObservation) {
        guard let boxes = box.characterBoxes else {return}
        var xMin: CGFloat = 9999.0
        var xMax: CGFloat = 0.0
        var yMin: CGFloat = 9999.0
        var yMax: CGFloat = 0.0
        
        for char in boxes {
            if char.bottomLeft.x < xMin {xMin = char.bottomLeft.x}
            if char.bottomRight.x > xMax {xMax = char.bottomRight.x}
            if char.bottomRight.y < yMin {yMin = char.bottomRight.y}
            if char.topRight.y > yMax {yMax = char.topRight.y}
        }
        
        let xCoord = xMin * previewView.frame.size.width
        let yCoord = (1 - yMax) * previewView.frame.size.height
        let width = (xMax - xMin) * previewView.frame.size.width
        let height = (yMax - yMin) * previewView.frame.size.height
        
        let layer = CALayer()
        layer.frame = CGRect(x: xCoord, y: yCoord, width: width, height: height)
        layer.borderWidth = 2.0
        layer.borderColor = UIColor.green.cgColor
        
        previewView.layer.addSublayer(layer)
    }
    
    func drawTextBox(box: VNRectangleObservation) {
        let xCoord = box.topLeft.x * previewView.frame.size.width
        let yCoord = (1 - box.topLeft.y) * previewView.frame.size.height
        let width = (box.topRight.x - box.bottomLeft.x) * previewView.frame.size.width
        let height = (box.topLeft.y - box.bottomLeft.y) * previewView.frame.size.height
        
        let layer = CALayer()
        layer.frame = CGRect(x: xCoord, y: yCoord, width: width, height: height)
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.blue.cgColor
        
        previewView.layer.addSublayer(layer)
    }
    
    
    // MARK: - Camera Delegate and Setup
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: 6, options: requestOptions)
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    func setupCamera() {
        let availableCameraDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        
        var activeDevice: AVCaptureDevice?
        
        for device in availableCameraDevices.devices as [AVCaptureDevice]{
            if device.position == .back {
                activeDevice = device
                break
            }
        }
        
        do {
            let camInput = try AVCaptureDeviceInput(device: activeDevice!)
            
            if session.canAddInput(camInput) {
                session.addInput(camInput)
            }
        } catch {
            print("no camera")
        }
        
        guard auth() else {return}
        
        let videoOutput = AVCaptureVideoDataOutput()
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "buffer queue", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil))
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        previewLayer.frame = previewView.bounds
        previewView.layer.addSublayer(previewLayer)
        
        session.startRunning()
    }
    
    private func auth() -> Bool{
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video,
                                          completionHandler: { (granted:Bool) -> Void in
                                            if granted {
                                                DispatchQueue.main.async {
                                                    self.previewView.setNeedsDisplay()
                                                }
                                            }
            })
           return true
        case .authorized:
            return true
        case .denied, .restricted: return false
        }
    }
    
}

