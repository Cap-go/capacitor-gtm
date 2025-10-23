/**
 * The main interface for the Google Tag Manager plugin.
 */
export interface GoogleTagManagerPlugin {
  /**
   * Initializes Google Tag Manager with the specified container ID.
   *
   * @param {Object} options - The initialization options.
   * @param {string} options.containerId - The Google Tag Manager container ID (e.g., 'GTM-XXXXXX').
   * @param {number} [options.timeout=2000] - The timeout in milliseconds for loading the container.
   * @returns {Promise<void>} A promise that resolves when GTM is successfully initialized.
   * @since 1.0.0
   */
  initialize(options: { containerId: string; timeout?: number }): Promise<void>;

  /**
   * Pushes an event to the Google Tag Manager dataLayer.
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
   * Gets a value from the Google Tag Manager dataLayer.
   * Searches through the dataLayer for the most recent value of the specified key.
   *
   * @param {Object} options - The options for retrieving a value.
   * @param {string} options.key - The key to retrieve from the dataLayer.
   * @returns {Promise<{ value: any }>} A promise that resolves with the value, or undefined if not found.
   * @since 1.0.0
   */
  getValue(options: { key: string }): Promise<{ value: any }>;

  /**
   * Resets the Google Tag Manager instance and clears all data.
   * This will remove all data from the dataLayer and require re-initialization.
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
