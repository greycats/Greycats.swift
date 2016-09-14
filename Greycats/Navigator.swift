import UIKit

public protocol Navigatable {
    func canGoBack() -> Bool
    func goBack()
    func navigatableChanged(_ listener: () -> Void)
}

extension UIViewController {
    @IBAction public func navigateBack() {
        goBack()
    }

    public func canGoBack() -> Bool {
        guard let navigationController = navigationController else {
            return false
        }
        if let index = navigationController.viewControllers.index(of: self) , index > 0 {
            return true
        }
        return false
    }

    public func goBack() {
        guard let navigationController = navigationController else {
            return
        }
        if let index = navigationController.viewControllers.index(of: self) , index > 0 {
            navigationController.popToViewController(navigationController.viewControllers[index - 1], animated: true)
        }
    }
}

public protocol BarActionProvider {
    func actionView(forBar bar: NavigationBar) -> UIView?
}

@IBDesignable
open class NavigationBar: NibView {
    @IBOutlet open weak var actionContainer: UIView!
    @IBOutlet open weak var leftButtonsContainer: UIView!
    @IBOutlet open weak var rightButtonsContainer: UIView!
    open weak var navigationItem: UINavigationItem!
}

open class NavigationController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet open weak var navigationBar: NavigationBar!

    weak var customizedActionView: UIView?

    override open func viewDidLoad() {
        super.viewDidLoad()
        for child in childViewControllers {
            if let child = child as? UINavigationController {
                child.delegate = self
            }
        }
    }

    open func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        navigationBar.navigationItem = viewController.navigationItem

        // customize action view
        customizedActionView?.removeFromSuperview()
        if let provider = viewController as? BarActionProvider {
            if let view = provider.actionView(forBar: navigationBar) {
                navigationBar.actionContainer.addSubview(view)
                view.fullDimension()
                customizedActionView = view
            }
        }

        navigationBar.leftButtonsContainer.isHidden = navigationController.viewControllers.count == 1
        weak var handler = viewController
        if let viewController = viewController as? Navigatable {
            viewController.navigatableChanged {[weak self] in
                guard let handler = handler else {
                    return
                }
                if handler == navigationController.topViewController {
                    self?.navigationBar.leftButtonsContainer.isHidden = !handler.canGoBack() && navigationController.viewControllers.count == 1
                }
            }
        }
    }
}
