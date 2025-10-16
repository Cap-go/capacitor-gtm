import { GoogleTagManager } from '@capgo/capacitor-gtm';

const containerIdInput = document.getElementById('containerId');
const timeoutInput = document.getElementById('timeout');
const initializeButton = document.getElementById('initializeButton');

const eventNameInput = document.getElementById('eventName');
const eventParamsInput = document.getElementById('eventParams');
const pushButton = document.getElementById('pushButton');

const propertyKeyInput = document.getElementById('propertyKey');
const propertyValueInput = document.getElementById('propertyValue');
const userPropertyButton = document.getElementById('userPropertyButton');

const lookupKeyInput = document.getElementById('lookupKey');
const getValueButton = document.getElementById('getValueButton');

const resetButton = document.getElementById('resetButton');
const logOutput = document.getElementById('logOutput');

const log = (message, payload) => {
  const timestamp = new Date().toISOString();
  const serialized = payload !== undefined ? `\n${JSON.stringify(payload, null, 2)}` : '';
  if (logOutput) {
    logOutput.textContent = `[${timestamp}] ${message}${serialized}`;
  }
};

const parseJsonOrThrow = (value) => {
  if (!value || !value.trim()) {
    return {};
  }

  try {
    const parsed = JSON.parse(value);
    if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
      return parsed;
    }
    throw new Error('Parameters JSON must represent an object.');
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Invalid JSON';
    throw new Error(message);
  }
};

initializeButton?.addEventListener('click', async () => {
  const containerId = containerIdInput?.value?.trim();
  const timeout = Number(timeoutInput?.value);

  if (!containerId) {
    log('Container ID is required to initialize.');
    return;
  }

  try {
    await GoogleTagManager.initialize({
      containerId,
      timeout: Number.isNaN(timeout) ? undefined : timeout,
    });
    log('Initialized container', { containerId, timeout });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    log('Initialize failed', { message });
  }
});

pushButton?.addEventListener('click', async () => {
  const eventName = eventNameInput?.value?.trim();
  if (!eventName) {
    log('Event name is required.');
    return;
  }

  try {
    const parameters = parseJsonOrThrow(eventParamsInput?.value ?? '');
    await GoogleTagManager.push({ event: eventName, parameters });
    log('Event pushed', { event: eventName, parameters });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    log('Push failed', { message });
  }
});

userPropertyButton?.addEventListener('click', async () => {
  const key = propertyKeyInput?.value?.trim();
  const value = propertyValueInput?.value ?? '';

  if (!key) {
    log('Property key is required.');
    return;
  }

  try {
    await GoogleTagManager.setUserProperty({ key, value });
    log('User property set', { key, value });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    log('Set user property failed', { message });
  }
});

getValueButton?.addEventListener('click', async () => {
  const key = lookupKeyInput?.value?.trim();
  if (!key) {
    log('Lookup key is required.');
    return;
  }

  try {
    const result = await GoogleTagManager.getValue({ key });
    log('Value lookup result', { key, value: result?.value });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    log('Get value failed', { message });
  }
});

resetButton?.addEventListener('click', async () => {
  try {
    await GoogleTagManager.reset();
    log('Container reset');
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    log('Reset failed', { message });
  }
});
