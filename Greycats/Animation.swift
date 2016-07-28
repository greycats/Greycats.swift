import UIKit

public class Animation: NSObject {
	var lastDrawTime: CFTimeInterval = 0
	var displayLink: CADisplayLink?

	public func start(closure: NSTimeInterval -> ()) {
		self.closure = closure
		if let displayLink = displayLink {
			displayLink.invalidate()
			lastDrawTime = 0
		}
		displayLink = CADisplayLink(target: self, selector: #selector(update))
		displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
	}

	deinit {
		stop()
	}

	public func stop() {
		if let displayLink = displayLink {
			displayLink.invalidate()
		}
		displayLink = nil
	}

	var closure: ((elapsedTime: NSTimeInterval) -> ())!

	func update() {
		if let displayLink = displayLink {
			if lastDrawTime == 0 {
				lastDrawTime = displayLink.timestamp
			}
			let elapsedTime = displayLink.timestamp - lastDrawTime
			closure(elapsedTime: elapsedTime)
		}
	}
}

public enum Easing {
	case Linear
	case Quad
	case Cubic
	case Sin
	case Cos
	case Circle
	case Exp
	case Elastic(bounciness: Double)

	func calc(t: NSTimeInterval) -> NSTimeInterval {
		switch self {
		case .Linear:
			return t
		case .Quad:
			return t * t
		case .Cubic:
			return t * t * t
		case .Sin:
			return sin(t * M_PI / 2)
		case .Cos:
			return cos(t * M_PI / 2)
		case .Circle:
			return 1 - sqrt(1 - t * t)
		case .Exp:
			return pow(2, 10 * (t - 1))
		case .Elastic(let bounciness):
			let p = bounciness * M_PI
			return 1 - pow(cos(t * M_PI / 2), 3) * cos(t * p)
		}
	}
}

public struct AnimationValue {

	var _timingFunction: (NSTimeInterval, Easing) -> CGFloat

	public static func interpolate(inputRange inputRange: [NSTimeInterval], outputRange: [CGFloat]) -> AnimationValue {
		return AnimationValue(_timingFunction: { time, fn in
			if time >= inputRange.last {
				return outputRange.last!
			}
			if time <= inputRange.first {
				return outputRange.first!
			}

			var found: Int = 0
			for (index, input) in inputRange.enumerate() {
				if time >= input {
					found = index
				} else {
					break
				}
			}
			let a = inputRange[found], b = inputRange[found + 1], c = outputRange[found], d = outputRange[found + 1]
			let t = (time - a) / (b - a)
			let f = fn.calc(t)
			return CGFloat(f) * (d - c) + c
		})
	}

	public func currentValue(time: NSTimeInterval, easing: Easing = .Linear) -> CGFloat {
		return _timingFunction(time, easing)
	}
}