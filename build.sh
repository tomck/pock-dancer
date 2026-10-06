#!/bin/bash
# Builds Dancer.pock (a Pock widget) without Xcode. Usage: ./build.sh [--install]
# Dancers aren't baked in: the widget reads whatever convert.sh has put in
# ~/Library/Application Support/Pock/Dancers.
set -euo pipefail
cd "$(dirname "$0")"

POCK_APP="/Applications/Pock.app"
POCKKIT_DIR=".build/pockkit"
MODULES="$POCKKIT_DIR/.build/x86_64-apple-macosx/debug/Modules"
OUT=".build/Dancer.pock"

# PockKit's Swift module (the copy embedded in Pock.app ships only the binary).
if [ ! -d "$MODULES/PockKit.swiftmodule" ]; then
    mkdir -p .build
    [ -d "$POCKKIT_DIR" ] || git clone --depth 1 https://github.com/pock/pockkit.git "$POCKKIT_DIR"
    (cd "$POCKKIT_DIR" && swift build)
fi

rm -rf "$OUT"
mkdir -p "$OUT/Contents/MacOS" "$OUT/Contents/Resources"

# Module name must match the class prefixes in Info.plist ("Dancer.DancerWidget").
swiftc Sources/*.swift \
    -module-name Dancer \
    -target x86_64-apple-macosx10.15 \
    -parse-as-library \
    -I "$MODULES" \
    -F "$POCK_APP/Contents/Frameworks" -framework PockKit \
    -Xlinker -bundle \
    -Xlinker -rpath -Xlinker @executable_path/../Frameworks \
    -o "$OUT/Contents/MacOS/Dancer" 2>&1 | { grep -E "error" || true; }
[ -f "$OUT/Contents/MacOS/Dancer" ] || { echo "Compile failed" >&2; exit 1; }

cp Info.plist "$OUT/Contents/Info.plist"
# The preferences pane's nib (the dropdown itself is built in code).
ibtool --errors --warnings --compile "$OUT/Contents/Resources/DancerPreferencePane.nib" DancerPreferencePane.xib >/dev/null
codesign --force --sign - "$OUT"
echo "Built $OUT"

if [ "${1:-}" = "--install" ]; then
    DEST="$HOME/Library/Application Support/Pock/Widgets"
    mkdir -p "$DEST"
    rm -rf "$DEST/Dancer.pock"
    cp -R "$OUT" "$DEST/Dancer.pock"
    echo "Installed to $DEST/Dancer.pock. Restart Pock to load it."
fi
