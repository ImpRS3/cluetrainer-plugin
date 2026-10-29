# Clue Trainer

This repository contains the Clue Trainer plugin for the RuneScape client api.
Successor to [Clue Trainer for Alt1](https://github.com/leridon/cluetrainer).

# Getting Started

This project uses [just](https://github.com/casey/just) to manage project-specific commands. The commands are only properly supported in a Unix environment, so if you are developing on Windows you are encouraged to use WSL.

Dependencies are git submodules: `git submodule update --init`.

To install the plugin into the local RuneScape development environment:

```sh
just install
```

Install [PrettyUI](https://mod.io/g/runescape/m/prettyui) once in the beta client via Settings ribbon > Plugins.

The beta client folder defaults to `/mnt/c/ProgramData/Jagex/RuneScape-BETA` (WSL) or `~/Jagex/RuneScape-BETA` (macOS). Set `RS_BETA_DIR` to override it.

## Running on macOS

1. `brew install just`
2. Launch the beta client:

   ```sh
   open 'jagex:launch=runescape,args=[configURI=rs-launch://www.runescape.com/jav_config_beta.ws]'
   ```

3. `just install`
4. In the console (`Option` + the key below `Esc`, English keyboard layout):

   ```
   prf
   pon cluetrainer
   prl cluetrainer   # after every `just install`
   ```
