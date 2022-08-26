//
//  TableViewData.swift
//	Greycats
//
//  Created by Rex Sheng on 1/29/15.
//  Copyright (c) 2015 Interactive Labs. All rights reserved.
//

// available in pod 'Greycats', '~> 0.1.5'

import UIKit

public protocol SectionData {
    var section: Int { get set }
    var tableView: UITableView? { get set }
    var reversed: Bool { get set }
    var navigationController: UINavigationController? { get set }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    func tableView(_ tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell!
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath)
    func tableView(_ tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: IndexPath)
    func tableView(_ tableView: UITableView, moveRowAtIndexPath sourceIndexPath: IndexPath, toIndexPath destinationIndexPath: IndexPath)
    func tableView(_ tableView: UITableView, editingStyleForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell.EditingStyle
}

public protocol TableViewDataNibCell {
    static var nibName: String { get }
}

extension TableViewDataNibCell {
    public static var nibName: String {
        return String(describing: self)
    }
}

public enum ChangeType {
    case create
    case update
    case delete
}

public struct Change<T: Equatable> {
    public let value: T
    public let type: ChangeType
    public init(type: ChangeType, value: T) {
        self.type = type
        self.value = value
    }
}

open class TableViewSource<T: Equatable>: SectionData {
    public typealias Element = T
    fileprivate var data: [T] = []
    fileprivate var select: ((T, Int) -> UIViewController?)?
    open var cacheKey: ((T) -> String)?
    fileprivate weak var _tableView: UITableView?
    open var reversed: Bool = false
    open var section: Int = 0
    open var tableView: UITableView? {
        set(t) {
            if let t = t {
                willSetTableView(t)
                _tableView = t
                didSetTableView(t)
            }
        }
        get {
            return _tableView
        }
    }
    open weak var navigationController: UINavigationController?
    fileprivate var title: String?
    fileprivate var renderHeader: ((String) -> UIView)?
    
    @discardableResult
    open func onHeader(_ block: @escaping (String) -> UIView) -> Self {
        renderHeader = block
        return self
    }
    
    fileprivate var deselectAfterward: Bool = true
    
    @discardableResult
    open func keepSelection() -> Self {
        deselectAfterward = false
        return self
    }
    
    fileprivate var _editingStyle: ((Int) -> UITableViewCell.EditingStyle)?
    
    @discardableResult
    open func editingStyle(_ block: @escaping (Int) -> UITableViewCell.EditingStyle) -> Self {
        _editingStyle = block
        return self
    }
    
    open func willSetTableView(_ tableView: UITableView) {
    }
    
    open func didSetTableView(_ tableView: UITableView) {
    }
    
    open var source: [T] {
        get { return data }
        set(value) {
            if reversed {
                data = Array(value.reversed())
            } else {
                data = value
            }
            onSourceChanged()
        }
    }
    
    open func applyChanges(_ changes: [Change<T>], animated: Bool = true) {
        if animated {
            tableView?.beginUpdates()
        }
        changes.forEach(_applyChange)
        if animated {
            tableView?.endUpdates()
        }
    }
    
    fileprivate func _applyChange(_ change: Change<T>) {
        switch change.type {
        case .create:
            let index = reversed ? 0 : data.count
            tableView?.insertRows(at: [IndexPath(row: index, section: section)], with: reversed ? .top : .bottom)
            data.insert(change.value, at: index)
        case .update:
            if let index = data.firstIndex(of: change.value) {
                tableView?.reloadRows(at: [IndexPath(row: index, section: section)], with: .automatic)
                data[index] = change.value
            }
        case .delete:
            if let index = data.firstIndex(of: change.value) {
                tableView?.deleteRows(at: [IndexPath(row: index, section: section)], with: .automatic)
                data.remove(at: index)
            }
        }
    }
    
    open func applyChange(_ change: Change<T>, animated: Bool = true) {
        if animated {
            tableView?.beginUpdates()
        }
        _applyChange(change)
        if animated {
            tableView?.endUpdates()
        }
    }
    
    func onSourceChanged() {
    }
    
    @discardableResult
    open func onSelect(_ block: @escaping (T, Int) -> UIViewController?) -> Self {
        select = block
        return self
    }
    
    @discardableResult
    open func onSelect(_ block: @escaping (T) -> UIViewController?) -> Self {
        select = { (t, _) in block(t) }
        return self
    }
    
    required public init(title: String?) {
        self.title = title
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell! {
        return nil
    }
    
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.title != nil {
            var height: CGFloat = 44
            if let view = renderHeader?(title!) {
                let size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
                height = size.height
            }
            return height
        }
        return 0
    }
    
