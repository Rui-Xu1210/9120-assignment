#!/bin/zsh
set -eu
cd "$(dirname "$0")"
mkdir -p .build/module-cache
swiftc -swift-version 5 -module-cache-path .build/module-cache -parse-as-library \
  Sources/Core.swift Sources/Store.swift Tests/NativeTests.swift -o .build/NativeTests
.build/NativeTests "$@"
