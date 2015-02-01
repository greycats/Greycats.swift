// Playground - noun: a place where people can play

import UIKit
import XCPlayground
import Greycats

func delay(delay: Double, closure: dispatch_block_t) {
	dispatch_after(
		dispatch_time(
			DISPATCH_TIME_NOW,
			Int64(delay * Double(NSEC_PER_SEC))
		),
		dispatch_get_main_queue(), closure)
}


struct Document {
	var name: String
	
	init(name: String) {
		self.name = name
	}
}

struct Story {
	var location: String
	var time: NSDate
	
	init(location: String, time: NSDate) {
		self.location = location
		self.time = time
	}
}

let docs = (0...2).map { Document(name: "document.\($0)") }
let stories = (0...9).map { _ in
	Story(location: "location", time: NSDate())
}

class DemoViewController: UIViewController {
	
	let tableView = UITableView()
	
	let docsData = TableViewData<Document, UITableViewCell>(title: "Documents")
		.onRender { (cell, object) -> Void in
			cell.textLabel!.text = object.name
		}
		.onHeader { (title) -> UIView? in
			let header = UILabel()
			header.text = title
			header.backgroundColor = UIColor.grayColor()
			header.textColor = UIColor.whiteColor()
			return header
	}
	
	let storiesData = TableViewData<Story, UITableViewCell>(title: "Stories")
		.onRender { (cell, object) -> Void in
			cell.textLabel!.text = "\(object.time) at \(object.location)"
		}
		.onHeader { (title) -> UIView? in
			let header = UILabel()
			header.text = title
			header.backgroundColor = UIColor.grayColor()
			header.textColor = UIColor.whiteColor()
			return header
	}
	
	override func viewDidLoad() {
		tableView.frame = view.bounds
		view.layer.borderWidth = 0.5
		tableView.autoresizingMask = .FlexibleHeight | .FlexibleWidth
		view.addSubview(tableView)
		connectTableView(tableView, sections: [docsData, storiesData])
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		delay(0.2) {
			self.docsData.source = docs
			self.storiesData.source = stories
		}
	}
}

XCPShowView("Demo", DemoViewController().view)