    open func tableView(_ tableView: UITableView, editingStyleForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return _editingStyle?((indexPath as NSIndexPath).row) ?? .delete
    }
    
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return renderHeader?(title!)
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        if deselectAfterward {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        if let vc = select?(data[(indexPath as NSIndexPath).row], (indexPath as NSIndexPath).row) {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    open func tableView(_ tableView: UITableView, moveRowAtIndexPath sourceIndexPath: IndexPath, toIndexPath destinationIndexPath: IndexPath) {
        let object = data.remove(at: (sourceIndexPath as NSIndexPath).row)
        data.insert(object, at: (destinationIndexPath as NSIndexPath).row)
    }
    
    open func tableView(_ tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: IndexPath) {
    }
}

open class TableViewDataNib<T: Equatable, U: UITableViewCell>: TableViewData<T, U> where U: TableViewDataNibCell {
    public required init(title: String?) {
        super.init(title: title)
    }
    
    open override func didSetTableView(_ tableView: UITableView) {
        cellIdentifier = "\(U.nibName)-\(section)"
        let nib = UINib(nibName: U.nibName, bundle: Bundle(for: U.self))
        print("\(self) register cell \(String(describing: cellIdentifier)) \(nib)")
        tableView.register(nib, forCellReuseIdentifier: cellIdentifier)
    }
}

public protocol TableViewDataCustomizeRegister {
    static func register(_ tableView: UITableView)
    static var defaultIdentifier: String { get }
}

open class TableViewDataCombine<T: Equatable, U: UITableViewCell>: TableViewData<T, U> where U: TableViewDataCustomizeRegister {
    
    public required init(title: String?) {
        super.init(title: title)
    }
    
    open override func willSetTableView(_ tableView: UITableView) {
        cellIdentifier = Cell.defaultIdentifier
    }
    
    open override func didSetTableView(_ tableView: UITableView) {
        Cell.register(tableView)
    }
}

open class TableViewData<T: Equatable, U: UITableViewCell>: TableViewSource<T> {
    typealias Cell = U
    open var alwaysDisplaySectionHeader = false
    var className: String?
    open var cellIdentifier: String!
    fileprivate var willDisplay: ((U, Int) -> Void)?
    fileprivate var preRender: ((U) -> Void)?
    fileprivate var renderCell: ((U, T, ()->()) -> Void)?
    fileprivate var postRender: ((U, Int) -> Void)?
    fileprivate var placeholder: U!
    fileprivate var rendering_cache: [String: Data] = [:]
    
    open override func didSetTableView(_ tableView: UITableView) {
        cellIdentifier = cellIdentifier ?? "\(className!)-\(section)"
        print("\(self) register cell \(String(describing: cellIdentifier))")
        _tableView?.register(U.self, forCellReuseIdentifier: cellIdentifier)
    }
    
    var identifier: ((T) -> (String))?
    
    @discardableResult
    open func interceptIdentifier(_ closure: @escaping ((T) -> (String))) -> Self {
        identifier = closure
        return self
    }
    
    func render(_ cell: U, index: Int) {
        let object = data[index]
        if let c = cacheKey {
            let key = c(object)
            let data = rendering_cache[key]
            if data == nil {
                renderCell?(cell, object) {[weak self] in
                    let mdata = NSMutableData()
                    let coder = NSKeyedArchiver(forWritingWith: mdata)
                    cell.encodeRestorableState(with: coder)
                    coder.finishEncoding()
                    self?.rendering_cache[key] = mdata as Data
                }
            } else {
                let coder = NSKeyedUnarchiver(forReadingWith: data!)
                cell.decodeRestorableState(with: coder)
            }
        } else {
            renderCell?(cell, object) {}
        }
    }
    
    public required init(title: String?) {
        super.init(title: title)
        className = "\(NSStringFromClass(U.self))"
    }
    
    @discardableResult
    open func willDisplay(_ block: @escaping (_ cell: U, _ row: Int) -> Void) -> Self {
        willDisplay = block
        return self
    }
    
    @discardableResult
    open func preRender(_ block: @escaping (_ cell: U) -> Void) -> Self {
        preRender = block
        return self
    }
    
    @discardableResult
    open func onRender(_ block: @escaping (_ cell: U, _ object: T) -> Void) -> Self {
        renderCell = {
            block($0, $1)
            $2()
        }
        return self
    }
    
    @discardableResult
    open func postRender(_ block: @escaping (_ cell: U, _ row: Int) -> Void) -> Self {
        postRender = block
        return self
    }
    
    var didChange: (() -> Void)?
    
    @discardableResult
    open func didChange(_ block: @escaping () -> Void) -> Self {
        didChange = block
        return self
    }
    
    @discardableResult
    open func onFutureRender(_ render: @escaping (U, T, ()->()) -> Void) -> Self {
        renderCell = render
        return self
    }
    
    var rowAnimation = UITableView.RowAnimation.none
    
    override func onSourceChanged() {
        didChange?()
        switch rowAnimation {
        case .none:
            self.tableView?.reloadData()
        default:
            self.tableView?.reloadSections(IndexSet(integer: section), with: rowAnimation)
        }
    }
    
    fileprivate override func _applyChange(_ change: Change<T>) {
        super._applyChange(change)
        didChange?()
    }
    
    open override func tableView(_ tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    open override func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let object = data[(indexPath as NSIndexPath).row]
        let id = identifier?(object) ?? cellIdentifier
        let cell = tableView.dequeueReusableCell(withIdentifier: id!, for: indexPath) as! Cell
        cell.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: reversed ? -1 : 1, tx: 0, ty: 0)
        cell.layoutMargins = .zero
        preRender?(cell)
        render(cell, index: (indexPath as NSIndexPath).row)
        postRender?(cell, (indexPath as NSIndexPath).row)
        return cell
    }
    
    open override func tableView(_ tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: IndexPath) {
        willDisplay?(cell as! Cell, (indexPath as NSIndexPath).row)
    }
}

class TableViewJoinedData: NSObject, UITableViewDataSource, UITableViewDelegate {
    var joined: [SectionData]
    var alwaysDisplaySectionHeader: Bool
    weak var scrollViewDelegate: UIScrollViewDelegate?
    
