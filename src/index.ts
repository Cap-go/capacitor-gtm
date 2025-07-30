import { registerPlugin } from '@capacitor/core';

import type { GoogleTagManagerPlugin } from './definitions';

const GoogleTagManager = registerPlugin<GoogleTagManagerPlugin>('GoogleTagManager', {
  web: () => import('./web').then((m) => new m.GoogleTagManagerWeb()),
});

export * from './definitions';
export { GoogleTagManager };
