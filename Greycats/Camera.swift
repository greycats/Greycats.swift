import AVFoundation
import UIKit

public class Camera {
	var session: AVCaptureSession!
	var previewLayer: AVCaptureVideoPreviewLayer!
	var stillCameraOutput: AVCaptureStillImageOutput!

	public init() {
		session = AVCaptureSession()
		stillCameraOutput = AVCaptureStillImageOutput()
		session.sessionPreset = AVCaptureSessionPresetPhoto
		previewLayer = AVCaptureVideoPreviewLayer(session: session)
		previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
		if let input = backCameraInput() {
			if session.canAddInput(input) {
				session.addInput(input)
			}
		}
		if session.canAddOutput(stillCameraOutput) {
			session.addOutput(stillCameraOutput)
		}
	}

	private func backCameraDevice() -> AVCaptureDevice? {
		let availableCameraDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
		for device in availableCameraDevices as! [AVCaptureDevice] {
			if device.position == .Back {
				return device
			}
		}
		return nil
	}

	public func containerDidUpdate(container: UIView) {
		if previewLayer.superlayer == nil {
			container.layer.addSublayer(previewLayer)
		}
		UIView.setAnimationsEnabled(false)
		previewLayer.frame = container.bounds
		UIView.setAnimationsEnabled(true)
	}

	public func start() {
		foreground {
			self.checkPermission {[weak self] in
				self?.session.startRunning()
			}
		}
	}

	public func capture(next: (UIImage?) -> ()) {
		if let connection = stillCameraOutput.connectionWithMediaType(AVMediaTypeVideo) {
			if connection.supportsVideoOrientation {
				connection.videoOrientation = .Portrait
			}
			stillCameraOutput.captureStillImageAsynchronouslyFromConnection(connection) { (buffer, error) in
				self.stop()
				if let buffer = buffer {
					let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
					let image = UIImage(data: imageData)?.fixedOrientation()
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

	public func stop() {
		session.stopRunning()
	}

	public func toggleFlash() {
		if let device = backCameraDevice() {
			do {
				try device.lockForConfiguration()
				if device.flashMode == .Off {
					device.flashMode = .On
				} else {
					device.flashMode = .Off
				}
				device.unlockForConfiguration()
			} catch {
			}
		}
	}

	private func backCameraInput() -> AVCaptureDeviceInput? {
		if let device = backCameraDevice() {
			return try? AVCaptureDeviceInput(device: device)
		}
		return nil
	}

	private func checkPermission(next: () -> ()) {
		let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
		switch authorizationStatus {
		case .NotDetermined:
			// permission dialog not yet presented, request authorization
			AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo) { granted in
				if granted {
					foreground {
						next()
					}
				}
				else {
					// user denied, nothing much to do
				}
			}
		case .Authorized:
			next()
		case .Denied, .Restricted:
			// the user explicitly denied camera usage or is not allowed to access the camera devices
			return
		}
	}
}
