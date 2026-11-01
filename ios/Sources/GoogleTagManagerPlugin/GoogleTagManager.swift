import Foundation
import ObjectiveC.runtime

private enum GTMErrorFactory {
    static func make(_ message: String, code: Int = -1) -> NSError {
        NSError(domain: "GoogleTagManager", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

/// Compile-time symbols for Google Tag Manager SDK private APIs (App Store 2.5.2 static lookup).
private enum GTMPrivateSymbols {
    static let tagManagerClassName = "TAGManager"
    static let containersKey = "containers"

    static let sharedInstanceSelector = Selector("sharedInstance")
    static let instanceSelector = Selector("instance")
    static let loadContainerSelector = Selector("loadContainer:")
    static let forwardEventSelector = Selector("forwardEvent:")
    static let loadStateSelector = Selector("loadState")
    static let valueForKeySelector = #selector(NSObject.value(forKey:))
}

private enum GTMRuntime {
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

        guard GTMRuntime.instanceResponds(manager, to: GTMPrivateSymbols.loadContainerSelector) else {
            completion(false, GTMErrorFactory.make("TAGManager missing loadContainer: selector."))
            return
        }

        initializationCompletion = completion
        let timeoutValue = timeout ?? 5.0

        // appstore-2.5.2-allow: call private TAGManager loadContainer: via static selector
        _ = manager.perform(GTMPrivateSymbols.loadContainerSelector, with: containerId)

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

        if (container as? NSObject)?.responds(to: GTMPrivateSymbols.valueForKeySelector) == true,
           // appstore-2.5.2-allow: read TAGContainer value via NSObject valueForKey: with runtime key
           let value = container.perform(GTMPrivateSymbols.valueForKeySelector, with: key)?.takeUnretainedValue() {
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
        if GTMRuntime.instanceResponds(container, to: GTMPrivateSymbols.forwardEventSelector) {
            // appstore-2.5.2-allow: call private TAGContainer forwardEvent: via static selector
            _ = container.perform(GTMPrivateSymbols.forwardEventSelector, with: payload)
            completion(true, nil)
        } else {
            completion(false, GTMErrorFactory.make("TAGContainer forwardEvent: selector unavailable"))
        }
    }

    private func waitForContainer(containerId: String, timeout: Double) {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if let container = resolveContainer(containerId: containerId) {
                // appstore-2.5.2-allow: read private TAGContainer loadState via static selector
                let state = (container.perform(GTMPrivateSymbols.loadStateSelector)?.takeUnretainedValue() as? NSNumber)?.uintValue ?? 0

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
              // appstore-2.5.2-allow: read TAGManager containers map via static KVC key
              let containers = manager.value(forKey: GTMPrivateSymbols.containersKey) as? NSDictionary else {
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
        // appstore-2.5.2-allow: resolve private TAGManager class via static class name constant
        guard let managerClass = NSClassFromString(GTMPrivateSymbols.tagManagerClassName) as? NSObject.Type else {
            return nil
        }

        if managerClass.responds(to: GTMPrivateSymbols.sharedInstanceSelector),
           // appstore-2.5.2-allow: obtain TAGManager via private sharedInstance static selector
           let instance = managerClass.perform(GTMPrivateSymbols.sharedInstanceSelector)?.takeUnretainedValue() as? NSObject {
            return instance
        }

        if managerClass.responds(to: GTMPrivateSymbols.instanceSelector),
           // appstore-2.5.2-allow: obtain TAGManager via private instance static selector fallback
           let instance = managerClass.perform(GTMPrivateSymbols.instanceSelector)?.takeUnretainedValue() as? NSObject {
            return instance
        }

        return nil
    }
}
