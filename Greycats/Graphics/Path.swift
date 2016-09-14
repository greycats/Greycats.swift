//
//  Path.swift
//  Greycats
//
//  Created by Rex Sheng on 8/1/16.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//

// This is useful when you want to create a Button in IB, but also want to set the image part as a BezierPath.

import UIKit

public protocol Graphic {
    func image(selected: Bool, tintColor: UIColor) -> CGImage?
    init()
}

public protocol SVG: Graphic {
    var path: UIBezierPath { get }
}

extension SVG {
    public func image(selected: Bool, tintColor: UIColor) -> CGImage? {
        let size = path.bounds.size
        return CGImageRef.op(Int(ceil(size.width)), Int(ceil(size.height))) { context in
            CGContextSetFillColorWithColor(context!, tintColor.CGColor)
            CGContextAddPath(context!, path.CGPath)
            CGContextFillPath(context!)
        }
    }
}

@IBDesignable
public class GraphicButton: UIButton {
    @IBInspectable public var graphicClass: String? {
        didSet {
            setImageToGraphic()
        }
    }

    override public func tintColorDidChange() {
        super.tintColorDidChange()
        setImageToGraphic()
    }

    private func setImageToGraphic() {
        if let value = graphicClass,
            let graphic = NSClassFromString(value) as? Graphic.Type {
            let instance = graphic.init()
            if let image = instance.image(true, tintColor: tintColor) {
                setImage(UIImage(CGImage: image, scale: UIScreen.mainScreen().scale, orientation: .Up), forState: .Selected)
            }
            if let image = instance.image(false, tintColor: tintColor) {
                setImage(UIImage(CGImage: image, scale: UIScreen.mainScreen().scale, orientation: .Up), forState: .Normal)
            }
        }
    }
}
