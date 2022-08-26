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
    func highlightMatches(_ matches: [NSTextCheckingResult])
    func clearMatches()
}

public enum Filter {
    case characterSequences
    case wordSequences
    case wordInitialSequences
    case startWith
    case contains
    
    func pattern(_ string: String) throws -> NSRegularExpression {
        var pattern = "(?:.*?)"
        let range = Range<String.Index>(uncheckedBounds: (string.startIndex, string.endIndex))
        switch self {
        case .characterSequences:
            string.enumerateSubstrings(in: range, options: NSString.EnumerationOptions.byComposedCharacterSequences) { (substring, substringRange, enclosingRange, stop) -> () in
                let escaped = NSRegularExpression.escapedPattern(for: substring!)
                pattern.append("(\(escaped))(?:.*?)")
            }
        case .wordSequences:
            string.enumerateSubstrings(in: range, options: .byWords) { (substring, substringRange, enclosingRange, stop) -> () in
                let escaped = NSRegularExpression.escapedPattern(for: substring!)
                pattern.append("(\(escaped))(?:.*?)")
            }
        case .wordInitialSequences:
            string.enumerateSubstrings(in: range, options: .byWords) { (substring, substringRange, enclosingRange, stop) -> () in
                let escaped = NSRegularExpression.escapedPattern(for: substring!)
                pattern.append("\\b(\(escaped))(?:.*?)")
            }
        case .startWith:
            let escaped = NSRegularExpression.escapedPattern(for: string)
            pattern = "(\(escaped)).*?"
        case .contains:
            let escaped = NSRegularExpression.escapedPattern(for: string)
            pattern = ".*?(\(escaped)).*?"
        }
        return try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
    }
    
    public func apply<T: Filtering>(_ string: String?, objects: [T]) -> [T] {
        if let keyword = string,
            let r = try? pattern(keyword) {
            var filtered: [T] = []
            objects.forEach { object in
                if let value = object.valueToFilter {
                    let matches = r.matches(in: value, options: .anchored, range: NSMakeRange(0, value.count))
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