    init(_ tableView: UITableView, sections: [SectionData], alwaysDisplaySectionHeader: Bool, reversed: Bool, scrollViewDelegate: UIScrollViewDelegate? = nil) {
        joined = sections
        self.scrollViewDelegate = scrollViewDelegate
        self.alwaysDisplaySectionHeader = alwaysDisplaySectionHeader
        for (index, var obj) in sections.enumerated() {
            obj.section = index
            obj.reversed = reversed
            obj.tableView = tableView
        }
        super.init()
        tableView.estimatedRowHeight = 80
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollViewDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewWillBeginDragging?(scrollView)
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollViewDelegate?.scrollViewWillBeginZooming?(scrollView, with: view)
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollViewDelegate?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return scrollViewDelegate?.scrollViewShouldScrollToTop?(scrollView) ?? true
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollViewDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidScrollToTop?(scrollView)
    }
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidScroll?(scrollView)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewDelegate?.scrollViewDidZoom?(scrollView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return joined.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return joined[section].tableView(tableView, numberOfRowsInSection: section)
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        joined[(sourceIndexPath as NSIndexPath).section].tableView(tableView, moveRowAtIndexPath: sourceIndexPath, toIndexPath: destinationIndexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if !alwaysDisplaySectionHeader && joined[section].tableView(tableView, numberOfRowsInSection: section) == 0 {
            return 0
        }
        return joined[section].tableView(tableView, heightForHeaderInSection: section)
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return joined[section].tableView(tableView, viewForHeaderInSection: section)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return joined[(indexPath as NSIndexPath).section].tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return joined[(indexPath as NSIndexPath).section].tableView(tableView, cellForRowAtIndexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        joined[(indexPath as NSIndexPath).section].tableView(tableView, didSelectRowAtIndexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        joined[(indexPath as NSIndexPath).section].tableView(tableView, willDisplayCell: cell, forRowAtIndexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return joined[(indexPath as NSIndexPath).section].tableView(tableView, editingStyleForRowAtIndexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

private var joinedAssociationKey: Void?
extension NSObject {
    fileprivate var _joined_sections: [String: TableViewJoinedData] {
        get {
            if let cache = objc_getAssociatedObject(self, &joinedAssociationKey) as? [String: TableViewJoinedData] {
                return cache
            } else {
                let newValue: [String: TableViewJoinedData] = [:]
                objc_setAssociatedObject(self, &joinedAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
                return newValue
            }
        }
        set(newValue) {
            objc_setAssociatedObject(self, &joinedAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public func connectTableView(_ tableView: UITableView, sections: [SectionData], alwaysDisplaySectionHeader: Bool = false, key: String = "default", reversed: Bool = false, navigationController: UINavigationController?, scrollViewDelegate: UIScrollViewDelegate? = nil) {
        if let joinedData = _joined_sections[key] {
            for (var data) in joinedData.joined {
                data.tableView = nil
            }
        }
        
        if reversed {
            tableView.transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 0)
        }
        let joined = TableViewJoinedData(tableView, sections: sections, alwaysDisplaySectionHeader: alwaysDisplaySectionHeader, reversed: reversed, scrollViewDelegate: scrollViewDelegate)
        for (var section) in sections {
            section.navigationController = navigationController
        }
        _joined_sections[key] = joined
        tableView.reloadData()
    }
}

extension UIViewController {
    public func connectTableView(_ tableView: UITableView, sections: [SectionData], alwaysDisplaySectionHeader: Bool = false, key: String = "default") {
        super.connectTableView(tableView, sections: sections, alwaysDisplaySectionHeader: alwaysDisplaySectionHeader, key: key, navigationController: navigationController, scrollViewDelegate: self as? UIScrollViewDelegate)
    }
}
