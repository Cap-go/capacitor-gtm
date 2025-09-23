import Foundation
import ObjectiveC.runtime

private enum GTMErrorFactory {
    static func make(_ message: String, code: Int = -1) -> NSError {
        NSError(domain: "GoogleTagManager", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

private enum GTMRuntime {
    static func classNamed(_ name: String) -> AnyClass? {
        NSClassFromString(name)
    }

    static func classResponds(_ cls: AnyClass, to selector: Selector) -> Bool {
        guard let meta = object_getClass(cls) else { return false }
        return class_respondsToSelector(meta, selector)
    }

    static func instanceResponds(_ instance: AnyObject, to selector: Selector) -> Bool {
        return (instance as? NSObject)?.responds(to: selector) ?? false
    }
}

@objc public final class GTMManager: NSObject {
    private var tagManager: NSObject?
    private var container: NSObject?
    private var initialized = false
    private var initializationCompletion: ((Bool, NSError?) -> Void)?

    private let openSelector = NSSelectorFromString("openContainerWithId:tagManager:openType:timeout:notifier:")
    private let pushSelector = NSSelectorFromString("push:")
    private let dataLayerKey = "dataLayer"
    private let valueForKeySelector = NSSelectorFromString("valueForKey:")
    private let preferFreshOpenType: UInt = 0

    public override init() {
        super.init()
        self.tagManager = GTMManager.resolveTagManager()
    }

    public func initialize(containerId: String, timeout: Double?, completion: @escaping (Bool, NSError?) -> Void) {
        if initialized {
            completion(true, nil)
            return
        }

        if initializationCompletion != nil {
            completion(false, GTMErrorFactory.make("Initialization already in progress"))
            return
        }

        guard let manager = tagManager else {
            completion(false, GTMErrorFactory.make("TAGManager class not found. Ensure GoogleTagManager framework is linked."))
            return
        }

        guard let openerClass = GTMRuntime.classNamed("TAGContainerOpener") else {
            completion(false, GTMErrorFactory.make("TAGContainerOpener class not found."))
            return
        }

        guard GTMRuntime.classResponds(openerClass, to: openSelector),
              let method = class_getClassMethod(openerClass, openSelector) else {
            completion(false, GTMErrorFactory.make("TAGContainerOpener missing required selector."))
            return
        }

        typealias OpenFn = @convention(c) (AnyClass, Selector, NSString, NSObject, UInt, Double, GTMManager) -> Void
        let implementation = method_getImplementation(method)
        let open = unsafeBitCast(implementation, to: OpenFn.self)

        initializationCompletion = completion

        let timeoutValue = timeout ?? 5.0
        open(openerClass, openSelector, containerId as NSString, manager, preferFreshOpenType, timeoutValue, self)
    }

    public func push(event: String, parameters: [String: Any]?, completion: @escaping (Bool, NSError?) -> Void) {
        guard initialized, let dataLayer = currentDataLayer() else {
            completion(false, GTMErrorFactory.make("Google Tag Manager not initialized"))
            return
        }

        var payload = parameters ?? [:]
        payload["event"] = event

        if GTMRuntime.instanceResponds(dataLayer, to: pushSelector) {
            _ = dataLayer.perform(pushSelector, with: payload)
            completion(true, nil)
        } else {
            completion(false, GTMErrorFactory.make("DataLayer push selector unavailable"))
        }
    }

    public func setUserProperty(key: String, value: Any, completion: @escaping (Bool, NSError?) -> Void) {
        guard initialized, let dataLayer = currentDataLayer() else {
            completion(false, GTMErrorFactory.make("Google Tag Manager not initialized"))
            return
        }

        if GTMRuntime.instanceResponds(dataLayer, to: pushSelector) {
            _ = dataLayer.perform(pushSelector, with: [key: value])
            completion(true, nil)
        } else {
            completion(false, GTMErrorFactory.make("DataLayer push selector unavailable"))
        }
    }

    public func getValue(key: String, completion: @escaping (Any?, NSError?) -> Void) {
        guard initialized, let container = container else {
            completion(nil, GTMErrorFactory.make("Google Tag Manager not initialized"))
            return
        }

        if (container as? NSObject)?.responds(to: valueForKeySelector) == true,
           let value = container.perform(valueForKeySelector, with: key)?.takeUnretainedValue() {
            completion(value, nil)
            return
        }

        completion(nil, nil)
    }

    public func reset(completion: @escaping (Bool, NSError?) -> Void) {
        guard let dataLayer = currentDataLayer() else {
            completion(false, GTMErrorFactory.make("Google Tag Manager not initialized"))
            return
        }

        if GTMRuntime.instanceResponds(dataLayer, to: pushSelector) {
            _ = dataLayer.perform(pushSelector, with: ["gtm.clear": true])
            completion(true, nil)
        } else {
            completion(false, GTMErrorFactory.make("DataLayer push selector unavailable"))
        }
    }

    @objc public func containerAvailable(_ availableContainer: AnyObject?) {
        guard let container = availableContainer as? NSObject else {
            finishInitialization(success: false, error: GTMErrorFactory.make("Received nil container"))
            return
        }

        self.container = container
        self.initialized = true
        finishInitialization(success: true, error: nil)
    }

    private func finishInitialization(success: Bool, error: NSError?) {
        if let completion = initializationCompletion {
            initializationCompletion = nil
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    private func currentDataLayer() -> NSObject? {
        guard let manager = tagManager else { return nil }
        if let dataLayer = manager.value(forKey: dataLayerKey) as? NSObject {
            return dataLayer
        }
        return nil
    }

    private static func resolveTagManager() -> NSObject? {
        guard let managerClass = GTMRuntime.classNamed("TAGManager") as? NSObject.Type else {
            return nil
        }

        let selectors = ["sharedInstance", "instance"]
        for name in selectors {
            let selector = NSSelectorFromString(name)
            if managerClass.responds(to: selector),
               let instance = managerClass.perform(selector)?.takeUnretainedValue() as? NSObject {
                return instance
            }
        }

        return nil
    }
}
