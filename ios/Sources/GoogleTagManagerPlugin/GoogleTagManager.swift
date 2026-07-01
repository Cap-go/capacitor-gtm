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

private enum TAGContainerLoadState: UInt {
    case notLoaded = 0
    case loading = 1
    case loaded = 2
    case failed = 3
}

@objc public final class GTMManager: NSObject {
    private var tagManager: NSObject?
    private var container: NSObject?
    private var initialized = false
    private var initializationCompletion: ((Bool, NSError?) -> Void)?

    private let loadContainerSelector = NSSelectorFromString("loadContainer:")
    private let forwardEventSelector = NSSelectorFromString("forwardEvent:")
    private let loadStateSelector = NSSelectorFromString("loadState")
    private let valueForKeySelector = NSSelectorFromString("valueForKey:")
    private let containersKey = "containers"

    override public init() {
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

        guard GTMRuntime.instanceResponds(manager, to: loadContainerSelector) else {
            completion(false, GTMErrorFactory.make("TAGManager missing loadContainer: selector."))
            return
        }

        initializationCompletion = completion
        let timeoutValue = timeout ?? 5.0

        _ = manager.perform(loadContainerSelector, with: containerId)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.waitForContainer(containerId: containerId, timeout: timeoutValue)
        }
    }

    public func push(event: String, parameters: [String: Any]?, completion: @escaping (Bool, NSError?) -> Void) {
        guard initialized, let container = container else {
            completion(false, GTMErrorFactory.make("Google Tag Manager not initialized"))
            return
        }

        var payload = parameters ?? [:]
        payload["event"] = event
        forwardEvent(payload, on: container, completion: completion)
    }

    public func setUserProperty(key: String, value: Any, completion: @escaping (Bool, NSError?) -> Void) {
        guard initialized, let container = container else {
            completion(false, GTMErrorFactory.make("Google Tag Manager not initialized"))
            return
        }

        forwardEvent([key: value], on: container, completion: completion)
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
        guard initialized, let container = container else {
            completion(false, GTMErrorFactory.make("Google Tag Manager not initialized"))
            return
        }

        forwardEvent(["gtm.clear": true], on: container, completion: completion)
    }

    private func forwardEvent(_ payload: [String: Any], on container: NSObject, completion: @escaping (Bool, NSError?) -> Void) {
        if GTMRuntime.instanceResponds(container, to: forwardEventSelector) {
            _ = container.perform(forwardEventSelector, with: payload)
            completion(true, nil)
        } else {
            completion(false, GTMErrorFactory.make("TAGContainer forwardEvent: selector unavailable"))
        }
    }

    private func waitForContainer(containerId: String, timeout: Double) {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if let container = resolveContainer(containerId: containerId) {
                let state = (container.perform(loadStateSelector)?.takeUnretainedValue() as? NSNumber)?.uintValue ?? 0

                switch TAGContainerLoadState(rawValue: state) {
                case .loaded:
                    self.container = container
                    self.initialized = true
                    finishInitialization(success: true, error: nil)
                    return
                case .failed:
                    finishInitialization(success: false, error: GTMErrorFactory.make("Failed to load GTM container"))
                    return
                case .notLoaded, .loading, .none:
                    break
                }
            }

            Thread.sleep(forTimeInterval: 0.05)
        }

        finishInitialization(success: false, error: GTMErrorFactory.make("Timed out waiting for GTM container to load"))
    }

    private func resolveContainer(containerId: String) -> NSObject? {
        guard let manager = tagManager,
              let containers = manager.value(forKey: containersKey) as? NSDictionary else {
            return nil
        }

        return containers[containerId] as? NSObject
    }

    private func finishInitialization(success: Bool, error: NSError?) {
        if let completion = initializationCompletion {
            initializationCompletion = nil
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
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
