#!/bin/bash
set -euo pipefail

ARCHS="arm64 x86_64" "$(dirname "$0")/build.sh"