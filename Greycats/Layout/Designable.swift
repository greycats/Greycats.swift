//
//  Box.swift
//	Greycats
//
//  Created by Rex Sheng on 5/1/15.
//  Copyright (c) 2015 Interactive Labs. All rights reserved.
//

import UIKit

public extension UIView {
    
    @IBInspectable var borderColor: UIColor? {
        get { if let color = layer.borderColor { return UIColor(cgColor: color) } else { return nil } }
        set(value) { if let value = value { layer.borderColor = value.cgColor } }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get { return layer.borderWidth }
        set(value) { layer.borderWidth = value }
    }
    
    @IBInspectable var relativeBorderWidth: CGFloat {
        get { return layer.borderWidth * UIScreen.main.scale }
        set(value) { layer.borderWidth = value / UIScreen.main.scale }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        get { return layer.cornerRadius }
        set(value) {
            layer.cornerRadius = value
        }
    }
    
    @IBInspectable var masksToBounds: Bool {
        get { return layer.masksToBounds }
        set(value) {
            layer.masksToBounds = value
        }
    }
    
    @IBInspectable var shadowColor: UIColor? {
        get { if let color = layer.shadowColor { return UIColor(cgColor: color) } else { return nil } }
        set(value) { if let value = value { layer.shadowColor = value.cgColor } }
    }
    
    @IBInspectable var shadowOffset: CGPoint {
        get { return CGPoint(x: layer.shadowOffset.width, y: layer.shadowOffset.height) }
        set(value) { layer.shadowOffset = CGSize(width: value.x, height: value.y) }
    }
    
    @IBInspectable var relativeShadowOffset: CGPoint {
        get { return CGPoint(x: layer.shadowOffset.width * UIScreen.main.scale, y: layer.shadowOffset.height * UIScreen.main.scale) }
        set(value) { layer.shadowOffset = CGSize(width: value.x / UIScreen.main.scale, height: value.y / UIScreen.main.scale) }
    }
    
    @IBInspectable var shadowOpacity: Float {
        get { return layer.shadowOpacity }
        set(value) {
            layer.shadowOpacity = value
            layer.masksToBounds = false
            if value > 0 {
                layer.shouldRasterize = true
                layer.rasterizationScale = UIScreen.main.scale
            } else {
                layer.shouldRasterize = false
            }
        }
    }
    
    @IBInspectable var shadowRadius: CGFloat {
        get { return layer.shadowRadius }
        set(value) { layer.shadowRadius = value }
    }
    
    @IBInspectable var relativeShadowRadius: CGFloat {
        get { return layer.shadowRadius * UIScreen.main.scale }
        set(value) { layer.shadowRadius = value / UIScreen.main.scale }
    }
}

@IBDesignable
open class BoxView: UIView {
    @IBInspectable open var cornerRadii: CGSize = CGSize(width: 4, height: 4)
    @IBInspectable open var corners: UInt = 0 {
        didSet {
            updateCorners()
        }
    }
    fileprivate func updateCorners() {
        if corners > 0 {
            let shape = CAShapeLayer()
            shape.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: UIRectCorner(rawValue: corners), cornerRadii: cornerRadii).cgPath
            layer.mask = shape
        }
    }
}

@IBDesignable
open class TextField: UITextField {
    @IBInspectable open var placeholderAlpha: CGFloat = 0.5 {
        didSet {
            updatePlaceholder()
        }
    }
    
    fileprivate func updatePlaceholder() {
        if let placeholder = placeholder, let font = font, let textColor = textColor {
            attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: textColor.withAlphaComponent(placeholderAlpha)
                ])
        }
    }
    
    override open var placeholder: String? {
        didSet {
            updatePlaceholder()
        }
    }
    
    override open var font: UIFont? {
        didSet {
            updatePlaceholder()
        }
    }
    
    override open var textColor: UIColor? {
        didSet {
            updatePlaceholder()
        }
    }
}

@IBDesignable
open class GradientView: UIView {
    @IBInspectable open var color1: UIColor = UIColor.white { didSet { setNeedsDisplay() } }
    @IBInspectable open var color2: UIColor = UIColor.white { didSet { setNeedsDisplay() } }
    @IBInspectable open var loc1: CGPoint = CGPoint(x: 0, y: 0) { didSet { setNeedsDisplay() } }
    @IBInspectable open var loc2: CGPoint = CGPoint(x: 1, y: 1) { didSet { setNeedsDisplay() } }
    
    override open func draw(_ rect: CGRect) {
        drawGradient(rect)
        super.draw(rect)
    }
    
    open func drawGradient(_ rect: CGRect, closure: () -> () = {}) {
        let context = UIGraphicsGetCurrentContext()
        
        context!.saveGState()
        closure()
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [color1.cgColor, color2.cgColor] as CFArray, locations: [0, 1])
        context!.drawLinearGradient(gradient!,
                                    start: CGPoint(x: rect.size.width * loc1.x, y: rect.size.height * loc1.y),
                                    end: CGPoint(x: rect.size.width * loc2.x, y: rect.size.height * loc2.y),
                                    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        context!.restoreGState()
    }
}

@IBDesignable
open class _Control: UIControl {
    override open func tintColorDidChange() {
        setNeedsDisplay()
    }
    
    @IBInspectable open var disabledColor: UIColor = UIColor.gray
    
    @IBInspectable open var respectHeight: Bool = false {
        didSet { setNeedsDisplay() }
    }
    
    @IBInspectable open var desiredWidth: CGFloat = 0 {
        didSet { setNeedsDisplay() }
    }
    
    @IBInspectable open var scaleBoost: CGFloat = 1 {
        didSet { setNeedsDisplay() }
    }
    
    @IBInspectable open var angle: CGFloat = 0 {
        didSet { setNeedsDisplay() }
    }
    
    required override public init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .redraw
        isOpaque = false
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        contentMode = .redraw
        isOpaque = false
    }
    
    open func centerScale(_ originalSize: CGSize, closure: (_ scale: CGFloat) -> ()) {
        let rect = bounds
        let scale: CGFloat
        let width: CGFloat
        let height: CGFloat
        if respectHeight {
            height = rect.size.width * scaleBoost
            scale = height / originalSize.height
            width = height * originalSize.width / originalSize.height
        } else {
            if desiredWidth == 0 {
                width = rect.size.width * scaleBoost
            } else {
                width = desiredWidth * scaleBoost
            }
            scale = width / originalSize.width
            height = width * originalSize.height / originalSize.width
        }
        let context = UIGraphicsGetCurrentContext()
        context!.saveGState()
        context!.translateBy(x: (rect.size.width - width) / 2, y: (rect.size.height - height) / 2)
        context!.scaleBy(x: scale, y: scale)
        if isEnabled {
            tintColor.setFill()
            tintColor.setStroke()
        } else {
            disabledColor.setFill()
            disabledColor.setStroke()
        }
        closure(scale)
        context!.restoreGState()
    }
}
