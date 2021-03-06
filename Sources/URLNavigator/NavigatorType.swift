#if os(iOS) || os(tvOS)
import UIKit

#if !COCOAPODS
import URLMatcher
#endif

public typealias URLPattern = String
public typealias ViewControllerFactory = (_ url: URLConvertible, _ values: [String: Any], _ context: Any?) -> UIViewController?
public typealias URLOpenHandlerFactory = (_ url: URLConvertible, _ values: [String: Any], _ context: Any?) -> Bool
public typealias URLOpenHandler = () -> Bool

public protocol NavigatorType {
  var matcher: URLMatcher { get }
  weak var delegate: NavigatorDelegate? { get set }

  /// Registers a view controller factory to the URL pattern.
  func register(_ pattern: URLPattern, _ factory: @escaping ViewControllerFactory)

  func register(_ patterns: [URLPattern], _ factory: @escaping ViewControllerFactory)

  /// Registers an URL open handler to the URL pattern.
  func handle(_ pattern: URLPattern, _ factory: @escaping URLOpenHandlerFactory)
  
  func handle(_ patterns: [URLPattern], _ factory: @escaping URLOpenHandlerFactory)

  /// Returns a matching view controller from the specified URL.
  ///
  /// - parameter url: An URL to find view controllers.
  ///
  /// - returns: A match view controller or `nil` if not matched.
  func viewController(for url: URLConvertible, context: Any?) -> UIViewController?

  /// Returns a matching URL handler from the specified URL.
  ///
  /// - parameter url: An URL to find url handlers.
  ///
  /// - returns: A matching handler factory or `nil` if not matched.
  func handler(for url: URLConvertible, context: Any?) -> URLOpenHandler?

  @discardableResult
  func push(_ url: URLConvertible, context: Any?, from: UINavigationControllerType?, animated: Bool) -> UIViewController?

  @discardableResult
  func push(_ viewController: UIViewController, from: UINavigationControllerType?, animated: Bool) -> UIViewController?

  @discardableResult
  func present(_ url: URLConvertible, context: Any?, wrap: UINavigationController.Type?, from: UIViewControllerType?, animated: Bool, completion: (() -> Void)?) -> UIViewController?

  @discardableResult
  func present(_ viewController: UIViewController, wrap: UINavigationController.Type?, from: UIViewControllerType?, animated: Bool, completion: (() -> Void)?) -> UIViewController?

  @discardableResult
  func open(_ url: URLConvertible, context: Any?) -> Bool
}

extension NavigatorType {
  public func viewController(for url: URLConvertible) -> UIViewController? {
    return self.viewController(for: url, context: nil)
  }

  public func handler(for url: URLConvertible) -> URLOpenHandler? {
    return self.handler(for: url, context: nil)
  }

  @discardableResult
  public func push(_ url: URLConvertible, context: Any? = nil, from: UINavigationControllerType? = nil, animated: Bool = true) -> UIViewController? {
    guard let viewController = self.viewController(for: url, context: context) else { return nil }
    return self.push(viewController, from: from, animated: animated)
  }

  @discardableResult
  public func push(_ viewController: UIViewController, from: UINavigationControllerType? = nil, animated: Bool = true) -> UIViewController? {
    guard (viewController is UINavigationController) == false else { return nil }
    guard let navigationController = from ?? UIViewController.topMost?.navigationController else { return nil }
    guard self.delegate?.shouldPush(viewController: viewController, from: navigationController) != false else { return nil }
    navigationController.pushViewController(viewController, animated: animated)
    return viewController
  }

  @discardableResult
  public func present(_ url: URLConvertible, context: Any? = nil, wrap: UINavigationController.Type? = nil, from: UIViewControllerType? = nil, animated: Bool = true, completion: (() -> Void)? = nil) -> UIViewController? {
    guard let viewController = self.viewController(for: url, context: context) else { return nil }
    return self.present(viewController, wrap: wrap, from: from, animated: animated, completion: completion)
  }

  @discardableResult
  public func present(_ viewController: UIViewController, wrap: UINavigationController.Type? = nil, from: UIViewControllerType? = nil, animated: Bool = true, completion: (() -> Void)? = nil) -> UIViewController? {
    guard let fromViewController = from ?? UIViewController.topMost else { return nil }

    let viewControllerToPresent: UIViewController
    if let navigationControllerClass = wrap, (viewController is UINavigationController) == false {
      viewControllerToPresent = navigationControllerClass.init(rootViewController: viewController)
    } else {
      viewControllerToPresent = viewController
    }

    guard self.delegate?.shouldPresent(viewController: viewController, from: fromViewController) != false else { return nil }
    fromViewController.present(viewControllerToPresent, animated: animated, completion: completion)
    return viewController
  }

  @discardableResult
  public func open(_ url: URLConvertible, context: Any? = nil) -> Bool {
    guard let handler = self.handler(for: url, context: context) else { return false }
    return handler()
  }
}
#endif
