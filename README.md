# Capacitor Google Tag Manager Plugin

Use Google Tag Manager in your Capacitor app. Native iOS and Android use the public Firebase Analytics SDK (App Store guideline 2.5.2 safe). Link your GTM container in the Firebase console and push events from JavaScript with the same plugin API.

<a href="https://capgo.app/?ref=plugin_gtm"><img src="https://capgo.app/readme-banner.svg?repo=Cap-go/capacitor-gtm" alt="Capgo - Instant updates for Capacitor" /></a>

<div align="center">
  <p><b>Capgo</b>: push fixes to your Capacitor users in minutes, build signed iOS and Android apps without a Mac, and roll back in one click.</p>
  <h2><a href="https://capgo.app/register/?ref=plugin_gtm">➡️ Get started for free</a></h2>
  <p>14-day unlimited free trial. No credit card required</p>
  <p><a href="https://capgo.app/consulting/?ref=plugin_gtm">Missing a feature? We'll build the plugin for you 💪</a></p>
</div>

<p align="center">
  <img src="https://raw.githubusercontent.com/Cap-go/capacitor-gtm/main/assets/github-social-preview.png" alt="@capgo/capacitor-gtm for Capacitor apps" width="300" />
</p>

## Key features

- **Container**: `initialize()` loads your GTM container ID, with an optional timeout on native.
- **Events**: `push()` sends events with parameters to the dataLayer.
- **User properties**: `setUserProperty()` sets values for tags and triggers.
- **Read values**: `getValue()` reads the in-memory dataLayer mirror (web searches `window.dataLayer`).
- **Reset**: `reset()` clears the instance and its data.
- **Platforms**: iOS, Android and Web. The web adapter ignores `timeout`.

A Capacitor plugin for integrating Google Tag Manager into your mobile applications.

> **Note**: iOS and Android route events through Firebase Analytics. Web keeps using the GTM JavaScript snippet. You still pass your `GTM-XXXXXX` container ID to `initialize()`; native code stores it as the `gtm_container_id` user property for debugging.

## Documentation

The most complete doc is available here: https://capgo.app/docs/plugins/gtm/

## Compatibility

| Plugin version | Capacitor compatibility | Maintained |
| -------------- | ----------------------- | ---------- |
| v8.\*.\*       | v8.\*.\*                | ✅          |
| v7.\*.\*       | v7.\*.\*                | On demand   |
| v6.\*.\*       | v6.\*.\*                | ❌          |
| v5.\*.\*       | v5.\*.\*                | ❌          |

> **Note:** The major version of this plugin follows the major version of Capacitor. Use the version that matches your Capacitor installation (e.g., plugin v8 for Capacitor 8). Only the latest major version is actively maintained.

## Installation

You can use our AI-Assisted Setup to install the plugin. Add the Capgo skills to your AI tool using the following command:

```bash
npx skills add https://github.com/cap-go/capacitor-skills --skill capacitor-plugins
```

Then use the following prompt:

```text
Use the `capacitor-plugins` skill from `cap-go/capacitor-skills` to install the `@capgo/capacitor-gtm` plugin in my project.
```

If you prefer Manual Setup, install the plugin by running the following commands and follow the platform-specific instructions below:

```bash
npm install @capgo/capacitor-gtm
npx cap sync
```

## Platform Setup

### iOS Setup

1. **Add Firebase config**
   - Create or open your Firebase project and add the iOS app
   - Download `GoogleService-Info.plist` and add it to your Xcode app target
2. **Link GTM in Firebase**
   - In the Firebase console, open Google Tag Manager and link the mobile container ID you pass to `initialize()`

### Android Setup

