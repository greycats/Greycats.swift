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
    func image(_ selected: Bool, tintColor: UIColor) -> CGImage?
    init()
}

public protocol SVG: Graphic {
    var path: UIBezierPath { get }
}

@available(*, deprecated=2.9, message="Use Graphic directly")
extension SVG {
    public func image(_ selected: Bool, tintColor: UIColor) -> CGImage? {
        let size = path.bounds.size
        return CGImage.op(Int(ceil(size.width)), Int(ceil(size.height))) { context in
            context!.setFillColor(tintColor.cgColor)
            context!.addPath(path.cgPath)
            context!.fillPath()
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
open class GraphicButton: UIButton, GraphicDesignable {
    @IBInspectable public var graphicClass: String? {
        didSet {
            setImageToGraphic()
        }
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()
        setImageToGraphic()
    }

    fileprivate func setImageToGraphic() {
        if let instance = self.graphic {
            if let image = instance.image(true, tintColor: tintColor) {
                setImage(UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .up), for: .selected)
            }
            if let image = instance.image(false, tintColor: tintColor) {
                setImage(UIImage(cgImage: image, scale: UIScreen.main.scale, orientation: .up), for: UIControlState())
            }
        }
    }
}

@IBDesignable
public class GraphicBarButtonItem: UIBarButtonItem, GraphicDesignable {
    @IBInspectable public var graphicClass: String? {
        didSet {
            setImageToGraphic()
        }
    }
    
    private func setImageToGraphic() {
        if let graphic = self.graphic {
            if let image = graphic.image(false, tintColor: tintColor ?? UIColor.whiteColor()) {
                self.image = UIImage(CGImage: image, scale: UIScreen.mainScreen().scale, orientation: .Up)
            }
        }
    }
}
