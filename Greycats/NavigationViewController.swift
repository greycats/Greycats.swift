//
//  NavigationViewController.swift
//  tesla
//
//  Created by Rex Sheng on 4/25/16.
//  Copyright © 2016 Interactive Labs. All rights reserved.
//

import UIKit

public protocol NavigationBarProtocol {
	var titleLabel: UILabel! {get set}
	var backButton: UIButton! {get set}
	var rightToolbar: UIToolbar! {get set}
	var navigationItem: UINavigationItem? {get set}
}

public class RootViewControllerRelationshipSegue: UIStoryboardSegue {
	override public func perform() {
		guard let source = sourceViewController as? NavigationViewController else {
			return
		}
		source.childNavigationController?.viewControllers = [destinationViewController]
	}
}

public protocol NavigationBackProxy {
	func navigateBack(next: () ->())
}

public class NavigationViewController: UIViewController, UINavigationControllerDelegate {
	@IBOutlet weak var navigationBar: UIView! {
		didSet {
			if let bar = navigationBar as? NavigationBarProtocol {
				self.bar = bar
			}
		}
	}

	var bar: NavigationBarProtocol?

	weak var childNavigationController: UINavigationController?

	private func reattach() {
		navigationBar.removeFromSuperview()
		view.addSubview(navigationBar)
		navigationBar.translatesAutoresizingMaskIntoConstraints = false
	}

	override public func viewDidLoad() {
		super.viewDidLoad()
		reattach()
		bar?.backButton.addTarget(self, action: #selector(navigateBack), forControlEvents: .TouchUpInside)
		let childNavigationController = UINavigationController()
		childNavigationController.navigationBarHidden = true
		childNavigationController.delegate = self
		self.childNavigationController = childNavigationController
		addChildViewController(childNavigationController)
		let container = childNavigationController.view
		container.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(container)

		//H
		view.addConstraint(NSLayoutConstraint(item: navigationBar, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1, constant: 0))
		view.addConstraint(NSLayoutConstraint(item: navigationBar, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1, constant: 0))
		view.addConstraint(NSLayoutConstraint(item: container, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1, constant: 0))
		view.addConstraint(NSLayoutConstraint(item: container, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1, constant: 0))
		//V
		view.addConstraint(NSLayoutConstraint(item: navigationBar, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1, constant: 0))
		view.addConstraint(NSLayoutConstraint(item: navigationBar, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0, constant: 82))
		view.addConstraint(NSLayoutConstraint(item: navigationBar, attribute: .Bottom, relatedBy: .Equal, toItem: container, attribute: .Top, multiplier: 1, constant: 0))
		view.addConstraint(NSLayoutConstraint(item: container, attribute: .Bottom, relatedBy: .Equal, toItem: bottomLayoutGuide, attribute: .Top, multiplier: 1, constant: 0))
		performSegueWithIdentifier("root", sender: nil)
	}

	@IBAction func navigateBack(sender: AnyObject) {
		if let proxy = childNavigationController?.topViewController as? NavigationBackProxy {
			proxy.navigateBack {[weak self] in
				self?.childNavigationController?.popViewControllerAnimated(true)
			}
		} else {
			childNavigationController?.popViewControllerAnimated(true)
		}
	}

	public func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
		let showBackButton = childNavigationController?.viewControllers.count > 1
		UIView.animateWithDuration(animated ? 0.25 : 0) {
			self.bar?.navigationItem = viewController.navigationItem
			self.bar?.backButton.alpha = showBackButton ? 1 : 0
		}
	}
}