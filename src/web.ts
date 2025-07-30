import { WebPlugin } from '@capacitor/core';

import type { GoogleTagManagerPlugin } from './definitions';

declare global {
  interface Window {
    dataLayer: any[];
    gtag?: (...args: any[]) => void;
  }
}

export class GoogleTagManagerWeb extends WebPlugin implements GoogleTagManagerPlugin {
  private initialized = false;
  private containerId?: string;

  async initialize(options: { containerId: string; timeout?: number }): Promise<void> {
    if (this.initialized) {
      return;
    }

    this.containerId = options.containerId;
    window.dataLayer = window.dataLayer || [];

    // Load GTM script
    const script = document.createElement('script');
    script.async = true;
    script.src = `https://www.googletagmanager.com/gtm.js?id=${options.containerId}`;
    
    const firstScript = document.getElementsByTagName('script')[0];
    firstScript.parentNode?.insertBefore(script, firstScript);

    // Initialize gtag
    window.gtag = function() {
      window.dataLayer.push(arguments);
    };
    window.gtag('js', new Date());
    window.gtag('config', options.containerId);

    this.initialized = true;
  }

  async push(options: { event: string; parameters?: Record<string, any> }): Promise<void> {
    if (!this.initialized) {
      throw new Error('Google Tag Manager not initialized');
    }

    const data: any = { event: options.event };
    if (options.parameters) {
      Object.assign(data, options.parameters);
    }
    
    window.dataLayer.push(data);
  }

  async setUserProperty(options: { key: string; value: string | number | boolean }): Promise<void> {
    if (!this.initialized) {
      throw new Error('Google Tag Manager not initialized');
    }

    window.dataLayer.push({
      [options.key]: options.value
    });
  }

  async getValue(options: { key: string }): Promise<{ value: any }> {
    if (!this.initialized) {
      throw new Error('Google Tag Manager not initialized');
    }

    // Search through dataLayer for the most recent value
    for (let i = window.dataLayer.length - 1; i >= 0; i--) {
      if (options.key in window.dataLayer[i]) {
        return { value: window.dataLayer[i][options.key] };
      }
    }

    return { value: undefined };
  }

  async reset(): Promise<void> {
    window.dataLayer = [];
    this.initialized = false;
    this.containerId = undefined;
  }
}
