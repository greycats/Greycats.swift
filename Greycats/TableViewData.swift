//
//  TableViewData.swift
//
//  Created by Rex Sheng on 1/29/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//

// available in pod 'Greycats', '~> 0.1.5'

import UIKit

private let skipHeightCalculation = UIDevice.currentDevice().systemVersion.compare("8.0", options: NSStringCompareOptions.NumericSearch) != .OrderedAscending

public protocol SectionData {
	var section: Int { get set }
	var tableView: UITableView? { get set }
	var reversed: Bool { get set }
	weak var navigationController: UINavigationController? { get set }
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell!
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
	func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
}

public protocol TableViewDataNibCell {
	static var nibName: String { get }
}

public enum ChangeType {
	case Create
	case Update
	case Delete
}

public struct Change<T: Equatable> {
	let value: T
	let type: ChangeType
	public init(type: ChangeType, value: T) {
		self.type = type
		self.value = value
	}
}

public class TableViewSource<T: Equatable>: SectionData {
	typealias Element = T
	private var data: [T] = []
	private var select: ((T) -> UIViewController?)?
	public var cacheKey: (T -> String)?
	private weak var _tableView: UITableView?
	public var reversed: Bool = false
	public var section: Int = 0
	public var tableView: UITableView? {
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
	public weak var navigationController: UINavigationController?
	private var title: String?
	private var renderHeader: (String -> UIView)?
	public func onHeader(block: String -> UIView) -> Self {
		renderHeader = block
		return self
	}
	
	public func willSetTableView(tableView: UITableView) {
	}
	
	public func didSetTableView(tableView: UITableView) {
	}
	
	public var source: [T] {
		get { return data }
		set(value) {
			if reversed {
				data = value.reverse()
			} else {
				data = value
			}
			onSourceChanged()
		}
	}
	
	public func applyChanges(changes: [Change<T>]) {
		tableView?.beginUpdates()
		changes.map(self._applyChange)
		tableView?.endUpdates()
	}
	
	private func _applyChange(change: Change<T>) {
		switch change.type {
		case .Create:
			let index = reversed ? 0 : data.count
			tableView?.insertRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: section)], withRowAnimation: reversed ? .Top : .Bottom)
			if data.count > 0 {
				tableView?.reloadRowsAtIndexPaths([NSIndexPath(forRow: reversed ? 0 : data.count - 1, inSection: section)], withRowAnimation: .Automatic)
			}
			data.insert(change.value, atIndex: index)
		case .Update:
			if let index = find(data, change.value) {
				tableView?.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: section)], withRowAnimation: .Automatic)
				data[index] = change.value
			}
		case .Delete:
			if let index = find(data, change.value) {
				tableView?.deleteRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: section)], withRowAnimation: .Automatic)
				data.removeAtIndex(index)
			}
		}
	}
	
	public func applyChange(change: Change<T>) {
		tableView?.beginUpdates()
		_applyChange(change)
		tableView?.endUpdates()
	}
	
	func onSourceChanged() {
	}
	
	public func onSelect(block: (T) -> UIViewController?) -> Self {
		select = block
		return self
	}
	
	required public init(title: String?) {
		self.title = title
	}
	
	public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return data.count
	}
	
	public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
	}
	
	public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell! {
		return nil
	}
	
	public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if self.title != nil {
			var height: CGFloat = 44
			if let view = renderHeader?(title!) {
				let size = view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
				height = size.height
			}
			return height
		}
		return 0
	}
	
	public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		return renderHeader?(title!)
	}
	
	public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		if let vc = select?(data[indexPath.row]) {
			navigationController?.pushViewController(vc, animated: true)
		}
	}
	
	public func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
	}
}

public class TableViewDataNib<T: Equatable, U: UITableViewCell where U: TableViewDataNibCell>: TableViewData<T, U> {
	public required init(title: String?) {
		super.init(title: title)
	}
	
	public override func didSetTableView(tableView: UITableView) {
		cellIdentifier = "\(U.nibName)-\(section)"
		tableView.registerNib(UINib(nibName: U.nibName, bundle: NSBundle(forClass: U.self)), forCellReuseIdentifier: cellIdentifier)
	}
}

