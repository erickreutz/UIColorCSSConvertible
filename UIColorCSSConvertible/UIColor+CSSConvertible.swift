//
//  UIColor+CSSConvertible.swift
//  UIColorCSSConvertible
//
//  Created by Eric on 10/9/14.
//  Copyright (c) 2014 erickreutz. All rights reserved.
//
//  Influenced almost entirely by fabric.js color functions
//  http://fabricjs.com/docs/fabric.js.html#line4422
//

import UIKit
import Foundation

private enum CSSColorRegex: NSRegularExpression {
    case RGBA = "^rgba?\\(\\s*(\\d{1,3}(?:\\.\\d+)?\\%?)\\s*,\\s*(\\d{1,3}(?:\\.\\d+)?\\%?)\\s*,\\s*(\\d{1,3}(?:\\.\\d+)?\\%?)\\s*(?:\\s*,\\s*(\\d+(?:\\.\\d+)?)\\s*)?\\)$"
    case HSLA = "^hsla?\\(\\s*(\\d{1,3})\\s*,\\s*(\\d{1,3}\\%)\\s*,\\s*(\\d{1,3}\\%)\\s*(?:\\s*,\\s*(\\d+(?:\\.\\d+)?)\\s*)?\\)$"
    case HEX = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
}

private enum CSSColorFormat {
    case RGBA(String)
    case HSLA(String)
    case HEX(String)
    case Invalid
}

private func HEX2ColorValue(string: String) -> CGFloat {
    var value: UInt32 = 0
    NSScanner(string: "0x" + string).scanHexInt(&value)
    return CGFloat( Int(value) ) / CGFloat(255.00)
}

private func HUE2RGB(var p: CGFloat, var q: CGFloat, var t: CGFloat) -> CGFloat {
    if (t < 0) {
        t += 1
    }
    if (t > 1) {
        t -= 1.0
    }
    if (t < 1/6) {
        return p + (q - p) * 6 * t
    }
    if (t < 1/2) {
        return q;
    }
    if (t < 2/3) {
        return p + (q - p) * (2/3 - t) * 6
    }
    return (p / 255)
}

private struct CSSColor {
    typealias ColorTuple = (CGFloat, CGFloat, CGFloat, CGFloat)
    
    var red:   CGFloat = 0,
    green: CGFloat = 0,
    blue:  CGFloat = 0,
    alpha: CGFloat = 1
    
    init(format: CSSColorFormat) {
        var colorTuple: ColorTuple?
        
        switch format {
        case .RGBA(let colorString):
            colorTuple = self.sourceFromRGBA(colorString)
            break
        case .HSLA(let colorString):
            colorTuple = self.sourceFromHSLA(colorString)
            break
        case .HEX(let colorString):
            colorTuple = self.sourceFromHEX(colorString)
            break
        case .Invalid:
            break
        }
        
        if let validTuple = colorTuple {
            (self.red, self.green, self.blue, self.alpha) = validTuple
        }
    }
    
    // NSString So we can use NSRange with substringWithRange
    private func sourceFromRGBA(color: NSString) -> ColorTuple? {
        if let firstMatch = CSSColorRegex.RGBA.toRaw().firstMatch(color) {
            var parts = [NSString]()
            
            for i in 0..<firstMatch.numberOfRanges {
                var range = firstMatch.rangeAtIndex(i)
                
                if range.location != NSNotFound && range.location != 0 {
                    parts.append( color.substringWithRange( firstMatch.rangeAtIndex(i) ) )
                }
            }
            
            
            var r = CGFloat(parts[0].floatValue) / (parts[0].hasSuffix("%") ? 100 : 1) * (parts[0].hasSuffix("%") ? 255 : 1),
            g = CGFloat(parts[0].floatValue) / (parts[0].hasSuffix("%") ? 100 : 1) * (parts[0].hasSuffix("%") ? 255 : 1),
            b = CGFloat(parts[0].floatValue) / (parts[0].hasSuffix("%") ? 100 : 1) * (parts[0].hasSuffix("%") ? 255 : 1);
            
            return (r, g, b, parts.count > 3 ? CGFloat(parts[3].floatValue) : 1)
        }
        
        return nil
    }
    
