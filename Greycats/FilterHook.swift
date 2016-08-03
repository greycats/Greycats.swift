//
//  Filter.swift
//	Greycats
//
//  Created by Rex Sheng on 8/3/16.
//  Copyright (c) 2016 Interactive Labs. All rights reserved.
//

import UIKit

class Delegate: NSObject {
    var applyFilter: (String? -> ()) = { _ in }
    var didCancel: (() -> Void)?
    var didSearch: ((UIResponder) -> ())? = { $0.resignFirstResponder() }
    var startEditing: (() -> Bool)?
}

extension Delegate: UITextFieldDelegate {
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
}

extension Delegate: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        applyFilter(searchBar.text!.characters.count > 0 ? searchBar.text : nil)
    }

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        applyFilter(nil)
        didCancel?()
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

public class FilterHook<T: Equatable where T: Filtering> {
    public var source: [T]! {
        didSet {
            data.source = source
            delegate.applyFilter(term)
        }
    }
    public typealias Data = TableViewSource<T>
    let delegate = Delegate()
    var term: String?
    weak var data: Data!

    public init(data: Data, filter: Filter, shouldStart: (() -> Bool)? = nil, didCancel: () -> () = {}, didSearch: ((UIResponder) -> ())? = nil) {
        delegate.startEditing = shouldStart
        delegate.didCancel = didCancel
        if let didSearch = didSearch {
            delegate.didSearch = didSearch
        }
        self.data = data
        delegate.applyFilter = {[weak self] string in
            guard let this = self else { return }
            this.term = string
            guard let source = this.source else { return }
            this.data.source = filter.apply(string, objects: source)
        }
    }

    public convenience init(data: Data, filter: Filter, input: UITextField, shouldStart: (() -> Bool)? = nil, didSearch: ((UIResponder) -> ())? = nil) {
        self.init(data: data, filter: filter, shouldStart: shouldStart, didSearch: didSearch)
        input.delegate = delegate
    }

    public convenience init(data: Data, filter: Filter, input: UISearchBar, shouldStart: (() -> Bool)? = nil, didCancel: () -> () = {}, didSearch: ((UIResponder) -> ())? = nil) {
        self.init(data: data, filter: filter, shouldStart: shouldStart, didCancel: didCancel, didSearch: didSearch)
        input.delegate = delegate
    }
}