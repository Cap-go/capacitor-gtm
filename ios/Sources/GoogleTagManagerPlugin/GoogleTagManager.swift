import Foundation
import FirebaseAnalytics
import FirebaseCore

private enum GTMErrorFactory {
    static func make(_ message: String, code: Int = -1) -> NSError {
        NSError(domain: "GoogleTagManager", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
}

@objc public final class GTMManager: NSObject {
    private var initialized = false
    private var containerId: String?
    private var dataLayerEntries: [[String: Any]] = []
    private var initializationCompletion: ((Bool, NSError?) -> Void)?

    override public init() {
        super.init()
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

        guard containerId.hasPrefix("GTM-") else {
            completion(false, GTMErrorFactory.make("Invalid container ID. Expected format GTM-XXXXXX"))
            return
        }

        self.containerId = containerId
        initializationCompletion = completion

        let timeoutSeconds = max(0.1, (timeout ?? 2000) / 1000.0)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.configureFirebase(timeout: timeoutSeconds)
        }
    }

    public func push(event: String, parameters: [String: Any]?, completion: @escaping (Bool, NSError?) -> Void) {
        guard initialized else {
            completion(false, GTMErrorFactory.make("Google Tag Manager not initialized"))
            return
        }

        var payload = parameters ?? [:]
        payload["event"] = event
        recordDataLayer(payload)

        let analyticsParameters = GTMParameterSanitizer.analyticsParameters(from: parameters ?? [:])
        Analytics.logEvent(GTMParameterSanitizer.eventName(event), parameters: analyticsParameters)
        completion(true, nil)
    }

    public func setUserProperty(key: String, value: Any, completion: @escaping (Bool, NSError?) -> Void) {
        guard initialized else {
            completion(false, GTMErrorFactory.make("Google Tag Manager not initialized"))
            return
        }

        recordDataLayer([key: value])
        Analytics.setUserProperty(GTMParameterSanitizer.stringValue(value), forName: GTMParameterSanitizer.parameterName(key))
        completion(true, nil)
    }

    public func getValue(key: String, completion: @escaping (Any?, NSError?) -> Void) {
        guard initialized else {
            completion(nil, GTMErrorFactory.make("Google Tag Manager not initialized"))
            return
        }

        completion(DataLayerLookup.latestValue(in: dataLayerEntries, for: key), nil)
    }

    public func reset(completion: @escaping (Bool, NSError?) -> Void) {
        guard initialized else {
            completion(false, GTMErrorFactory.make("Google Tag Manager not initialized"))
            return
        }

        Analytics.resetAnalyticsData()
        dataLayerEntries.removeAll()
        initialized = false
        containerId = nil
        completion(true, nil)
    }

    private func configureFirebase(timeout: Double) {
        let deadline = Date().addingTimeInterval(timeout)

        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        while Date() < deadline {
            if FirebaseApp.app() != nil {
                if let containerId = containerId {
                    Analytics.setUserProperty(containerId, forName: "gtm_container_id")
                }
                initialized = true
                finishInitialization(success: true, error: nil)
                return
            }
            Thread.sleep(forTimeInterval: 0.05)
        }

        finishInitialization(success: false, error: GTMErrorFactory.make("Timed out waiting for Firebase to initialize"))
    }

    private func recordDataLayer(_ values: [String: Any]) {
        dataLayerEntries.append(values)
    }

    private func finishInitialization(success: Bool, error: NSError?) {
        if let completion = initializationCompletion {
            initializationCompletion = nil
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
}

enum DataLayerLookup {
    static func latestValue(in entries: [[String: Any]], for key: String) -> Any? {
        for entry in entries.reversed() {
            if let value = entry[key] {
                return value
            }
        }
        return nil
    }
}

enum GTMParameterSanitizer {
    static func eventName(_ name: String) -> String {
        sanitize(name, maxLength: 40)
    }

    static func parameterName(_ name: String) -> String {
        sanitize(name, maxLength: 40)
    }

    static func stringValue(_ value: Any) -> String? {
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number.stringValue
        case let bool as Bool:
            return bool ? "true" : "false"
        default:
            return String(describing: value)
        }
    }

    static func analyticsParameters(from parameters: [String: Any]) -> [String: Any]? {
        var sanitized: [String: Any] = [:]

        for (key, value) in parameters {
            let name = parameterName(key)
            if let converted = analyticsValue(value) {
                sanitized[name] = converted
            }
        }

        return sanitized.isEmpty ? nil : sanitized
    }

    private static func analyticsValue(_ value: Any) -> Any? {
        switch value {
        case let string as String:
            return string
        case let number as Int:
            return number
        case let number as Int64:
            return number
        case let number as Double:
            return number
        case let number as Float:
            return Double(number)
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue
            }
            return number
        case let bool as Bool:
            return bool
        case let array as [Any]:
            let converted = array.compactMap { analyticsValue($0) }
            return converted.isEmpty ? nil : converted
        default:
            return stringValue(value)
        }
    }

    private static func sanitize(_ value: String, maxLength: Int) -> String {
        let allowed = value.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) || scalar == "_" {
                return Character(scalar)
            }
            return "_"
        }

        let cleaned = String(allowed)
        if cleaned.isEmpty {
            return "event"
        }

        if cleaned.count <= maxLength {
            return cleaned
        }

        return String(cleaned.prefix(maxLength))
    }
}
