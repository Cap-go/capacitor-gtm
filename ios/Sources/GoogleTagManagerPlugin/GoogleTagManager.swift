import Foundation

@objc public class GoogleTagManager: NSObject {
    @objc public func echo(_ value: String) -> String {
        print(value)
        return value
    }
}
