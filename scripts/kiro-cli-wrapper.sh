#!/bin/sh
# Thin wrapper that delegates to the user's pre-installed kiro-cli binary.
# This script is distributed inside platform-specific archives so that
# Zed (and other ACP clients) can spawn it as an agent server.
#
# Prerequisites:
#   kiro-cli must be on PATH.  Install with:
#     curl -fsSL https://cli.kiro.dev/install | bash

exec kiro-cli acp "$@"
