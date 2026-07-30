#!/bin/bash

CACHE_DIR="/mnt/c/ProgramData/Jagex/RuneScape-BETA"

install_plugin() {
  local plugin_name="$1"
  local target_dir="$CACHE_DIR/$(basename "$plugin_name")"

  # Remove existing plugin folder if it exists
  if [ -d "$target_dir" ]; then
    rm -rf "$target_dir"
  fi

  # Copy plugin folder to target directory
  cp -r "$plugin_name" "$target_dir"
}

install_plugin "cluetrainer"

for plugin in dependencies/plugins/*; do
  if [ -d "$plugin" ]; then
    install_plugin "$plugin"
  fi
done

for plugin in mre/*; do
  if [ -d "$plugin" ]; then
    install_plugin "$plugin"
  fi
done

