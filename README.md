# SUMMIT — The Long Way Up

A complete little mountain-climbing game made with Godot 4.6.3. Leap up a
snowy route of 28 ledges, secure four checkpoint camps, and reach the summit.
Layered alpine scenery, drifting snow, wind, stamina, and synthesized sound;
all art is drawn in the game, with no external asset dependencies.

## Play on Windows

[Download Summit for Windows (64-bit)](https://github.com/olliezwmarshall-create/climb-mountain/raw/refs/heads/main/builds/Summit-Windows-x64.zip)

Extract the ZIP, then double-click **Summit.exe**. Windows 10/11 x64 with
OpenGL 3.3 support is recommended. No Godot installation needed. This is an
unsigned build; Windows may display an unknown-publisher warning.
The adjacent `.sha256` file lets you verify the ZIP's integrity.

| Key | Action |
| --- | --- |
| A/D or arrow keys | Move |
| Space, W, or Up | Jump |
| Shift | Sprint; consumes stamina |
| R | Return to latest camp |
| Escape or P | Pause/resume |
| M | Toggle sound |
| Enter or Space | Start / play again |

Rest on ledges to regain stamina. Flags save your progress within the current
run; falls return you to the latest camp. Progress resets when you quit.
There is no time limit. The full route is reachable without sprinting.

## Develop

Open `project.godot` in **Godot 4.6.3**, then press F6 or F5.
Use the existing checkout: cloud tasks already have their own isolated environment.
No Git worktree is needed.

On Linux x86_64, with Bash, curl, and Python 3.11+:

```bash
bash scripts/setup.sh
source scripts/tool-env.sh
"$GODOT_BIN" --path .
```

Setup uses an existing Godot 4.6.3 or downloads the official binary, then
installs official Windows/Linux release templates after SHA512 verification.
The template archive is about 1.2 GB; tools are cached outside the checkout
at `/workspace/tool-cache`. Set `SUMMIT_TOOL_ROOT` to use another writable
absolute path. No credentials or external services are needed to play.

## Test and compile

```bash
source scripts/tool-env.sh
"$GODOT_BIN" --headless --path . --script tests/smoke.gd
bash scripts/build.sh
```

The test simulates every jump from base to summit using the actual gameplay
physics, plus landing, checkpoint recovery, stamina, pause, and restart checks.
The build script runs tests before exporting `builds/Summit.exe` with its
resources embedded, then packages `builds/Summit-Windows-x64.zip` and its SHA256.
GitHub Actions repeats setup, tests, and export and uploads the resulting ZIP.

Gameplay is validated headlessly on Linux. The Windows export is structurally
checked, but interactive Windows testing is still needed on a Windows machine.
The build is unsigned and does not include an installer.
