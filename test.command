#!/bin/zsh
set -eu
cd "${0:A:h}"
TEST_DIR=$(mktemp -d -t bookpad-tests)
trap 'rm -rf "$TEST_DIR"' EXIT
xcrun swiftc StickGate.swift ReadingAction.swift Tests/main.swift -o "$TEST_DIR/check"
"$TEST_DIR/check"
