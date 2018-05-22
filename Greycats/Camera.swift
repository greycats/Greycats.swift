import AVFoundation
import UIKit

open class Camera {
    var session: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var stillCameraOutput: AVCaptureStillImageOutput!
    
    public init() {
        session = AVCaptureSession()
        stillCameraOutput = AVCaptureStillImageOutput()
        session.sessionPreset = AVCaptureSession.Preset.photo
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        if let input = backCameraInput() {
            if session.canAddInput(input) {
                session.addInput(input)
            }
        }
        if session.canAddOutput(stillCameraOutput) {
            session.addOutput(stillCameraOutput)
        }
    }
    
    fileprivate func backCameraDevice() -> AVCaptureDevice? {
        let availableCameraDevices = AVCaptureDevice.devices(for: AVMediaType.video)
        for device in availableCameraDevices {
            if device.position == .back {
                return device
            }
        }
        return nil
    }
    
    open func containerDidUpdate(_ container: UIView) {
        if previewLayer.superlayer == nil {
            container.layer.addSublayer(previewLayer)
        }
        UIView.setAnimationsEnabled(false)
        previewLayer.frame = container.bounds
        UIView.setAnimationsEnabled(true)
    }
    
    open func start() {
        foreground {
            self.checkPermission {[weak self] in
                self?.session.startRunning()
            }
        }
    }
    
    open func capture(_ next: @escaping (UIImage?) -> ()) {
        if let connection = stillCameraOutput.connection(with: AVMediaType.video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            stillCameraOutput.captureStillImageAsynchronously(from: connection) { (buffer, error) in
                self.stop()
                if let buffer = buffer {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                    let image = UIImage(data: imageData!)?.fixedOrientation()
                    foreground {
                        next(image)
                    }
                } else {
                    next(nil)
                }
            }
        } else {
            next(nil)
        }
    }
    
    open func stop() {
        session.stopRunning()
    }
    
    open func toggleFlash() -> AVCaptureDevice.FlashMode? {
        if let device = backCameraDevice() {
            do {
                try device.lockForConfiguration()
                if device.flashMode == .off {
                    device.flashMode = .on
                } else {
                    device.flashMode = .off
                }
                device.unlockForConfiguration()
            } catch {
            }
            return device.flashMode
        }
        return nil
    }
    
    fileprivate func backCameraInput() -> AVCaptureDeviceInput? {
        if let device = backCameraDevice() {
            return try? AVCaptureDeviceInput(device: device)
        }
        return nil
    }
    
    fileprivate func checkPermission(_ next: @escaping () -> ()) {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authorizationStatus {
        case .notDetermined:
            // permission dialog not yet presented, request authorization
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
                if granted {
                    foreground {
                        next()
                    }
                }
                else {
                    // user denied, nothing much to do
                }
            }
        case .authorized:
            next()
        case .denied, .restricted:
            // the user explicitly denied camera usage or is not allowed to access the camera devices
            return
        }
    }
}
