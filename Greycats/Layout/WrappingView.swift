//
//  WrapingView.swift
//  Trusted
//
//  Created by Rex Sheng on 8/16/16.
//  Copyright © 2016 Trusted. All rights reserved.
//

import UIKit

public class WrappingView: UIView {
    
    public var insets: UIEdgeInsets = .zero
    
    public var wrappingItems: [UIView] = [] {
        didSet {
            oldValue.forEach { $0.removeFromSuperview() }
            wrappingItems.forEach { (item) in
                item.translatesAutoresizingMaskIntoConstraints = false
                addSubview(item)
            }
            invalidateIntrinsicContentSize()
        }
    }
    
    private var _intrinsicContentSize: CGSize? {
        didSet {
            if oldValue != _intrinsicContentSize {
                invalidateIntrinsicContentSize()
            }
        }
    }
    public override var intrinsicContentSize: CGSize {
        return _intrinsicContentSize ?? CGSize.zero
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let wereEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        var totalRect = CGRect.null
        let layoutWidth = bounds.width
        var rect = CGRect(x: insets.left, y: insets.top, width: 0, height: 0)
        wrappingItems.forEach { (item) in
            let size = item.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            let width = min(size.width, layoutWidth - insets.left - insets.right)
            if rect.origin.x > layoutWidth - insets.left - insets.right - size.width {
                rect.origin.y += size.height + insets.bottom
                rect.origin.x = insets.left
            }
            rect.size = CGSize(width: width, height: size.height)
            totalRect = rect.union(totalRect)
            item.frame = rect
            rect.origin.x += rect.size.width + insets.right
        }
        _intrinsicContentSize = totalRect.size
        UIView.setAnimationsEnabled(wereEnabled)
    }
}