public protocol TableViewDataCustomizeRegister {
	static func register(tableView: UITableView)
	static var defaultIdentifier: String { get }
}

public class TableViewDataCombine<T: Equatable, U: UITableViewCell where U: TableViewDataCustomizeRegister>: TableViewData<T, U> {
	
	public required init(title: String?) {
		super.init(title: title)
	}
	
	public override func willSetTableView(tableView: UITableView) {
		cellIdentifier = Cell.defaultIdentifier
	}
	
	public override func didSetTableView(tableView: UITableView) {
		Cell.register(tableView)
	}
}

public class TableViewData<T: Equatable, U: UITableViewCell>: TableViewSource<T> {
	typealias Cell = U
	public var alwaysDisplaySectionHeader = false
	var className: String?
	public var cellIdentifier: String!
	private var willDisplay: ((U, Int) -> Void)?
	private var preRender: (U -> Void)?
	private var renderCell: ((U, T, dispatch_block_t) -> Void)?
	private var postRender: ((U, Int) -> Void)?
	private var placeholder: U!
	private let rendering_cache = NSCache()
	
	public override func didSetTableView(tableView: UITableView) {
		cellIdentifier = cellIdentifier ?? "\(className!)-\(section)"
		println("\(self) register cell \(cellIdentifier)")
		_tableView?.registerClass(U.self, forCellReuseIdentifier: cellIdentifier)
	}
	
	var identifier: ((T) -> (String))?
	public func interceptIdentifier(closure: ((T) -> (String))) -> Self {
		identifier = closure
		return self
	}
	
	func render(cell: U, index: Int) {
		let object = data[index]
		if let c = cacheKey {
			let key = c(object)
			var data = rendering_cache.objectForKey(key) as? NSData
			if data == nil {
				renderCell?(cell, object) {[weak self] _ in
					var mdata = NSMutableData()
					let coder = NSKeyedArchiver(forWritingWithMutableData: mdata)
					cell.encodeRestorableStateWithCoder(coder)
					coder.finishEncoding()
					self!.rendering_cache.setObject(mdata, forKey: key)
					if !skipHeightCalculation {
						self!._tableView?.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: self!.section)], withRowAnimation: .None)
					}
				}
			} else {
				let coder = NSKeyedUnarchiver(forReadingWithData: data!)
				cell.decodeRestorableStateWithCoder(coder)
			}
		} else {
			renderCell?(cell, object) {}
		}
	}
	
	public required init(title: String?) {
		super.init(title: title)
		className = "\(NSStringFromClass(U))"
	}
	
	public func willDisplay(block: (cell: U, row: Int) -> Void) -> Self {
		willDisplay = block
		return self
	}
	
	public func preRender(block: (cell: U) -> Void) -> Self {
		preRender = block
		return self
	}
	
	public func onRender(block: (cell: U, object: T) -> Void) -> Self {
		renderCell = {
			block(cell: $0, object: $1)
			$2()
		}
		return self
	}
	
	public func postRender(block: (cell: U, row: Int) -> Void) -> Self {
		postRender = block
		return self
	}
	
	public func onFutureRender(render: (U, T, dispatch_block_t) -> Void) -> Self {
		renderCell = render
		return self
	}
	
	var rowAnimation = UITableViewRowAnimation.None
	
	override func onSourceChanged() {
		switch rowAnimation {
		case .None:
			self.tableView?.reloadData()
		default:
			self.tableView?.reloadSections(NSIndexSet(index: section), withRowAnimation: rowAnimation)
		}
	}
	
	public override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		if skipHeightCalculation {
			return UITableViewAutomaticDimension
		}
		if placeholder == nil {
			let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! Cell
			if skipHeightCalculation {
				cell.layoutMargins = UIEdgeInsetsZero
			}
			placeholder = cell
			placeholder.setTranslatesAutoresizingMaskIntoConstraints(false)
		}
		preRender?(placeholder)
		render(placeholder, index: indexPath.row)
		placeholder.setNeedsLayout()
		placeholder.layoutIfNeeded()
		let height = CGFloat(ceil(placeholder.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height)) + 0.5
		return height
	}
	
	public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let object = data[indexPath.row]
		let id = identifier?(object) ?? cellIdentifier
		let cell = tableView.dequeueReusableCellWithIdentifier(id!, forIndexPath: indexPath) as! Cell
		cell.transform = CGAffineTransformMake(1, 0, 0, reversed ? -1 : 1, 0, 0)
		if skipHeightCalculation {
			cell.layoutMargins = UIEdgeInsetsZero
		}
		preRender?(cell)
		render(cell, index: indexPath.row)
		postRender?(cell, indexPath.row)
		return cell
	}
	
	public override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		willDisplay?(cell as! Cell, indexPath.row)
	}
}

