//
//  Filter.swift
//
//  Created by Rex Sheng on 1/28/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

// available in pod 'Greycats', '~> 0.1.4'

import UIKit

public class FilterHook<T: Equatable> {
	public var source: [T]! {
		didSet {
			data.source = source
			delegate.applyFilter(term)
		}
	}
	
	let delegate = Filter.Delegate()
	var term: String?
	weak var data: TableViewSource<T>!
	public init(data: TableViewSource<T>, filter: Filter, input: UITextField, shouldStart: (() -> Bool)? = nil, selector: T -> String?) {
		delegate.startEditing = shouldStart
		self.data = data
		delegate.applyFilter = {[weak self] string in
			if let this = self {
				this.term = string
				let results = filter.apply(string, objects: this.source, selector: selector)
				self?.data.source = results
			}
		}
		input.delegate = delegate
	}
}

public enum Filter {
	case CharacterSequences
	case WordSequences
	case WordInitialSequences
	case StartWith
	case Contains

	func pattern(string: String) -> NSRegularExpression {
		var pattern = "(.*?)"
		let range = Range(start: string.startIndex, end: string.endIndex)
		switch self {
		case .CharacterSequences:
			string.enumerateSubstringsInRange(range, options: NSStringEnumerationOptions.ByComposedCharacterSequences) { (substring, substringRange, enclosingRange, stop) -> () in
				let escaped = NSRegularExpression.escapedPatternForString(substring!)
				pattern += "(\(escaped))(?:.*?)"
			}
		case .WordSequences:
			string.enumerateSubstringsInRange(range, options: NSStringEnumerationOptions.ByWords) { (substring, substringRange, enclosingRange, stop) -> () in
				let escaped = NSRegularExpression.escapedPatternForString(substring!)
				pattern += "(\(escaped))(?:.*?)"
			}
		case .WordInitialSequences:
			string.enumerateSubstringsInRange(range, options: NSStringEnumerationOptions.ByWords) { (substring, substringRange, enclosingRange, stop) -> () in
				let escaped = NSRegularExpression.escapedPatternForString(substring!)
				pattern += "\\b(\(escaped))(?:.*?)"
			}
		case .StartWith:
			let escaped = NSRegularExpression.escapedPatternForString(string)
			pattern = "(\(escaped)).*?"
		case .Contains:
			let escaped = NSRegularExpression.escapedPatternForString(string)
			pattern = ".*?(\(escaped)).*?"
		}
		let r = try! NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions.CaseInsensitive)
		return r
	}

	public func apply<T>(string: String?, objects: [T], selector: (T) -> String?) -> [T] {
		var filtered: [T] = objects
		if let keyword = string {
			let r = pattern(keyword)
			filtered = objects.filter { object in
				if let name = selector(object) {
					return r.firstMatchInString(name, options: NSMatchingOptions.Anchored, range: NSMakeRange(0, name.characters.count)) != nil
				}
				return false
			}
		}
		return filtered
	}

	class Delegate: NSObject, UITextFieldDelegate, UISearchBarDelegate {
		var applyFilter: (String? -> ()) = { _ in }
		var startEditing: (() -> Bool)? = nil

		func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
			var start = true
			if startEditing != nil {
				start = startEditing!()
			}
			return start
		}

		func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
			let filter = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
			if filter.characters.count > 0 {
				applyFilter(filter)
			} else {
				applyFilter(nil)
			}
			return true
		}

		func textFieldShouldClear(textField: UITextField) -> Bool {
			applyFilter(nil)
			return true
		}

		func textFieldShouldReturn(textField: UITextField) -> Bool {
			applyFilter(textField.text!.characters.count > 0 ? textField.text : nil)
			textField.resignFirstResponder()
			return true
		}

		func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
			applyFilter(searchBar.text!.characters.count > 0 ? searchBar.text : nil)
		}

		func searchBarCancelButtonClicked(searchBar: UISearchBar) {
			applyFilter(nil)
		}

		func searchBarSearchButtonClicked(searchBar: UISearchBar) {
			searchBar.resignFirstResponder()
		}
	}
}