#!/usr/bin/env bash
# Source this file from the repository root.
export SUMMIT_TOOL_ROOT="${SUMMIT_TOOL_ROOT:-/workspace/tool-cache}"
export XDG_DATA_HOME="$SUMMIT_TOOL_ROOT/data"
export XDG_CONFIG_HOME="$SUMMIT_TOOL_ROOT/config"
export XDG_CACHE_HOME="$SUMMIT_TOOL_ROOT/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
if [[ -z "${GODOT_BIN:-}" ]]; then
  if command -v godot >/dev/null 2>&1; then
    export GODOT_BIN="$(command -v godot)"
  elif [[ -x /opt/godot/4.6.3/Godot_v4.6.3-stable_linux.x86_64 ]]; then
    export GODOT_BIN=/opt/godot/4.6.3/Godot_v4.6.3-stable_linux.x86_64
  else
    export GODOT_BIN="$SUMMIT_TOOL_ROOT/Godot_v4.6.3-stable_linux.x86_64"
  fi
fi