class TableViewJoinedData: NSObject, UITableViewDataSource, UITableViewDelegate {
	var joined: [SectionData]
	var alwaysDisplaySectionHeader: Bool
	
	init(_ tableView: UITableView, sections: [SectionData], alwaysDisplaySectionHeader: Bool, reversed: Bool) {
		joined = sections
		self.alwaysDisplaySectionHeader = alwaysDisplaySectionHeader
		for (index, var obj) in enumerate(sections) {
			obj.section = index
			obj.reversed = reversed
			obj.tableView = tableView
		}
		super.init()
		if skipHeightCalculation {
			tableView.estimatedRowHeight = 80
		}
		tableView.delegate = self
		tableView.dataSource = self
	}
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return joined.count
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return joined[section].tableView(tableView, numberOfRowsInSection: section)
	}
	
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if !alwaysDisplaySectionHeader && joined[section].tableView(tableView, numberOfRowsInSection: section) == 0 {
			return 0
		}
		return joined[section].tableView(tableView, heightForHeaderInSection: section)
	}
	
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		return joined[section].tableView(tableView, viewForHeaderInSection: section)
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return joined[indexPath.section].tableView(tableView, heightForRowAtIndexPath: indexPath)
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return joined[indexPath.section].tableView(tableView, cellForRowAtIndexPath: indexPath)
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		joined[indexPath.section].tableView(tableView, didSelectRowAtIndexPath: indexPath)
	}
	
	func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		joined[indexPath.section].tableView(tableView, willDisplayCell: cell, forRowAtIndexPath: indexPath)
	}
}

private var joinedAssociationKey: UInt8 = 0x01

extension NSObject {
	private var _joined_sections: [String: TableViewJoinedData] {
		get {
			if let cache = objc_getAssociatedObject(self, &joinedAssociationKey) as? [String: TableViewJoinedData] {
				return cache
			} else {
				var newValue: [String: TableViewJoinedData] = [:]
				objc_setAssociatedObject(self, &joinedAssociationKey, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN))
				return newValue
			}
		}
		set(newValue) {
			objc_setAssociatedObject(self, &joinedAssociationKey, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN))
		}
	}
	
	public func connectTableView(tableView: UITableView, sections: [SectionData], alwaysDisplaySectionHeader: Bool = false, key: String = "default", reversed: Bool = false, navigationController: UINavigationController?) {
		if let joinedData = _joined_sections[key] {
			for (var data) in joinedData.joined {
				data.tableView = nil
			}
		}
		
		if reversed {
			tableView.transform = CGAffineTransformMake(1, 0, 0, -1, 0, 0)
		}
		let joined = TableViewJoinedData(tableView, sections: sections, alwaysDisplaySectionHeader: alwaysDisplaySectionHeader, reversed: reversed)
		for (var section) in sections {
			section.navigationController = navigationController
		}
		_joined_sections[key] = joined
		tableView.reloadData()
	}
}

extension UIViewController {
	public func connectTableView(tableView: UITableView, sections: [SectionData], alwaysDisplaySectionHeader: Bool = false, key: String = "default") {
		super.connectTableView(tableView, sections: sections, alwaysDisplaySectionHeader: alwaysDisplaySectionHeader, key: key, navigationController: navigationController)
	}
}