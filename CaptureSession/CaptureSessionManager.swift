//
//  CaptureSessionManager.swift
//  ARMakunouchi
//
//  Created by Riku Yamane on 2017/06/11.
//  Copyright © 2017年 Riku Yamane. All rights reserved.
//

import UIKit
import AVFoundation

public protocol UmeDataSource: class {
    func umeImageData() -> (image: UIImage, rect: CGRect)
}
open class CaptureSessionManager: NSObject, AVCapturePhotoCaptureDelegate {
    // MARK: - public properties
    public static let shared:CaptureSessionManager = CaptureSessionManager()
    public var previewLayer:AVCaptureVideoPreviewLayer?
    
    // MARK: - private properties
    private let captureSession:AVCaptureSession
    private var capturePhotoOutput:AVCapturePhotoOutput!
    private var captureFrame:CGRect!
    
    public weak var dataSource: UmeDataSource?
    
    override private init(){
        captureSession = AVCaptureSession()
        super.init()
    }
    
    
    /// 権限チェック
    ///
    /// - Returns: 許可=ture / それ以外=false
    public func checkAuthority() -> (Bool) {
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        if status == .authorized {
            return true
        }
        return false
    }
    
    
    /// 初期化を行う
    ///
    /// - Parameter frame: キャプチャするフレーム
    public func setup(frame:CGRect) {
        guard let devices = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaTypeVideo, position: .back).devices else {
            return
        }

        let videoIn = try? AVCaptureDeviceInput(device:devices.first)
        
        if let videoIn = videoIn {
            if captureSession.canAddInput(videoIn) {
                captureFrame = frame
                
                captureSession.addInput(videoIn)
                capturePhotoOutput = AVCapturePhotoOutput()
                captureSession.addOutput(capturePhotoOutput)
                if captureSession.canSetSessionPreset(AVCaptureSessionPreset3840x2160) {
                    captureSession.sessionPreset = AVCaptureSessionPreset3840x2160
                }
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                previewLayer?.frame = frame
                previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                captureSession.startRunning()
            }
        }
    }

    fileprivate var captureCompletion:((_ error:Error?)->Void)!
    /// 画像取得
    public func takePhoto( complition:@escaping ((_ error:Error?)->Void) ){
        captureCompletion = complition
        let capturePhotoSettings = AVCapturePhotoSettings()
        if capturePhotoOutput.supportedFlashModes.contains(NSNumber(value: AVCaptureFlashMode.auto.rawValue)) {
            capturePhotoSettings.flashMode = .auto
        }
        
        capturePhotoSettings.isAutoStillImageStabilizationEnabled = true
        capturePhotoSettings.isHighResolutionPhotoEnabled = false
        capturePhotoOutput?.capturePhoto(with: capturePhotoSettings, delegate: self)
    }
    
    public func capture(_ captureOutput: AVCapturePhotoOutput,
                 didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?,
                 previewPhotoSampleBuffer: CMSampleBuffer?,
                 resolvedSettings: AVCaptureResolvedPhotoSettings,
                 bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        //
        if let error = error {
            captureCompletion(error)
        }
        
        // do something
        let photoData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer!, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
        let image = UIImage(data: photoData!)
        
        if let image = image, let dataSource = dataSource {
            let aspectFillingImage = image.aspectFillingImage(to: captureFrame.size)
            let umeData = dataSource.umeImageData()
            let compositImage = aspectFillingImage?.composit(image: umeData.image, rect: umeData.rect)
            UIImageWriteToSavedPhotosAlbum(compositImage!, nil, nil, nil)
            captureCompletion(nil)
        }
    }
}
