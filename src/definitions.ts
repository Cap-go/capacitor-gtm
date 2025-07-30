export interface GoogleTagManagerPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
