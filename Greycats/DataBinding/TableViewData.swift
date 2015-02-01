//
//  TableViewData.swift
//
//  Created by Rex Sheng on 1/29/15.
//  Copyright (c) 2015 iLabs. All rights reserved.
//
import UIKit

public protocol SectionData: NSObjectProtocol {
	var section: Int {get set}
	var tableView: UITableView? {get set}
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) -> UIViewController?
}

public class TableViewData<T, U: UITableViewCell>: NSObject, SectionData {
	typealias Element = T
	typealias Cell = U
	
	private var data: [T] = []
	private var renderCell: ((Cell, T) -> Void)?
	private var select: ((T) -> UIViewController?)?
	private var renderHeader: ((String) -> UIView?)?
	private var title: String?
	
	public var section: Int = 0
	
	private weak var _tableView: UITableView?
	public var cellIdentifier = "cell"

	public var tableView: UITableView? {
		set(t) {
			_tableView = t
			_tableView?.registerClass(U.self, forCellReuseIdentifier: cellIdentifier)
		}
		get {
			return _tableView
		}
	}
	
	public required init(title: String?) {
		self.title = title
		cellIdentifier = "\(NSStringFromClass(U))"
		super.init()
	}
	
	public func onRender(block: (cell: U, object: T) -> Void) -> Self {
		renderCell = block
		return self
	}
	
	public func onSelect(block: (T) -> UIViewController?) -> Self {
		select = block
		return self
	}
	
	public func onHeader(block: (String) -> UIView?) -> Self {
		renderHeader = block
		return self
	}
	
	public var source: [T] {
		set(data) {
			self.data = data
			self.tableView?.reloadSections(NSIndexSet(index: section), withRowAnimation: .Automatic)
		}
		get {
			return self.data
		}
	}
	
	public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return data.count
	}
	
	public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as Cell
		renderCell?(cell, data[indexPath.row])
		return cell
	}
	
	public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		if self.title != nil {
			return 40
		}
		return 0
	}
	
	public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		return renderHeader?(title!)
	}
	
	public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) -> UIViewController? {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		return select?(data[indexPath.row])
	}
}

class TableViewJoinedData: NSObject, UITableViewDataSource, UITableViewDelegate {
	var joined: [SectionData]
	private weak var viewController: UIViewController?
	
	init(tableView: UITableView, sections: [SectionData]) {
		joined = sections
		for (index, obj) in enumerate(sections) {
			obj.section = index
			obj.tableView = tableView
		}
		super.init()
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
		return joined[section].tableView(tableView, heightForHeaderInSection: section)
	}
	
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		return joined[section].tableView(tableView, viewForHeaderInSection: section)
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return joined[indexPath.section].tableView(tableView, cellForRowAtIndexPath: indexPath)
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if let vc = joined[indexPath.section].tableView(tableView, didSelectRowAtIndexPath: indexPath) {
			viewController?.navigationController?.pushViewController(vc, animated: true)
		}
	}
}

private var joinedAssociationKey: UInt8 = 0

extension UIViewController {

	var _joined_sections: TableViewJoinedData! {
		get {
			return objc_getAssociatedObject(self, &joinedAssociationKey) as? TableViewJoinedData
		}
		set(newValue) {
			objc_setAssociatedObject(self, &joinedAssociationKey, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN))
		}
	}
	
	public func connectTableView(tableView: UITableView, sections: [SectionData]) {
		let joined = TableViewJoinedData(tableView: tableView, sections: sections)
		joined.viewController = self
		_joined_sections = joined
	}
}
