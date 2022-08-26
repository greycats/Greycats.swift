//
//  NavigationViewController.swift
//  tesla
//
//  Created by Rex Sheng on 4/25/16.
//  Copyright © 2016 Interactive Labs. All rights reserved.
//

import UIKit
private func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

private func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

/**
 intergration steps:
 
 1. drag a view controller into storyboard set its class to NavigationViewController
 2. create your navigationbar class, accept NavigationBarProtocol
 3. drag a view into your controller, and set it class to your navigationbar class, connect it to navigationBar outlet
 4. create a custom segue to your root view controller, select 'root view controller relationship', name it 'root'
 */
public protocol NavigationBarProtocol {
    var titleLabel: UILabel! { get set }
    var backButton: UIButton! { get set }
    var rightToolbar: UIToolbar! { get set }
    var navigationItem: UINavigationItem? { get set }
}

open class RootViewControllerRelationshipSegue: UIStoryboardSegue {
    override open func perform() {
        guard let source = source as? NavigationViewController else {
            return
        }
        source.childNavigationController?.viewControllers = [destination]
    }
}

public protocol NavigationBackProxy {
    func navigateBack(_ next: () -> Void)
}

public protocol Navigation {
    var hidesNavigationBarWhenPushed: Bool { get }
}

open class NavigationViewController: UIViewController, UINavigationControllerDelegate {
    @IBOutlet weak var navigationBar: UIView! {
        didSet {
            if let bar = navigationBar as? NavigationBarProtocol {
                self.bar = bar
            }
        }
    }

    var bar: NavigationBarProtocol?

    weak var childNavigationController: UINavigationController?

    fileprivate func reattach() {
        navigationBar.removeFromSuperview()
        view.addSubview(navigationBar)
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        reattach()
        bar?.backButton.addTarget(self, action: #selector(navigateBack(_:)), for: .touchUpInside)
        let childNavigationController = UINavigationController()
        childNavigationController.isNavigationBarHidden = true
        childNavigationController.delegate = self
        self.childNavigationController = childNavigationController
        addChild(childNavigationController)
        guard let container = childNavigationController.view else { return }
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        // H
        view.addConstraint(NSLayoutConstraint(item: navigationBar as Any, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: navigationBar as Any, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: container, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: container, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0))
        // V
        view.addConstraint(NSLayoutConstraint(item: navigationBar as Any, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: navigationBar as Any, attribute: .bottom, relatedBy: .equal, toItem: container, attribute: .top, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: container, attribute: .bottom, relatedBy: .equal, toItem: bottomLayoutGuide, attribute: .top, multiplier: 1, constant: 0))
        performSegue(withIdentifier: "root", sender: nil)
    }

    @IBAction func navigateBack(_ sender: Any) {
        if let proxy = childNavigationController?.topViewController as? NavigationBackProxy {
            proxy.navigateBack {[weak self] in
                _ = self?.childNavigationController?.popViewController(animated: true)
            }
        } else {
            _ = childNavigationController?.popViewController(animated: true)
        }
    }

    open func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        let showBackButton = childNavigationController?.viewControllers.count > 1
        var hides = false
        if let customNav = viewController as? Navigation {
            hides = customNav.hidesNavigationBarWhenPushed
        }
        UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
            self.navigationBar.alpha = hides ? 0 : 1
            self.bar?.navigationItem = viewController.navigationItem
            self.bar?.backButton.alpha = showBackButton ? 1 : 0
        })
    }
}
