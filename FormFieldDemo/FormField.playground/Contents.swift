//: Playground - noun: a place where people can play

import FormFieldDemo
import XCPlayground
import UIKit

let view = Fields(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
view.backgroundColor = .whiteColor()
XCPlaygroundPage.currentPage.liveView = view
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
view
