
import UIKit

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l >= r
    default:
        return !(lhs < rhs)
    }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l <= r
    default:
        return !(rhs < lhs)
    }
}


public protocol Animatable: class {
    func render(_ elapsedTime: TimeInterval) -> Bool
    func start()
    func stop()
}

class DisplayLink: NSObject {
    weak var animatable: Animatable?
    let end: (() -> Void)?
    
    var ended: Bool = false
    
    var lastDrawTime: CFTimeInterval = 0
    var displayLink: CADisplayLink?
    fileprivate var pausedTime: CFTimeInterval?
    fileprivate var bindAppStatus = false
    
    required init(animatable: Animatable, end: (() -> Void)? = nil) {
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
            end?()
            ended = true
        }
    }
    
    deinit {
        invalidate()
        if bindAppStatus {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    @objc func update() {
        guard let displayLink = displayLink else {
            return
        }
        guard let animatable = animatable else {
            invalidate()
            return
        }
        
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
    
    @objc func pause() {
        displayLink?.isPaused = true
        pausedTime = displayLink?.timestamp
    }
    
    @objc func resume() {
        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(update))
            displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
        }
        if !bindAppStatus {
            bindAppStatus = true
            NotificationCenter.default.addObserver(self, selector: #selector(resume), name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(pause), name: UIApplication.willResignActiveNotification, object: nil)
        }
        displayLink?.isPaused = false
    }
}

private var displayLinkKey: Void?
extension Animatable {
    
    public func start() {
        let displayLink = DisplayLink(animatable: self)
        objc_setAssociatedObject(self, &displayLinkKey, displayLink, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    public func stop() {
        objc_setAssociatedObject(self, &displayLinkKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

open class Animation {
    
    public enum Easing {
        case linear
        case quad
        case cubic
        case sin
        case cos
        case circle
        case exp
        case elastic(bounciness: Double)
    }
    
    public struct Value {
        let _value: (_ time: TimeInterval, _ easing: Easing) -> CGFloat
        
        public func value(_ time: TimeInterval, easing: Easing = .linear) -> CGFloat {
            return _value(time, easing)
        }
    }
    
    var displayLink: DisplayLink?
    
    public init() {
    }
    
    open func start(_ animatable: Animatable, end: (() -> Void)? = nil) {
        displayLink = DisplayLink(animatable: animatable, end: end)
    }
    
    open func stop() {
        displayLink = nil
    }
}

extension Animation.Easing {
    func calc(_ t: TimeInterval) -> TimeInterval {
        switch self {
        case .linear:
            return t
        case .quad:
            return t * t
        case .cubic:
            return t * t * t
        case .sin:
            return Foundation.sin(t * .pi / 2)
        case .cos:
            return Foundation.cos(t * .pi / 2)
        case .circle:
            return 1 - sqrt(1 - t * t)
        case .exp:
            return pow(2, 10 * (t - 1))
        case .elastic(let bounciness):
            let p = bounciness * .pi
            return 1 - pow(Foundation.cos(t * .pi / 2), 3) * Foundation.cos(t * p)
        }
    }
}

extension Animation.Value {
    public static func interpolate(inputRange: [TimeInterval], outputRange: [CGFloat]) -> Animation.Value {
        return Animation.Value(_value: { time, fn in
            if time >= inputRange.last {
                return outputRange.last!
            }
            if time <= inputRange.first {
                return outputRange.first!
            }
            
            var found: Int = 0
            for (index, input) in inputRange.enumerated() {
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
