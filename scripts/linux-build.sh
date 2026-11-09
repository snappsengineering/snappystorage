#!/usr/bin/env bash
set -euo pipefail
export PATH="${HOME}/.local/share/swiftly/bin:${PATH}"
export LIBRARY_PATH="/usr/lib/gcc/x86_64-linux-gnu/12:${LIBRARY_PATH:-}"
CXX_FLAGS=(-Xcxx -isystem -Xcxx /usr/include/c++/12 -Xcxx -isystem -Xcxx /usr/include/x86_64-linux-gnu/c++/12)
LINK_FLAGS=(-Xlinker -L -Xlinker /usr/lib/gcc/x86_64-linux-gnu/12)
swift build "${CXX_FLAGS[@]}" "${LINK_FLAGS[@]}" "$@"
swift test "${CXX_FLAGS[@]}" "${LINK_FLAGS[@]}" "$@"
