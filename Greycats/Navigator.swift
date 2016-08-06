import UIKit

public protocol Navigatable {
    func canGoBack() -> Bool
    func goBack()
    func navigatableChanged(listener: () -> Void)
}

extension UIViewController {
    @IBAction public func navigateBack() {
        goBack()
    }

    public func canGoBack() -> Bool {
        guard let navigationController = navigationController else {
            return false
        }
        if let index = navigationController.viewControllers.indexOf(self) where index > 0 {
            return true
        }
        return false
    }

    public func goBack() {
        guard let navigationController = navigationController else {
            return
        }
        if let index = navigationController.viewControllers.indexOf(self) where index > 0 {
            navigationController.popToViewController(navigationController.viewControllers[index - 1], animated: true)
        }
    }
}

public protocol BarActionProvider {
    func provideActionView(forBar bar: NavigationBar) -> UIView
}

@IBDesignable
public class NavigationBar: NibView {
    @IBOutlet public weak var actionContainer: UIView!
    @IBOutlet public weak var leftButtonsContainer: UIView!
    @IBOutlet public weak var rightButtonsContainer: UIView!
    public weak var navigationItem: UINavigationItem!
}

public class NavigationController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet public weak var navigationBar: NavigationBar!

    weak var customizedActionView: UIView?

    override public func viewDidLoad() {
        super.viewDidLoad()
        for child in childViewControllers {
            if let child = child as? UINavigationController {
                child.delegate = self
            }
        }
    }

    public func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        navigationBar.navigationItem = viewController.navigationItem

        // customize action view
        customizedActionView?.removeFromSuperview()
        if let provider = viewController as? BarActionProvider {
            let view = provider.provideActionView(forBar: navigationBar)
            navigationBar.actionContainer.addSubview(view)
            view.fullDimension()
            customizedActionView = view
        }

        navigationBar.leftButtonsContainer.hidden = navigationController.viewControllers.count == 1
        weak var handler = viewController
        if let viewController = viewController as? Navigatable {
            viewController.navigatableChanged {[weak self] in
                guard let handler = handler else {
                    return
                }
                if handler == navigationController.topViewController {
                    self?.navigationBar.leftButtonsContainer.hidden = !handler.canGoBack() && navigationController.viewControllers.count == 1
                }
            }
        }
    }
}
