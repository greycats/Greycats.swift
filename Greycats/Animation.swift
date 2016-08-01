import UIKit

public protocol Animatable {
	func render(elapsedTime: NSTimeInterval) -> Bool
}

class DisplayLink: NSObject {
	let animatable: Animatable
	let end: () -> ()

	var ended: Bool = false

	var lastDrawTime: CFTimeInterval = 0
	var displayLink: CADisplayLink?
	private var pausedTime: CFTimeInterval?
	private var bindAppStatus = false

	required init(animatable: Animatable, end: () -> ()) {
		self.animatable = animatable
		self.end = end
		super.init()
		resume()
	}

	func invalidate() {
		displayLink?.invalidate()
		lastDrawTime = 0
		displayLink = nil
		if !ended {
			end()
			ended = true
		}
	}

	deinit {
		invalidate()
	}

	func update() {
		guard let displayLink = displayLink else { return }

		if lastDrawTime == 0 {
			lastDrawTime = displayLink.timestamp
		}
		if let time = pausedTime {
			lastDrawTime += displayLink.timestamp - time
			pausedTime = nil
		}
		let done = animatable.render(displayLink.timestamp - lastDrawTime)
		if done {
			invalidate()
		}
	}

	func pause() {
		displayLink?.paused = true
		pausedTime = displayLink?.timestamp
	}

	func resume() {
		if displayLink == nil {
			displayLink = CADisplayLink(target: self, selector: #selector(update))
			displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
		}
		if !bindAppStatus {
			bindAppStatus = true
			NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(resume), name: UIApplicationDidBecomeActiveNotification, object: nil)
			NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(pause), name: UIApplicationWillResignActiveNotification, object: nil)
		}
		displayLink?.paused = false
	}
}

public class Animation {

	public enum Easing {
		case Linear
		case Quad
		case Cubic
		case Sin
		case Cos
		case Circle
		case Exp
		case Elastic(bounciness: Double)
	}

	public struct Value {
		let _value: (time: NSTimeInterval, easing: Easing) -> CGFloat

		public func value(time: NSTimeInterval, easing: Easing = .Linear) -> CGFloat {
			return _value(time: time, easing: easing)
		}
	}

	var displayLink: DisplayLink?

	public init() {
	}

	public func start(animatable: Animatable, end: () -> ()) {
		displayLink = DisplayLink(animatable: animatable, end: end)
	}

	public func stop() {
		displayLink = nil
	}
}

extension Animation.Easing {
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

extension Animation.Value {
	public static func interpolate(inputRange inputRange: [NSTimeInterval], outputRange: [CGFloat]) -> Animation.Value {
		return Animation.Value(_value: { time, fn in
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
}
