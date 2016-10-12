//
//  JSON.swift
//	Greycats
//
//  Created by Rex Sheng on 6/23/15.
//  Copyright (c) 2015 Interactive Labs. All rights reserved.
//

import Foundation

public struct JSON {
    public enum `Type` {
        case number
        case string
        case dictionary
        case array
        case null
    }
    public let type: Type
    public typealias RawValue = Any
    public let object: RawValue?
    
    public init(_ json: RawValue?) {
        switch json {
        case _ as String:
            type = .string
            object = json
        case _ as Double:
            type = .number
            object = json
        case _ as [RawValue]:
            type = .array
            object = json
        case _ as [String: RawValue]:
            type = .dictionary
            object = json
        default:
            type = .null
            object = nil
        }
    }
    
    public var int: Int? {
        if type == .number {
            return object as? Int
        }
        return nil
    }
    
    public var double: Double? {
        if type == .number {
            return object as? Double
        }
        return nil
    }
    
    public var string: String? {
        if type == .string {
            return object as? String
        }
        return nil
    }
    
    public var bool: Bool {
        if type == .number {
            return (object as? Bool)!
        }
        return false
    }
    
    public var array: [JSON]? {
        if type == .array {
            let array: [JSON] = (object as! [RawValue]).map { JSON($0) }
            return array
        }
        return nil
    }
    
    public var dictionary: [String: JSON]? {
        if type == .dictionary {
            var dictionary: [String: JSON] = [:]
            for (k, v) in object as! [String: RawValue] {
                dictionary[k] = JSON(v)
            }
            return dictionary
        }
        return nil
    }
    
    public func tryDictionary(_ keys: String...) -> JSON? {
        if let object = object as? [String: Any] {
            for key in keys {
                if let v = object[key] {
                    return JSON(v)
                }
            }
        }
        return nil
    }
    
    public var json: Any {
        if let o: Any = object {
            return o
        } else {
            return NSNull()
        }
    }
    
    public subscript (key: Int) -> JSON {
        if type == .array {
            if let object = object as? [RawValue] {
                return JSON(object[key])
            }
        }
        return JSON(nil)
    }
    
    public subscript (key: String) -> JSON {
        if let object = object as? [String: Any] {
            return JSON(object[key])
        }
        return JSON(nil)
    }
}

extension JSON: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.init(nil)
    }
}
