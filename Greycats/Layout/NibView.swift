//
//  NibView.swift
//  Greycats
//
//  Created by Rex Sheng on 3/11/15.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//

import UIKit

public let LineWidth = 1 / UIScreen.main.scale

extension UIView {
    public func fullDimension() {
        translatesAutoresizingMaskIntoConstraints = false
        let views = ["v": self]
        let parent = superview!
        parent.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v]|", options: [], metrics: nil, views: views))
        parent.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[v]|", options: [], metrics: nil, views: views))
    }
    
    public func bottom(_ height: CGFloat = 1) {
        translatesAutoresizingMaskIntoConstraints = false
        let views = ["v": self]
        let parent = superview!
        parent.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v]|", options: [], metrics: nil, views: views))
        parent.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[v(h)]|", options: [], metrics: ["h": height / UIScreen.main.scale], views: views))
    }
    
    public func right(_ width: CGFloat = 1, margin: CGFloat = 0) {
        translatesAutoresizingMaskIntoConstraints = false
        let views = ["v": self]
        let parent = superview!
        parent.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-m-[v]-m-|", options: [], metrics: ["m": margin], views: views))
        parent.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[v(w)]|", options: [], metrics: ["w": width / UIScreen.main.scale], views: views))
    }
}

extension UIStoryboardSegue {
    public func topViewController<T>() -> T? {
        var dest: T? = nil
        if let controller = destination as? T {
            dest = controller
        } else {
            if let controller = destination as? UINavigationController {
                if let controller = controller.topViewController as? T {
                    dest = controller
                }
            }
        }
        return dest
    }
}

private var viewKey: Void?

public protocol NibViewProtocol {
    func replaceFirstChildWith(nibName: String) -> UIView
}

extension NibViewProtocol where Self: UIView {
    public func replaceFirstChildWith(nibName: String) -> UIView {
        if let view = objc_getAssociatedObject(self, &viewKey) as? UIView {
            view.removeFromSuperview()
        }
        let buddle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: buddle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        view.backgroundColor = nil
        view.frame = bounds
        insertSubview(view, at: 0)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        objc_setAssociatedObject(self, &viewKey, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return view
    }
}

open class NibView: UIView, NibViewProtocol {
    open var nibName: String { return String(describing: type(of: self)) }
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    @IBOutlet var lineWidth: [NSLayoutConstraint]!
    
    open func setup() {
        _ = replaceFirstChildWith(nibName: nibName)
        if lineWidth != nil {
            for c in lineWidth {
                c.constant = LineWidth
            }
        }
    }
}

@IBDesignable
open class StyledView: NibView {
    open override var nibName: String { return "\(nibNamePrefix)\(layout)" }
    open var nibNamePrefix: String { return String(describing: type(of: self)) }
    @IBInspectable open var layout: String = "" {
        didSet {
            if oldValue != layout {
                setup()
            }
        }
    }
}

@IBDesignable
open class KernLabel: UILabel {
    @IBInspectable open var kern: Float = 0 {
        didSet { updateAttributedText() }
    }
    open override var text: String? {
        didSet { updateAttributedText() }
    }
    
    @IBInspectable open var lineHeight: CGFloat = 0 {
        didSet { updateAttributedText() }
    }
    
    open var attributes: [NSAttributedString.Key: Any] {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = lineHeight / font.lineHeight
        style.alignment = textAlignment
        return [
            NSAttributedString.Key.font: font as Any,
            NSAttributedString.Key.foregroundColor: textColor as Any,
            NSAttributedString.Key.kern: kern as Any,
            NSAttributedString.Key.paragraphStyle: style,
        ]
    }
    
    func updateAttributedText() {
        if let text = text {
            attributedText = NSAttributedString(string: text, attributes: attributes)
        }
    }
}
