//
//  Filter.swift
//
//  Created by Rex Sheng on 1/28/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

// available in pod 'Greycats', '~> 0.1.4'

import UIKit

public protocol FilterDelegate {
	func numberOfItemsPassingToFilter() -> Int
	func itemPassingToFilterAt(index: Int) -> AnyObject!
	func comparingStringOf(item: AnyObject) -> String!
}

public enum Filter {
	case CharacterSequences
	case WordSequences
	case WordInitialSequences
	case StartWith
	case Contains
	
	public func pattern(string: String) -> NSRegularExpression {
		var pattern = "(.*?)"
		let range = Range(start: string.startIndex, end: string.endIndex)
		switch self {
		case .CharacterSequences:
			string.enumerateSubstringsInRange(range, options: NSStringEnumerationOptions.ByComposedCharacterSequences) { (substring, substringRange, enclosingRange, stop) -> () in
				let escaped = NSRegularExpression.escapedPatternForString(substring)
				pattern += "(\(escaped))(?:.*?)"
			}
		case .WordSequences:
			string.enumerateSubstringsInRange(range, options: NSStringEnumerationOptions.ByWords) { (substring, substringRange, enclosingRange, stop) -> () in
				let escaped = NSRegularExpression.escapedPatternForString(substring)
				pattern += "(\(escaped))(?:.*?)"
			}
		case .WordInitialSequences:
			string.enumerateSubstringsInRange(range, options: NSStringEnumerationOptions.ByWords) { (substring, substringRange, enclosingRange, stop) -> () in
				let escaped = NSRegularExpression.escapedPatternForString(substring)
				pattern += "\\b(\(escaped))(?:.*?)"
			}
		case .StartWith:
			let escaped = NSRegularExpression.escapedPatternForString(string)
			pattern = "(\(escaped)).*?"
		case .Contains:
			let escaped = NSRegularExpression.escapedPatternForString(string)
			pattern = ".*?(\(escaped)).*?"
		}
		let r = NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions.CaseInsensitive, error: nil)!
		return r
	}
	
	public func apply<T>(string: String?, objects: [T], selector: (T) -> String?) -> [T] {
		var filtered: [T] = objects
		if let keyword = string {
			let r = self.pattern(keyword)
			filtered = objects.filter() {
				if let name = selector($0) {
					return r.firstMatchInString(name, options: NSMatchingOptions.Anchored, range: NSMakeRange(0, name.utf16Count)) != nil
				}
				return false
			}
		}
		return filtered
	}
	
	public func apply(string: String, delegate: FilterDelegate) -> [AnyObject]? {
		let r = self.pattern(string)
		let num = delegate.numberOfItemsPassingToFilter()
		var filtered: [AnyObject] = []
		for i in 0..<num {
			let item: AnyObject = delegate.itemPassingToFilterAt(i)
			let name = delegate.comparingStringOf(item)
			if let m = r.firstMatchInString(name, options: NSMatchingOptions.Anchored, range: NSMakeRange(0, name.utf16Count)) {
				filtered.append(item)
			}
		}
		return filtered
	}
	
	public class Delegate: NSObject, UITextFieldDelegate, UISearchBarDelegate {
		var applyFilter: ((String?, hitReturn: Bool) -> Void) = { _ in }
		var startEditing: (() -> Bool)? = nil
		
		public func onChange(block: (String?, hitReturn: Bool) -> Void) -> Self {
			applyFilter = block
			return self
		}
		
		public func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
			var start = true
			if startEditing != nil {
				start = startEditing!()
			}
			return start
		}
		
		public func search(term: String?) {
			applyFilter(term, hitReturn: false)
		}
		
		public func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
			let filter = (textField.text as NSString).stringByReplacingCharactersInRange(range, withString: string)
			if countElements(filter) > 0 {
				applyFilter(filter, hitReturn: false)
			} else {
				applyFilter(nil, hitReturn: false)
			}
			return true
		}
		
		public func textFieldShouldClear(textField: UITextField) -> Bool {
			applyFilter(nil, hitReturn: false)
			return true
		}
		
		public func textFieldShouldReturn(textField: UITextField) -> Bool {
			applyFilter(countElements(textField.text) > 0 ? textField.text : nil, hitReturn: true)
			textField.resignFirstResponder()
			return true
		}
		
		public func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
			applyFilter(countElements(searchBar.text) > 0 ? searchBar.text : nil, hitReturn: false)
		}
		
		public func searchBarCancelButtonClicked(searchBar: UISearchBar) {
			applyFilter(nil, hitReturn: false)
		}
		
		public func searchBarSearchButtonClicked(searchBar: UISearchBar) {
			searchBar.resignFirstResponder()
		}
	}
}