    private func sourceFromHEX(color: String) -> ColorTuple? {
        if CSSColorRegex.HEX.toRaw().matches(color) {
            var value = Array(color.stringByReplacingOccurrencesOfString("#", withString: "", options: .LiteralSearch, range: nil))
            var isShorthand = countElements(value) == 3
            
            
            var r = HEX2ColorValue(isShorthand
                ? value[0] + value[0]
                : "".join( value[0...1].map { String($0) } )
            )
            
            var g = HEX2ColorValue(isShorthand
                ? value[0] + value[1]
                : "".join( value[2...3].map { String($0) } )
            )
            
            var b = HEX2ColorValue(isShorthand
                ? value[0] + value[2]
                : "".join( value[4...5].map { String($0) } )
            )
            
            return (r, g, b, 1)
        }
        
        return nil
    }
    
    // NSString So we can use NSRange with substringWithRange
    private func sourceFromHSLA(color: NSString) -> ColorTuple? {
        if let firstMatch = CSSColorRegex.HSLA.toRaw().firstMatch(color) {
            var parts = [NSString]()
            
            for i in 0..<firstMatch.numberOfRanges {
                var range = firstMatch.rangeAtIndex(i)
                
                if range.location != NSNotFound && range.location != 0 {
                    parts.append( color.substringWithRange( firstMatch.rangeAtIndex(i) ) )
                }
            }
            
            var h = ((CGFloat(parts[0].floatValue % 360) + 360) % 360) / 360,
            s = CGFloat(parts[1].floatValue) / ( parts[1].hasSuffix("%") ? 100 : 1 ),
            l = CGFloat(parts[2].floatValue) / ( parts[2].hasSuffix("%") ? 100 : 1 ),
            r: CGFloat, g: CGFloat, b: CGFloat;
            
            if (s == 0) {
                (r, g, b) = (l, l, l)
            } else {
                var q = l <= 0.5 ? l * (s + 1) : l + s - l * s,
                p = l * 2 - q
                
                r = HUE2RGB(p, q, h + 1/3)
                g = HUE2RGB(p, q, h)
                b = HUE2RGB(p, q, h - 1/3)
                
                return (round(r), round(g), round(b), parts.count > 3 ? CGFloat(parts[3].floatValue) : 1)
            }
        }
        
        return nil
    }
}

extension NSRegularExpression: StringLiteralConvertible {
    typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    
    public class func convertFromStringLiteral(value: StringLiteralType) -> Self {
        return self(pattern: value, options: nil, error: nil)
    }
    
    public class func convertFromExtendedGraphemeClusterLiteral(value: StringLiteralType) -> Self {
        return self(pattern: value, options: nil, error: nil)
    }
    
    public func matches(string: String) -> Bool {
        return self.matchesInString(string, options: nil, range: NSMakeRange(0, countElements(string))).count > 0
    }
    
    public func firstMatch(string: String) -> NSTextCheckingResult? {
        return self.firstMatchInString(string, options: nil, range: NSMakeRange(0, countElements(string)))
    }
}

extension UIColor: StringLiteralConvertible {
    typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    
    private class func convertFromCSSColorString(colorString: String) -> Self {
        var color: CSSColor
        
        if CSSColorRegex.HSLA.toRaw().matches(colorString) {
            color = CSSColor(format: CSSColorFormat.HSLA(colorString))
        } else if CSSColorRegex.RGBA.toRaw().matches(colorString) {
            color = CSSColor(format: CSSColorFormat.RGBA(colorString))
        } else if CSSColorRegex.HEX.toRaw().matches(colorString) {
            color = CSSColor(format: CSSColorFormat.HEX(colorString))
        } else {
            color = CSSColor(format: CSSColorFormat.Invalid)
        }
        
        return self(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)
    }
    
    public class func convertFromStringLiteral(value: StringLiteralType) -> Self {
        return convertFromCSSColorString(value)
    }
    
    public class func convertFromExtendedGraphemeClusterLiteral(value: StringLiteralType) -> Self {
        return convertFromCSSColorString(value)
    }
}
