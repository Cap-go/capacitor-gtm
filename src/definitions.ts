/**
 * The main interface for the Google Tag Manager plugin.
 *
 * On iOS and Android, native calls are routed through the public Firebase Analytics SDK.
 * Link your GTM web container in the Firebase console. Legacy on-device GTM container
 * bundles are no longer loaded by this plugin.
 */
export interface GoogleTagManagerPlugin {
  /**
   * Initializes Google Tag Manager for the app session.
   *
   * Provide the GTM container ID so native code can tag analytics with `gtm_container_id`.
   * Your app must include Firebase config (`GoogleService-Info.plist` on iOS,
   * `google-services.json` on Android). The optional timeout is in milliseconds.
   *
   * @param {Object} options - The initialization options.
   * @param {string} options.containerId - The Google Tag Manager container ID (e.g., 'GTM-XXXXXX').
   * @param {number} [options.timeout=2000] - The timeout in milliseconds for Firebase startup.
   * @returns {Promise<void>} A promise that resolves when native analytics is ready.
   * @since 1.0.0
   */
  initialize(options: { containerId: string; timeout?: number }): Promise<void>;

  /**
   * Pushes an event to the Google Tag Manager dataLayer.
   *
   * On native platforms the event is sent with Firebase Analytics `logEvent`.
   *
   * @param {Object} options - The event options.
   * @param {string} options.event - The event name to push to the dataLayer.
   * @param {Record<string, any>} [options.parameters] - Additional parameters to include with the event.
   * @returns {Promise<void>} A promise that resolves when the event is successfully pushed.
   * @since 1.0.0
   * @example
   * await GoogleTagManager.push({
   *   event: 'purchase',
   *   parameters: {
   *     value: 99.99,
   *     currency: 'USD'
   *   }
   * });
   */
  push(options: { event: string; parameters?: Record<string, any> }): Promise<void>;

  /**
   * Sets a user property in the Google Tag Manager dataLayer.
   *
   * On native platforms the value is stored as a Firebase Analytics user property (string).
   *
   * @param {Object} options - The user property options.
   * @param {string} options.key - The property key name.
   * @param {string | number | boolean} options.value - The property value.
   * @returns {Promise<void>} A promise that resolves when the property is successfully set.
   * @since 1.0.0
   * @example
   * await GoogleTagManager.setUserProperty({
   *   key: 'user_type',
   *   value: 'premium'
   * });
   */
  setUserProperty(options: { key: string; value: string | number | boolean }): Promise<void>;

  /**
   * Gets a value from the in-memory dataLayer mirror maintained by this plugin.
   *
   * On web, the plugin searches `window.dataLayer`. On iOS and Android, only values
   * previously set with `push()` or `setUserProperty()` during the current session are returned.
   * Native GTM container macros are not readable through this API.
   *
   * @param {Object} options - The options for retrieving a value.
   * @param {string} options.key - The key to retrieve from the dataLayer.
   * @returns {Promise<{ value: any }>} A promise that resolves with the value, or undefined if not found.
   * @since 1.0.0
   */
  getValue(options: { key: string }): Promise<{ value: any }>;

  /**
   * Resets the Google Tag Manager instance and clears all data.
   *
   * On native platforms this clears the plugin dataLayer mirror and calls Firebase
   * `resetAnalyticsData()`. You must call `initialize()` again before pushing events.
   *
   * @returns {Promise<void>} A promise that resolves when GTM is successfully reset.
   * @since 1.0.0
   */
  reset(): Promise<void>;

  /**
   * Get the native Capacitor plugin version
   *
   * @returns {Promise<{ id: string }>} an Promise with version for this device
   * @throws An error if the something went wrong
   */
  getPluginVersion(): Promise<{ version: string }>;
}
