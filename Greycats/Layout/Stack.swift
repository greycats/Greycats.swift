//
//  AutolayoutStack.swift
//  Greycats
//
//  Created by Rex Sheng on 3/25/15.
//  Copyright (c) 2015 Interactive Labs. All rights reserved.
//

// available in pod 'Greycats', '~> 0.4.0'

import UIKit

public func _id<T: AnyObject>(_ object: T) -> String {
    return "[\(type(of: object)):0x\(String(UInt(bitPattern: ObjectIdentifier(object)), radix: 16))]"
}

func edge0(_ axis: NSLayoutConstraint.Axis) -> NSLayoutConstraint.Attribute {
    return axis == .vertical ? .top : .leading
}
func edge1(_ axis: NSLayoutConstraint.Axis) -> NSLayoutConstraint.Attribute {
    return axis == .vertical ? .bottom : .trailing
}
func perpendicularEdge0(_ axis: NSLayoutConstraint.Axis) -> NSLayoutConstraint.Attribute {
    return axis == .horizontal ? .top : .leading
}
func perpendicularEdge1(_ axis: NSLayoutConstraint.Axis) -> NSLayoutConstraint.Attribute {
    return axis == .horizontal ? .bottom : .trailing
}
func perpendicularDimension(_ axis: NSLayoutConstraint.Axis) -> NSLayoutConstraint.Attribute {
    return axis == .horizontal ? .height : .width
}

extension UIView {
    public func verticalStack(_ views: [UIView], marginX: CGFloat = 0) {
        for v in subviews {
            v.removeFromSuperview()
        }
        var previous: UIView? = nil
        for view in views {
            injectView(view, axis: .vertical, after: previous, marginX: marginX)
            previous = view
        }
    }
    
