install: 
    #!/usr/bin/env bash
    set -euo pipefail

    CACHE_DIR="/mnt/c/ProgramData/Jagex/RuneScape-BETA"

    just package_into "$CACHE_DIR/dev_plugins/cluetrainer"

    install_plugin() {
      local plugin_name="$1"
      local target_dir="$CACHE_DIR/dev_plugins/$(basename "$plugin_name")"

      if [ -d "$target_dir" ]; then
        rm -rf "$target_dir"
      fi

      cp -r "$plugin_name" "$target_dir"
    }

    for plugin in dependencies/dynamic/*; do
      if [ -d "$plugin" ]; then
        install_plugin "$plugin"
      fi
    done

package: (package_into "dist/cluetrainer")

[private]
package_into target:
    rm -rf "{{target}}"
    mkdir -p "{{target}}"
    cp -R cluetrainer/. "{{target}}/"
    cp -R dependencies/zyklib/src/. "{{target}}/"
