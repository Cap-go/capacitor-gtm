import { WebPlugin } from '@capacitor/core';

import type { GoogleTagManagerPlugin } from './definitions';

export class GoogleTagManagerWeb extends WebPlugin implements GoogleTagManagerPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
