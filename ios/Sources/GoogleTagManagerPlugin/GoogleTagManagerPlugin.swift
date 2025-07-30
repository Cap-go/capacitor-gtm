import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(GoogleTagManagerPlugin)
public class GoogleTagManagerPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "GoogleTagManagerPlugin"
    public let jsName = "GoogleTagManager"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "initialize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "push", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setUserProperty", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getValue", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "reset", returnType: CAPPluginReturnPromise)
    ]
    private let implementation = GoogleTagManager()

    @objc func initialize(_ call: CAPPluginCall) {
        guard let containerId = call.getString("containerId") else {
            call.reject("Missing containerId parameter")
            return
        }
        
        let timeout = call.getDouble("timeout")
        
        implementation.initialize(containerId: containerId, timeout: timeout) { success, error in
            if success {
                call.resolve()
            } else {
                call.reject(error?.localizedDescription ?? "Failed to initialize Google Tag Manager")
            }
        }
    }

    @objc func push(_ call: CAPPluginCall) {
        guard let event = call.getString("event") else {
            call.reject("Missing event parameter")
            return
        }
        
        let parameters = call.getObject("parameters") ?? [:]
        
        implementation.push(event: event, parameters: parameters)
        call.resolve()
    }

    @objc func setUserProperty(_ call: CAPPluginCall) {
        guard let key = call.getString("key") else {
            call.reject("Missing key parameter")
            return
        }
        
        guard let value = call.getValue("value") else {
            call.reject("Missing value parameter")
            return
        }
        
        implementation.setUserProperty(key: key, value: value)
        call.resolve()
    }

    @objc func getValue(_ call: CAPPluginCall) {
        guard let key = call.getString("key") else {
            call.reject("Missing key parameter")
            return
        }
        
        let value = implementation.getValue(key: key)
        call.resolve(["value": value as Any])
    }

    @objc func reset(_ call: CAPPluginCall) {
        implementation.reset()
        call.resolve()
    }
}
