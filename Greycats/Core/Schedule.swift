//
//  Schedule.swift
//	Greycats
//
//  Created by Rex Sheng on 6/19/15.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//

import Foundation

public typealias Task = (_ cancel : Bool) -> ()

@discardableResult
public func delay(_ delay: TimeInterval, closure: @escaping () -> Void) -> Task? {
    var task: (() -> Void)? = closure
    var result: Task?
    let delayedClosure: Task = { cancel in
        if let internalClosure = task {
            if cancel == false {
                foreground(internalClosure)
            }
        }
        task = nil
        result = nil
    }
    result = delayedClosure
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(Int(delay * 1000))) {
        result?(false)
    }
    return result
}

public func cancel(_ task: Task?) {
    task?(true)
}

public func background(_ closure: @escaping () -> Void) {
    DispatchQueue.global(qos: .background).async(execute: closure)
}

public func foreground(_ closure: @escaping () -> Void) {
    DispatchQueue.main.async(execute: closure)
}

public struct Schedule {
    fileprivate let timer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: UInt(0)), queue: DispatchQueue.main)
        timer.resume()
        return timer
    }()
    
    let interval: DispatchTimeInterval?
    let delay: DispatchTimeInterval
    
    public init(interval: DispatchTimeInterval?, delay: DispatchTimeInterval = .milliseconds(250)) {
        self.delay = delay
        self.interval = interval
    }
    
    public func cancel() {
        timer.cancel()
    }
    
    mutating public func schedule(_ closure: @escaping (_ check: () -> Bool) -> ()) {
        cancel()
        if let interval = interval {
            timer.schedule(deadline: DispatchTime.distantFuture, repeating: interval)
        } else {
            timer.schedule(deadline: DispatchTime.distantFuture)
        }
        timer.setEventHandler {
            closure { true }
        }
    }
}
