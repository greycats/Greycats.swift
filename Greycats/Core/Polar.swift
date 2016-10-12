//
//  Polar.swift
//	Greycats
//
//  Created by Rex Sheng on 2/5/16.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.

import UIKit

public struct Polar {
    public let r: CGFloat
    public var θ: CGFloat
    
    public init(_ a: CGFloat, _ b: CGFloat) {
        r = sqrt(pow(a, 2) + pow(b, 2))
        θ = atan2(b, a)
    }
    
    public mutating func rotate(_ angle: CGFloat) {
        θ -= angle
    }
    
    public var x: CGFloat {
        return r * cos(θ)
    }
    
    public var y: CGFloat {
        return r * sin(θ)
    }
}
