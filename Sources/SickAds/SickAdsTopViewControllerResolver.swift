import UIKit

enum SickAdsTopViewControllerResolver {
    static func current() -> UIViewController? {
        guard
            let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let root = scene.sickads_keyWindow?.rootViewController
        else { return nil }
        return topMost(from: root)
    }

    private static func topMost(from base: UIViewController) -> UIViewController {
        if let nav = base as? UINavigationController {
            return topMost(from: nav.visibleViewController ?? base)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topMost(from: selected)
        }
        if let presented = base.presentedViewController {
            return topMost(from: presented)
        }
        return base
    }
}

private extension UIWindowScene {
    var sickads_keyWindow: UIWindow? {
        windows.first { $0.isKeyWindow }
    }
}
