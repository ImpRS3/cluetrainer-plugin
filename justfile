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

# Replaces everything in the installed plugin except the resources folder.
install-light:
    #!/usr/bin/env bash
    set -euo pipefail

    TARGET="/mnt/c/ProgramData/Jagex/RuneScape-BETA/dev_plugins/cluetrainer"

    mkdir -p "$TARGET"
    find "$TARGET" -mindepth 1 -maxdepth 1 ! -name resources -exec rm -rf {} +

    copy_without_resources() {
      local src="$1"
      (
        cd "$src"
        find . -path ./resources -prune -o -type f -print0 | while IFS= read -r -d '' f; do
          mkdir -p "$TARGET/$(dirname "$f")"
          cp -f "$f" "$TARGET/$f"
        done
      )
    }

    copy_without_resources cluetrainer
    copy_without_resources dependencies/zyklib/src

package: (package_into "dist/cluetrainer")

package-zip: (package_into "dist/cluetrainer")
    #!/usr/bin/env bash
    set -euo pipefail

    rm -f dist/cluetrainer.zip
    (
      cd dist/cluetrainer
      shopt -s dotglob nullglob
      zip -r ../cluetrainer.zip *
    )

[private]
package_into target:
    rm -rf "{{target}}"
    mkdir -p "{{target}}"
    cp -R cluetrainer/. "{{target}}/"
    cp -R dependencies/zyklib/src/. "{{target}}/"
