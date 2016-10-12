//
//  Graphics.swift
//  Greycats
//
//  Created by Rex Sheng on 8/1/16.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//

import UIKit

private var _bitmapInfo: UInt32 = {
    var bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue
    bitmapInfo &= ~CGBitmapInfo.alphaInfoMask.rawValue
    bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue
    return bitmapInfo
}()

extension CGImage {
    public func op(_ closure: (CGContext?, CGRect) -> ()) -> CGImage? {
        let width = self.width
        let height = self.height
        let colourSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 8, space: colourSpace, bitmapInfo: bitmapInfo.rawValue)
        let rect = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        closure(context, rect)
        return context!.makeImage()
    }
    
    public static func op(_ width: Int, _ height: Int, closure: (CGContext?) -> ()) -> CGImage? {
        let scale = UIScreen.main.scale
        let w = width * Int(scale)
        let h = height * Int(scale)
        let colourSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 8, space: colourSpace, bitmapInfo: _bitmapInfo)
        context!.translateBy(x: 0, y: CGFloat(h))
        context!.scaleBy(x: scale, y: -scale)
        closure(context)
        return context!.makeImage()
    }
}
