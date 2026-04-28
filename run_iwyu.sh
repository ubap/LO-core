#!/bin/bash
# Pobierz ścieżkę do SDK z Xcode
SDK_PATH=$(xcrun --show-sdk-path)

# Uruchom IWYU dla konkretnego pliku
include-what-you-use -p -Xiwyu --verbose=1 \
  -Xclang -isysroot -Xclang $SDK_PATH \
  "$1"
