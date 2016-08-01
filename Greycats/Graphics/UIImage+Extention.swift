import UIKit
import ImageIO

extension UIImage {
	public func resize(maxPixel: Int) -> UIImage? {
		if let imageSource = CGImageSourceCreateWithData(UIImageJPEGRepresentation(self, 1)!, nil) {
			let options: [NSString: NSObject] = [
				kCGImageSourceThumbnailMaxPixelSize: maxPixel,
				kCGImageSourceCreateThumbnailFromImageAlways: true,
				]

			return CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options).flatMap { UIImage(CGImage: $0) }
		}
		return nil
	}

	public func fixedOrientation() -> UIImage {

		if imageOrientation == .Up {
			return self
		}

		var transform = CGAffineTransformIdentity

		switch imageOrientation {
		case .Down, .DownMirrored:
			transform = CGAffineTransformTranslate(transform, size.width, size.height)
			transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
			break
		case .Left, .LeftMirrored:
			transform = CGAffineTransformTranslate(transform, size.width, 0)
			transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
			break
		case .Right, .RightMirrored:
			transform = CGAffineTransformTranslate(transform, 0, size.height)
			transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))
			break
		case .Up, .UpMirrored:
			break
		}

		switch imageOrientation {
		case .UpMirrored, .DownMirrored:
			CGAffineTransformTranslate(transform, size.width, 0)
			CGAffineTransformScale(transform, -1, 1)
			break
		case .LeftMirrored, .RightMirrored:
			CGAffineTransformTranslate(transform, size.height, 0)
			CGAffineTransformScale(transform, -1, 1)
		case .Up, .Down, .Left, .Right:
			break
		}

		let ctx = CGBitmapContextCreate(nil, Int(size.width), Int(size.height), CGImageGetBitsPerComponent(CGImage), 0, CGImageGetColorSpace(CGImage), CGImageAlphaInfo.PremultipliedLast.rawValue)!

		CGContextConcatCTM(ctx, transform)

		switch imageOrientation {
		case .Left, .LeftMirrored, .Right, .RightMirrored:
			CGContextDrawImage(ctx, CGRectMake(0, 0, size.height, size.width), CGImage)
			break
		default:
			CGContextDrawImage(ctx, CGRectMake(0, 0, size.width, size.height), CGImage)
			break
		}

		let cgImage = CGBitmapContextCreateImage(ctx)!

		return UIImage(CGImage: cgImage)
	}
}