    public func horizontalStack(_ views: [UIView], marginX: CGFloat = 0, equalWidth: Bool = false) {
        for v in subviews {
            v.removeFromSuperview()
        }
        var previous: UIView? = nil
        for view in views {
            injectView(view, axis: .horizontal, after: previous, marginX: marginX)
            if equalWidth {
                if self is UIScrollView {
                    addConstraint(NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: -2 * marginX))
                } else if let previous = previous {
                    addConstraint(NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: previous, attribute: .width, multiplier: 1, constant: 0))
                }
            }
            previous = view
        }
    }
    
    public func _previousView(_ view: UIView, axis: NSLayoutConstraint.Axis) -> NSLayoutConstraint? {
        let gaps = constraints
        let attr = edge0(axis)
        for gap in gaps {
            if gap.firstAttribute == attr && gap.firstItem as? UIView == view {
                return gap
            }
        }
        return nil
    }
    
    public func _firstView(_ axis: NSLayoutConstraint.Axis) -> NSLayoutConstraint? {
        let gaps = constraints
        let attr = edge0(axis)
        for gap in gaps {
            if gap.secondAttribute == attr && gap.secondItem as? UIView == self {
                return gap
            }
        }
        return nil
    }
    
    public func _lastView(_ axis: NSLayoutConstraint.Axis) -> NSLayoutConstraint? {
        let gaps = constraints
        let attr = edge1(axis)
        for gap in gaps {
            if gap.firstAttribute == attr && gap.firstItem as? UIView == self {
                return gap
            }
        }
        return nil
    }
    
    public func _nextView(_ view: UIView, axis: NSLayoutConstraint.Axis) -> NSLayoutConstraint? {
        let gaps = constraints
        let attr = edge1(axis)
        for gap in gaps {
            if gap.secondAttribute == attr && gap.secondItem as? UIView == view {
                return gap
            }
        }
        return nil
    }
    
    public func ejectView(_ view: UIView, axis: NSLayoutConstraint.Axis, animated: Bool = true) {
        if let prev = _previousView(view, axis: axis),
            let next = _nextView(view, axis: axis) {
            if let prevNext = _previousView(next.firstItem as! UIView, axis: axis) {
                removeConstraint(prevNext)
            }
            let newConstraint = NSLayoutConstraint(item: next.firstItem!, attribute: next.firstAttribute, relatedBy: .equal, toItem: prev.secondItem, attribute: prev.secondAttribute, multiplier: 1, constant: view.bounds.height)
            if animated {
                addConstraint(newConstraint)
                layoutIfNeeded()
                UIView.animate(withDuration: 0.25, animations: {
                    view.alpha = 0
                    }, completion: { _ in
                        self.removeConstraint(prev)
                        self.removeConstraint(next)
                        view.removeFromSuperview()
                })
                UIView.animate(withDuration: 0.15, delay: 0.2, options: .curveEaseIn, animations: {
                    newConstraint.constant = 0
                    self.layoutIfNeeded()
                    }, completion: nil)
            } else {
                newConstraint.constant = 0
                addConstraint(newConstraint)
                removeConstraint(prev)
                removeConstraint(next)
                view.removeFromSuperview()
                layoutIfNeeded()
            }
        }
    }
    
    public func injectView(_ view: UIView, axis: NSLayoutConstraint.Axis, after previous: UIView?, marginX: CGFloat = 0, animated: Bool = false) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        let _edge0 = edge0(axis)
        let _edge1 = edge1(axis)
        let pedge0 = perpendicularEdge0(axis)
        let pedge1 = perpendicularEdge1(axis)
        let attr = perpendicularDimension(axis)
        addConstraint(NSLayoutConstraint(item: view, attribute: pedge0, relatedBy: .equal, toItem: self, attribute: pedge0, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: view, attribute: pedge1, relatedBy: .equal, toItem: self, attribute: pedge1, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: view, attribute: attr, relatedBy: .equal, toItem: self, attribute: attr, multiplier: 1, constant: 0))
        
        let edge0Constraint: NSLayoutConstraint
        if let previous = previous {
            // let us found original next view, and link it to this view
            if let c = _nextView(previous, axis: axis) {
                removeConstraint(c)
                let bottom = NSLayoutConstraint(item: c.firstItem!, attribute: c.firstAttribute, relatedBy: .equal, toItem: view, attribute: _edge1, multiplier: 1, constant: c.constant)
                addConstraint(bottom)
            }
            edge0Constraint = NSLayoutConstraint(item: view, attribute: _edge0, relatedBy: .equal, toItem: previous, attribute: _edge1, multiplier: 1, constant: marginX)
        } else {
            // view is gonna be first, find current first and unlink it
            if let c = _firstView(axis) {
                addConstraint(NSLayoutConstraint(item: c.firstItem!, attribute: _edge0, relatedBy: .equal, toItem: view, attribute: _edge1, multiplier: 1, constant: 0))
                removeConstraint(c)
            } else {
                let bottom = NSLayoutConstraint(item: self, attribute: _edge1, relatedBy: .equal, toItem: view, attribute: _edge1, multiplier: 1, constant: 0)
                addConstraint(bottom)
            }
            edge0Constraint = NSLayoutConstraint(item: view, attribute: _edge0, relatedBy: .equal, toItem: self, attribute: _edge0, multiplier: 1, constant: 0)
        }
        addConstraint(edge0Constraint)
        if animated {
            let size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            edge0Constraint.constant = axis == .vertical ? -size.height : -size.width
            layoutIfNeeded()
            view.alpha = 0
            UIView.animate(withDuration: 0.25, animations: {
                edge0Constraint.constant = 0
                self.layoutIfNeeded()
            })
            
            UIView.animate(withDuration: 0.15, delay: 0.2, options: .curveEaseIn, animations: {
                view.alpha = 1
                }, completion: nil)
        }
    }
}

infix operator |<
public func |< (view: UIView, views: [UIView]) {
    view.verticalStack(views, marginX: 0)
}

infix operator -<
public func -< (view: UIView, views: [UIView]) {
    view.horizontalStack(views, marginX: 0)
}

infix operator --<
public func --< (view: UIView, views: [UIView]) {
    view.horizontalStack(views, marginX: 0, equalWidth: true)
}

