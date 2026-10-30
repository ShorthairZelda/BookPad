#!/bin/zsh
set -eu
cd "${0:A:h}"
APP="$PWD/BookPad.app"
mkdir -p "$APP/Contents/MacOS"
cp Info.plist "$APP/Contents/Info.plist"
xcrun swiftc -swift-version 5 -O -target arm64-apple-macos13.0 StickGate.swift ReadingAction.swift main.swift -framework AppKit -framework GameController -framework ApplicationServices -o "$APP/Contents/MacOS/BookPad"
codesign --force --sign - "$APP"
echo "已生成：$APP"
