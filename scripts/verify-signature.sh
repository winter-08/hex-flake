#!/usr/bin/env bash
# Fails if the packaged app lost its signature or changed signing identity.
# Either would make macOS drop the Microphone and Accessibility grants.
set -euo pipefail

app=${1:?usage: verify-signature.sh path/to/Hex.app}
requirement='identifier "anomaly.hex" and anchor apple generic and certificate leaf[subject.OU] = "5NZ4Q7NXJ4"'

/usr/bin/codesign --verify --deep --strict --verbose=2 -R="$requirement" "$app"

echo "$app matches the pinned Hex signing identity"
