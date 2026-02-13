# Audio Assets

This folder is intentionally present for package asset registration (`assets/audio/`).

Expected runtime files referenced by `SoundService`:

- `bass_drop.mp3`
- `glitch_noise.mp3`
- `click.mp3`
- `bg_music.mp3`

These files are currently not committed in this repository snapshot. Playback now degrades gracefully and logs a one-time missing asset warning per file.
