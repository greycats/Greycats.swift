//
//  Schedule.swift
//  Trusted
//
//  Created by Rex Sheng on 6/19/15.
//  Copyright (c) 2015 Trusted. All rights reserved.
//

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
		dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), interval, 0)
		dispatch_source_set_event_handler(timer) {
			if f == self.flag {
				closure { f == self.flag }
			}
		}
	}
}
