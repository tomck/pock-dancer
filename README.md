# Dancer for Pock

A nostalgic Microsoft Dancer for your Touch Bar: a [Pock](https://pock.app) widget that plays the classic dancer animations. Pick which dancer you want from a dropdown in Pock's Widgets Manager. One dancer plays at a time; running several animations at once made some of them freeze.

**This repo contains no dancer artwork.** You supply the original files yourself and a script converts them locally, in the same spirit as Tale of Two Wastelands.

## Requirements

- A Touch Bar Mac (this build targets Intel / x86_64) with [Pock](https://pock.app) installed in /Applications
- Xcode command line tools (`xcode-select --install`), and `ffmpeg` (`brew install ffmpeg`)

## Get the dancers

- **Scooby Doo** (the free trial): https://archive.org/details/scooby_dancerle. You need `ScoobyDoo_L.Dnc`.
- **The other dancers** (Amanda and the rest, from the `MSPLUS!DME` disc image): https://archive.org/details/msplus-dme Each dancer is a `.cab` in the disc's folders; the `_l` ones are the large versions.

## Install

```bash
./convert.sh /path/to/ScoobyDoo_L.Dnc /path/to/Amanda_l.cab   # any mix of .Dnc files, .cab files or folders
./build.sh --install
```

Pointing `convert.sh` at a folder converts every dancer in it, preferring the large version of each. Then restart Pock, open the menu bar icon > **Customize Pock...** and drag **Dancer** onto the Touch Bar. Choose which dancer plays in **Widgets Manager > Dancer**.

Dancers live in `~/Library/Application Support/Pock/Dancers`, so converting more later needs no rebuild: they appear in the dropdown straight away.

## How it works

- A Pock widget is a `.pock` bundle, not a SwiftPM library. `build.sh` assembles `Dancer.pock` with `swiftc` and `ibtool`, linking against the PockKit embedded in Pock.app, so no Xcode project is needed.
- `convert.sh` reads each dancer's video, finds the area they dance in from the `.Dat` alpha mask (`detect_crop.py`), and writes frames 60px high: the Touch Bar is 30pt, 60px at 2x. Wider dancers get wider widgets.
- The widget reads frames from disk as they play, so even a seven-minute dancer uses almost no memory.
- The dropdown is Pock's per-widget preferences pane (`PKWidgetPreferenceClass` in `Info.plist`), a small compiled nib plus code.

For Apple silicon, the PockKit module and the `-target` in `build.sh` would need an arm64 pass.
