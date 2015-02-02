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

struct Anchor {
	var title: String
	
	init(title: String) {
		self.title = title
	}
}

let docs = (0...2).map { Document(name: "document.\($0)") }
let sitemap = ["iOS 8", "OS X Yosemite", "Swift", "Xcode 6", "iOS Dev Center", "Mac Dev Center", "Safari Dev Center", "App Store", "iAd", "iCloud", "Forums", "Videos", "Licensing and Trademarks", "Hardware and Drivers", "iPod, iPhone, and iPad Cases", "Open Source", "iOS Developer Program", "iOS Developer Enterprise Program", "iOS Developer University Program", "Mac Developer Program", "Safari Developer Program", "MFi Program", "iOS Developer Program", "Mac Developer Program", "Safari Developer Program", "App Store", "iTunes Connect", "Technical Support"].map { Anchor(title: $0) }

class DemoViewController: UIViewController {
	
	let tableView = UITableView()
	let filter = FilterTextFieldDelegate()
	
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
	
	let sitemapData = TableViewData<Anchor, UITableViewCell>(title: "Sitemap")
		.onRender { (cell, object) -> Void in
			cell.textLabel!.text = "\(object.title)"
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
		let filterField = UITextField(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 40))
		filterField.placeholder = "Search"
		filterField.delegate = filter
		tableView.tableHeaderView = filterField
		tableView.autoresizingMask = .FlexibleHeight | .FlexibleWidth
		view.addSubview(tableView)
		connectTableView(tableView, sections: [docsData, sitemapData])
		
		filter.onChange {string in
			self.docsData.source = Filter.WordSequences.apply(string, objects: docs, {$0.name})
			self.sitemapData.source = Filter.Contains.apply(string, objects: sitemap, {$0.title})
		}
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		delay(0.2) {
			self.docsData.source = docs
			self.sitemapData.source = sitemap
		}
		
		delay(1.2) {
			self.filter.search("OS")
		}
	}
}


XCPShowView("Demo", DemoViewController().view)
