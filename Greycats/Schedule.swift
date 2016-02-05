//
//  Schedule.swift
//	Greycats
//
//  Created by Rex Sheng on 6/19/15.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//

public func dispatch_time_in(delay: NSTimeInterval) -> dispatch_time_t {
	return dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
}

public typealias Task = (cancel : Bool) -> ()
public func delay(delay: NSTimeInterval, closure: dispatch_block_t) -> Task? {
	var task: dispatch_block_t? = closure
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
	dispatch_after(dispatch_time_in(delay), dispatch_get_main_queue()) {
		result?(cancel: false)
	}
	return result
}
public func cancel(task: Task?) {
	task?(cancel: true)
}

public func background(closure: dispatch_block_t) {
	dispatch_async(dispatch_get_global_queue(0, 0), closure)
}

public func foreground(closure: dispatch_block_t) {
	dispatch_async(dispatch_get_main_queue(), closure)
}

public struct Schedule {
	private let timer: dispatch_source_t = {
		let timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue())
		dispatch_resume(timer)
		return timer
		}()
	
	private var interval = DISPATCH_TIME_FOREVER
	private var delay: NSTimeInterval = 0.25
	
	public init(interval: NSTimeInterval = 0, delay: NSTimeInterval = 0.25) {
		self.delay = delay
		if interval > 0 {
			self.interval = UInt64(interval * Double(NSEC_PER_SEC))
		}
	}
	
	public func cancel() {
		dispatch_source_cancel(timer)
	}
	private var flag: UInt8 = 0
	
	mutating public func schedule(closure: (check: () -> Bool) -> ()) {
		flag++
		if flag > 250 {
			flag = 0
		}
		let f = flag
		dispatch_source_set_timer(timer, dispatch_time_in(delay), interval, 0)
		dispatch_source_set_event_handler(timer) {
			if f == self.flag {
				closure { f == self.flag }
			}
		}
	}
}

private var labelTimer: Void?
extension UILabel {
	public func keepUpdating(time: NSTimeInterval, closure: (NSTimeInterval) -> (String)) {
		let timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue())
		dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, NSEC_PER_SEC, 0)
		objc_setAssociatedObject(self, &labelTimer, timer, .OBJC_ASSOCIATION_RETAIN)
		dispatch_source_set_event_handler(timer) {[weak self] in
			self?.text = closure(time - NSDate.timeIntervalSinceReferenceDate())
		}
		dispatch_resume(timer)
	}
}