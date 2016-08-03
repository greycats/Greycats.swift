//
//  Filter.swift
//	Greycats
//
//  Created by Rex Sheng on 1/28/15.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//

// available in pod 'Greycats', '~> 0.1.4'

import Foundation

public protocol Filtering {
    var valueToFilter: String? { get }
    func highlightMatches(matches: [NSTextCheckingResult])
    func clearMatches()
}

public enum Filter {
    case CharacterSequences
    case WordSequences
    case WordInitialSequences
    case StartWith
    case Contains

    func pattern(string: String) throws -> NSRegularExpression {
        var pattern = "(?:.*?)"
        let range = string.startIndex..<string.endIndex
        switch self {
        case .CharacterSequences:
            string.enumerateSubstringsInRange(range, options: NSStringEnumerationOptions.ByComposedCharacterSequences) { (substring, substringRange, enclosingRange, stop) -> () in
                let escaped = NSRegularExpression.escapedPatternForString(substring!)
                pattern.appendContentsOf("(\(escaped))(?:.*?)")
            }
        case .WordSequences:
            string.enumerateSubstringsInRange(range, options: NSStringEnumerationOptions.ByWords) { (substring, substringRange, enclosingRange, stop) -> () in
                let escaped = NSRegularExpression.escapedPatternForString(substring!)
                pattern.appendContentsOf("(\(escaped))(?:.*?)")
            }
        case .WordInitialSequences:
            string.enumerateSubstringsInRange(range, options: NSStringEnumerationOptions.ByWords) { (substring, substringRange, enclosingRange, stop) -> () in
                let escaped = NSRegularExpression.escapedPatternForString(substring!)
                pattern.appendContentsOf("\\b(\(escaped))(?:.*?)")
            }
        case .StartWith:
            let escaped = NSRegularExpression.escapedPatternForString(string)
            pattern = "(\(escaped)).*?"
        case .Contains:
            let escaped = NSRegularExpression.escapedPatternForString(string)
            pattern = ".*?(\(escaped)).*?"
        }
        return try NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions.CaseInsensitive)
    }

    public func apply<T: Filtering>(string: String?, objects: [T]) -> [T] {
        if let keyword = string,
            r = try? pattern(keyword) {
            var filtered: [T] = []
            objects.forEach { object in
                if let value = object.valueToFilter {
                    let matches = r.matchesInString(value, options: .Anchored, range: NSMakeRange(0, value.characters.count))
                    if matches.count > 0 {
                        object.highlightMatches(matches)
                        filtered.append(object)
                    }
                }
            }
            return filtered
        } else {
            for t in objects {
                t.clearMatches()
            }
            return objects
        }
    }
}