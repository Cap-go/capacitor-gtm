import Foundation
import GoogleTagManager

@objc public class GoogleTagManager: NSObject {
    private var tagManager: TAGManager?
    private var container: TAGContainer?
    private var containerOpener: TAGContainerOpener?
    
    @objc public override init() {
        super.init()
        tagManager = TAGManager.instance()
    }
    
    @objc public func initialize(containerId: String, timeout: Double?, completion: @escaping (Bool, Error?) -> Void) {
        guard let tagManager = tagManager else {
            completion(false, NSError(domain: "GoogleTagManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get TAGManager instance"]))
            return
        }
        
        let timeoutInterval = timeout ?? 2.0
        
        TAGContainerOpener.openContainer(
            withId: containerId,
            tagManager: tagManager,
            openType: kTAGOpenTypePreferFresh,
            timeout: timeoutInterval,
            notifier: self
        )
        
        // Store completion for later use
        self.initializationCompletion = completion
    }
    
    @objc public func push(event: String, parameters: [String: Any]) {
        guard let tagManager = tagManager else { return }
        
        var dataLayerDict: [String: Any] = ["event": event]
        for (key, value) in parameters {
            dataLayerDict[key] = value
        }
        
        tagManager.dataLayer.push(dataLayerDict)
    }
    
    @objc public func setUserProperty(key: String, value: Any) {
        guard let tagManager = tagManager else { return }
        
        tagManager.dataLayer.push([key: value])
    }
    
    @objc public func getValue(key: String) -> Any? {
        guard let container = container else { return nil }
        
        // Try different types to get the value
        let stringValue = container.string(forKey: key)
        if !stringValue.isEmpty {
            return stringValue
        }
        
        let doubleValue = container.double(forKey: key)
        if doubleValue != 0 {
            return doubleValue
        }
        
        let boolValue = container.boolean(forKey: key)
        return boolValue
    }
    
    @objc public func reset() {
        guard let tagManager = tagManager else { return }
        
        // Clear the data layer by pushing a reset event
        tagManager.dataLayer.push(["gtm.reset": true])
    }
    
    private var initializationCompletion: ((Bool, Error?) -> Void)?
}

// MARK: - TAGContainerOpenerNotifier
extension GoogleTagManager: TAGContainerOpenerNotifier {
    public func containerAvailable(_ container: TAGContainer!) {
        self.container = container
        initializationCompletion?(true, nil)
        initializationCompletion = nil
    }
}