1. **Add Firebase config**
   - Add the Android app in Firebase and download `google-services.json`
   - Place it in `android/app/google-services.json`
   - Apply the Google services Gradle plugin in your app module (see [Firebase Android setup](https://firebase.google.com/docs/android/setup))
2. **Link GTM in Firebase**
   - Link the same GTM container in the Firebase console

## API

<docgen-index>

* [`initialize(...)`](#initialize)
* [`push(...)`](#push)
* [`setUserProperty(...)`](#setuserproperty)
* [`getValue(...)`](#getvalue)
* [`reset()`](#reset)
* [`getPluginVersion()`](#getpluginversion)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

The main interface for the Google Tag Manager plugin.

On iOS and Android, native calls are routed through the public Firebase Analytics SDK.
Link your GTM web container in the Firebase console. Legacy on-device GTM container
bundles are no longer loaded by this plugin.

### initialize(...)

```typescript
initialize(options: { containerId: string; timeout?: number; }) => Promise<void>
```

Initializes Google Tag Manager for the app session.

Provide the GTM container ID so native code can tag analytics with `gtm_container_id`.
Your app must include Firebase config (`GoogleService-Info.plist` on iOS,
`google-services.json` on Android). The optional timeout is in milliseconds.

**Not preserved on native (no public Firebase API):** blocking until a legacy on-device
GTM container file finishes loading (`TAGContainer` / `ContainerHolder`). Initialization
completes when Firebase Analytics is ready; link the container in the Firebase console.

| Param         | Type                                                    | Description                   |
| ------------- | ------------------------------------------------------- | ----------------------------- |
| **`options`** | <code>{ containerId: string; timeout?: number; }</code> | - The initialization options. |

**Since:** 1.0.0

--------------------


### push(...)

```typescript
push(options: { event: string; parameters?: Record<string, any>; }) => Promise<void>
```

Pushes an event to the Google Tag Manager dataLayer.

On native platforms the event is sent with Firebase Analytics `logEvent`.

| Param         | Type                                                                                          | Description          |
| ------------- | --------------------------------------------------------------------------------------------- | -------------------- |
| **`options`** | <code>{ event: string; parameters?: <a href="#record">Record</a>&lt;string, any&gt;; }</code> | - The event options. |

**Since:** 1.0.0

--------------------


### setUserProperty(...)

```typescript
setUserProperty(options: { key: string; value: string | number | boolean; }) => Promise<void>
```

Sets a user property in the Google Tag Manager dataLayer.

On native platforms the value is stored as a Firebase Analytics user property (string).

| Param         | Type                                                              | Description                  |
| ------------- | ----------------------------------------------------------------- | ---------------------------- |
| **`options`** | <code>{ key: string; value: string \| number \| boolean; }</code> | - The user property options. |

**Since:** 1.0.0

--------------------


### getValue(...)

```typescript
getValue(options: { key: string; }) => Promise<{ value: any; }>
```

Gets a value from the in-memory dataLayer mirror maintained by this plugin.

On web, the plugin searches `window.dataLayer` from newest to oldest entry.
On iOS and Android, the plugin uses the same newest-first search over the session
dataLayer mirror updated by `push()` and `setUserProperty()`.

**Not preserved on native (no public Firebase API):** values that existed only in a
legacy on-device GTM container (Android `Container.get*`, iOS container key lookup).
Those keys return `undefined` unless you set them with `push()` or `setUserProperty()`.

| Param         | Type                          | Description                           |
| ------------- | ----------------------------- | ------------------------------------- |
| **`options`** | <code>{ key: string; }</code> | - The options for retrieving a value. |

**Returns:** <code>Promise&lt;{ value: any; }&gt;</code>

**Since:** 1.0.0

--------------------


### reset()

```typescript
reset() => Promise<void>
```

Resets the Google Tag Manager instance and clears all data.

On native platforms this clears the plugin dataLayer mirror and calls Firebase
`resetAnalyticsData()`. You must call `initialize()` again before pushing events.

**Since:** 1.0.0

--------------------


### getPluginVersion()

```typescript
getPluginVersion() => Promise<{ version: string; }>
```

Get the native Capacitor plugin version

**Returns:** <code>Promise&lt;{ version: string; }&gt;</code>

--------------------


### Type Aliases


#### Record

Construct a type with a set of properties K of type T

<code>{ [P in K]: T; }</code>

</docgen-api>

## Usage Example

```typescript
import { GoogleTagManager } from '@capgo/capacitor-gtm';

// Initialize GTM
await GoogleTagManager.initialize({ 
  containerId: 'GTM-XXXXXX',
  timeout: 2000 // optional, defaults to 2000ms
});

// Track an event
await GoogleTagManager.push({
  event: 'purchase',
  parameters: {
    value: 29.99,
    currency: 'USD',
    items: ['item1', 'item2']
  }
});

// Set user property
await GoogleTagManager.setUserProperty({
  key: 'user_type',
  value: 'premium'
});

// Get a value from container
const result = await GoogleTagManager.getValue({ key: 'api_key' });
console.log('API Key:', result.value);

// Reset data layer
await GoogleTagManager.reset();
```

## Common Use Cases

### E-commerce Tracking

```typescript
// Track product view
await GoogleTagManager.push({
  event: 'view_item',
  parameters: {
    currency: 'USD',
    value: 15.99,
    items: [{
      item_id: 'SKU123',
      item_name: 'Product Name',
      price: 15.99,
      quantity: 1
    }]
  }
});

// Track purchase
await GoogleTagManager.push({
  event: 'purchase',
  parameters: {
    transaction_id: '12345',
    value: 45.99,
    currency: 'USD',
    items: [{
      item_id: 'SKU123',
      item_name: 'Product Name',
      price: 15.99,
      quantity: 2
    }]
  }
});
```

### User Engagement

```typescript
// Track screen view
await GoogleTagManager.push({
  event: 'screen_view',
  parameters: {
    screen_name: 'Home',
    screen_class: 'HomeViewController'
  }
});

// Track custom event
await GoogleTagManager.push({
  event: 'level_complete',
  parameters: {
    level: 5,
    score: 1000,
    time_spent: 300
  }
});
```

## Troubleshooting

### iOS Issues

1. **Initialization failures**: Confirm `GoogleService-Info.plist` is in the app target and Firebase is configured before calling `initialize()`.

2. **Build errors**: Run `npx cap sync` after installing the plugin.

### Android Issues

1. **Initialization failures**: Confirm `google-services.json` is present and the Google services Gradle plugin is applied in the app module.

2. **Events missing in GTM**: Publish the linked container in GTM and allow time for DebugView or Tag Assistant to show events.

### General Issues

1. **Events not appearing in GTM**: Remember that GTM has a delay in showing real-time events. Also ensure your GTM container is published.

2. **Values returning null on native**: `getValue()` only returns keys set with `push()` or `setUserProperty()` in the current session. It does not read GTM container variables.

## License

MIT
