# Root of the RuneScape beta client cache (the folder containing the *.jcache files).
# Override by setting the RS_BETA_DIR environment variable.
RS_BETA_DIR := env_var_or_default("RS_BETA_DIR", if os() == "macos" {
  env_var("HOME") / "Jagex/RuneScape-BETA"
} else {
  "/mnt/c/ProgramData/Jagex/RuneScape-BETA"
})

DEV_PLUGINS := RS_BETA_DIR / "dev_plugins"

install: check-beta-dir
    #!/usr/bin/env bash
    set -euo pipefail

    just package_into "{{DEV_PLUGINS}}/cluetrainer"
    just install_devtool

    install_plugin() {
      local plugin_name="$1"
      local target_dir="{{DEV_PLUGINS}}/$(basename "$plugin_name")"

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
install-light: check-beta-dir
    #!/usr/bin/env bash
    set -euo pipefail

    TARGET="{{DEV_PLUGINS}}/cluetrainer"

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

    just install_devtool

# The devtool is a plugin of its own and only gets the data files of Clue Trainer, no code.
[private]
install_devtool:
    #!/usr/bin/env bash
    set -euo pipefail

    TARGET="{{DEV_PLUGINS}}/cluetrainer_devtool"

    rm -rf "$TARGET"
    mkdir -p "$TARGET/cluetrainer/data"
    cp -R cluetrainer_devtool/. "$TARGET/"
    cp -R cluetrainer/cluetrainer/data/. "$TARGET/cluetrainer/data/"

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

[private]
check-beta-dir:
    #!/usr/bin/env bash
    if ! ls "{{RS_BETA_DIR}}"/*.jcache > /dev/null 2>&1; then
      echo "No RuneScape beta cache found at {{RS_BETA_DIR}}." >&2
      echo "Launch the beta client once, or set RS_BETA_DIR to the folder containing the *.jcache files." >&2
      exit 1
    fi

# Paths relative to the project root
BLACKLIST := "^(./)?(cluetrainer/cluetrainer/data|cluetrainer/prettymap/data)(/|$)"

cloc:
    cloc cluetrainer --fullpath --not-match-d '{{BLACKLIST}}' --by-file
