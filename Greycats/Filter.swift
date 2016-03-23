//
//  Filter.swift
//	Greycats
//
//  Created by Rex Sheng on 1/28/15.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//

// available in pod 'Greycats', '~> 0.1.4'


public protocol Filtering {
	var valueToFilter: String? { get }
	func highlightMatches(matches: [NSTextCheckingResult])
	func clearMatches()
}

public class FilterHook<T: Equatable where T: Filtering> {
	public var source: [T]! {
		didSet {
			data.source = source
			delegate.applyFilter(term)
		}
	}
	public typealias Data = TableViewSource<T>
	let delegate = Filter.Delegate()
	var term: String?
	weak var data: Data!

	public init(data: Data, filter: Filter, shouldStart: (() -> Bool)? = nil, didCancel: () -> () = { }, didSearch: ((UIResponder) -> ())? = nil) {
		delegate.startEditing = shouldStart
		delegate.didCancel = didCancel
		if let didSearch = didSearch {
			delegate.didSearch = didSearch
		}
		self.data = data
		delegate.applyFilter = {[weak self] string in
			if let this = self {
				this.term = string
				guard let source = this.source else { return }
				let results = filter.apply(string, objects: source)
				this.data.source = results
			}
		}
	}

	convenience public init(data: Data, filter: Filter, input: UITextField, shouldStart: (() -> Bool)? = nil, didSearch: ((UIResponder) -> ())? = nil) {
		self.init(data: data, filter: filter, shouldStart: shouldStart, didSearch: didSearch)
		input.delegate = delegate
	}

	convenience public init(data: Data, filter: Filter, input: UISearchBar, shouldStart: (() -> Bool)? = nil, didCancel: () -> () = {}, didSearch: ((UIResponder) -> ())? = nil) {
		self.init(data: data, filter: filter, shouldStart: shouldStart, didCancel: didCancel, didSearch: didSearch)
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
		var pattern = "(?:.*?)"
		let range = (string.startIndex..<string.endIndex)
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

	public func apply<T: Filtering>(string: String?, objects: [T]) -> [T] {
		if let keyword = string {
			let r = pattern(keyword)
			var filtered: [T] = []
			objects.forEach { object in
				if let name = object.valueToFilter {
					let matches = r.matchesInString(name, options: .Anchored, range: NSMakeRange(0, name.characters.count))
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

	class Delegate: NSObject, UITextFieldDelegate, UISearchBarDelegate {
		var applyFilter: (String? -> ()) = { _ in }
		var didCancel: () -> () = {}
		var didSearch: ((UIResponder) -> ())? = { $0.resignFirstResponder() }
		var startEditing: (() -> Bool)? = nil

		func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
			return startEditing?() ?? true
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
			didSearch?(textField)
			return true
		}

		func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
			applyFilter(searchBar.text!.characters.count > 0 ? searchBar.text : nil)
		}

		func searchBarCancelButtonClicked(searchBar: UISearchBar) {
			applyFilter(nil)
			didCancel()
			searchBar.showsCancelButton = false
			searchBar.resignFirstResponder()
		}

		func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
			searchBar.showsCancelButton = true
			return startEditing?() ?? true
		}

		func searchBarSearchButtonClicked(searchBar: UISearchBar) {
			didSearch?(searchBar)
		}
	}
}