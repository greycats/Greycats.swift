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

@available(*, deprecated=2.9, message="Use Graphic directly")
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

public protocol GraphicDesignable {
    var graphicClass: String? { get set }
    var graphic: Graphic? { get }
}

extension GraphicDesignable {
    public var graphic: Graphic? {
        if let value = graphicClass,
            let instance = NSClassFromString(value) as? Graphic.Type {
            return instance.init()
        }
        return nil
    }
}

@IBDesignable
public class GraphicButton: UIButton, GraphicDesignable {
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
        if let graphic = self.graphic {
            if let image = graphic.image(true, tintColor: tintColor) {
                setImage(UIImage(CGImage: image, scale: UIScreen.mainScreen().scale, orientation: .Up), forState: .Selected)
            }
            if let image = graphic.image(false, tintColor: tintColor) {
                setImage(UIImage(CGImage: image, scale: UIScreen.mainScreen().scale, orientation: .Up), forState: .Normal)
            }
        }
    }
}

public protocol HasDefaultGraphic: class {
    func defaultTintColor() -> UIColor?
    var image: UIImage? { get set }
}

extension HasDefaultGraphic where Self: GraphicDesignable {
    private func setImageToGraphic() {
        if let graphic = self.graphic {
            if let image = graphic.image(false, tintColor: defaultTintColor() ?? UIColor.whiteColor()) {
                self.image = UIImage(CGImage: image, scale: UIScreen.mainScreen().scale, orientation: .Up)
            }
        }
    }
}

@IBDesignable
public class GraphicBarButtonItem: UIBarButtonItem, HasDefaultGraphic, GraphicDesignable {
    @IBInspectable public var graphicClass: String? {
        didSet {
            setImageToGraphic()
        }
    }
    
    public func defaultTintColor() -> UIColor? {
        return tintColor
    }
}

@IBDesignable
public class GraphicImageView: UIImageView, HasDefaultGraphic, GraphicDesignable {
    @IBInspectable public var graphicClass: String? {
        didSet {
            setImageToGraphic()
        }
    }
    
    public func defaultTintColor() -> UIColor? {
        return tintColor
    }
}
