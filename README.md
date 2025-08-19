# Capacitor Google Tag Manager Plugin

A Capacitor plugin for integrating Google Tag Manager into your mobile applications.

## Installation

```bash
npm install capacitor-gtm
npx cap sync
```

## Platform Setup

### iOS Setup

1. **Add your GTM container file**
   - Download your container from Google Tag Manager console
   - Add the downloaded `GTM-XXXXXX.json` file to your iOS project
   - In Xcode, drag the file into your project
   - Make sure "Copy items if needed" is selected
   - Ensure the file is added to your app target

2. **No additional configuration needed**
   - The plugin uses Google Tag Manager SDK v7.4.6 which supports iOS 12+
   - The plugin is compatible with iOS 14.0+

### Android Setup

1. **Add your GTM container file**
   - Download your container from Google Tag Manager console  
   - Place the `GTM-XXXXXX.json` file in your Android project's `assets/containers/` folder
   - Create the `containers` folder if it doesn't exist: `android/app/src/main/assets/containers/`

### Web Setup

No additional setup is required for web. The plugin will automatically load the Google Tag Manager script.

## Usage

```typescript
import { GoogleTagManager } from 'capacitor-gtm';

// Initialize Google Tag Manager
await GoogleTagManager.initialize({ 
  containerId: 'GTM-XXXXXX',
  timeout: 2000 // optional, defaults to 2000ms
});

// Push an event to the dataLayer
await GoogleTagManager.push({
  event: 'purchase',
  parameters: {
    value: 29.99,
    currency: 'USD',
    transaction_id: '12345'
  }
});

// Set a user property
await GoogleTagManager.setUserProperty({
  key: 'user_type',
  value: 'premium'
});

// Get a value from the container
const result = await GoogleTagManager.getValue({ key: 'api_key' });
console.log('API Key:', result.value);

// Reset all data
await GoogleTagManager.reset();
```

## Common Use Cases

### Track Screen Views

```typescript
await GoogleTagManager.push({
  event: 'screen_view',
  parameters: {
    screen_name: 'Home',
    screen_class: 'HomeViewController'
  }
});
```

### Track User Actions

```typescript
await GoogleTagManager.push({
  event: 'button_click',
  parameters: {
    button_name: 'subscribe',
    button_location: 'header'
  }
});
```

### E-commerce Events

```typescript
// Track a purchase
await GoogleTagManager.push({
  event: 'purchase',
  parameters: {
    transaction_id: '12345',
    value: 59.99,
    currency: 'USD',
    items: [{
      item_id: 'SKU123',
      item_name: 'Product Name',
      price: 59.99,
      quantity: 1
    }]
  }
});

// Track add to cart
await GoogleTagManager.push({
  event: 'add_to_cart',
  parameters: {
    currency: 'USD',
    value: 29.99,
    items: [{
      item_id: 'SKU456',
      item_name: 'Another Product',
      price: 29.99,
      quantity: 1
    }]
  }
});
```

### User Properties

```typescript
// Set multiple user properties
await GoogleTagManager.setUserProperty({
  key: 'user_id',
  value: 'USER123'
});

await GoogleTagManager.setUserProperty({
  key: 'subscription_status',
  value: 'active'
});
```

### Custom Events

```typescript
await GoogleTagManager.push({
  event: 'custom_event',
  parameters: {
    custom_parameter_1: 'value1',
    custom_parameter_2: 123,
    custom_parameter_3: true
  }
});
```

## API Reference

<docgen-index>

* [`initialize(...)`](#initialize)
* [`push(...)`](#push)
* [`setUserProperty(...)`](#setuserproperty)
* [`getValue(...)`](#getvalue)
* [`reset()`](#reset)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

The main interface for the Google Tag Manager plugin.

### initialize(...)

```typescript
initialize(options: { containerId: string; timeout?: number; }) => Promise<void>
```

Initializes Google Tag Manager with the specified container ID.

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

| Param         | Type                                                              | Description                  |
| ------------- | ----------------------------------------------------------------- | ---------------------------- |
| **`options`** | <code>{ key: string; value: string \| number \| boolean; }</code> | - The user property options. |

**Since:** 1.0.0

--------------------


### getValue(...)

```typescript
getValue(options: { key: string; }) => Promise<{ value: any; }>
```

Gets a value from the Google Tag Manager dataLayer.
Searches through the dataLayer for the most recent value of the specified key.

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
This will remove all data from the dataLayer and require re-initialization.

**Since:** 1.0.0

--------------------


### Type Aliases


#### Record

Construct a type with a set of properties K of type T

<code>{ [P in K]: T; }</code>

</docgen-api>

## Testing & Debugging

### Preview Mode

To test your container configuration before publishing:

1. In Google Tag Manager, click "Preview" in your workspace
2. For mobile apps, you'll need to use the Google Tag Manager app for testing
3. Follow the preview instructions in the GTM interface

### Debug Mode

Enable verbose logging by setting the log level in your app:

```typescript
// This should be done before initializing GTM
if (__DEV__) {
  // Platform-specific debug enabling
}
```

## Requirements

- **iOS**: Requires iOS 14.0 or later
- **Android**: Requires Android 5.0 (API level 21) or later
- **Web**: Works in all modern browsers

## License

MIT
