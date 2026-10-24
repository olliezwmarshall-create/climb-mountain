#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/tool-env.sh
release=https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable
curl -fsSL --retry 2 "$release/SHA512-SUMS.txt" -o "$SUMMIT_TOOL_ROOT/SHA512-SUMS.txt"
if [[ ! -x "$GODOT_BIN" ]]; then
  engine=Godot_v4.6.3-stable_linux.x86_64.zip
  curl -fL --retry 2 "$release/$engine" -o "$SUMMIT_TOOL_ROOT/$engine"
  python3 - "$SUMMIT_TOOL_ROOT" "$engine" <<'PY'
import hashlib, pathlib, sys, zipfile
root=pathlib.Path(sys.argv[1]); name=sys.argv[2]
expected=next(s.split()[0] for s in (root/'SHA512-SUMS.txt').read_text().splitlines() if s.split()[-1]==name)
with (root/name).open('rb') as f:
    assert hashlib.file_digest(f,'sha512').hexdigest()==expected, 'Engine checksum mismatch'
with zipfile.ZipFile(root/name) as z:
    z.extract('Godot_v4.6.3-stable_linux.x86_64',root)
(root/'Godot_v4.6.3-stable_linux.x86_64').chmod(0o755)
PY
fi
"$GODOT_BIN" --version | grep -q '^4\.6\.3\.'
templates="$XDG_DATA_HOME/godot/export_templates/4.6.3.stable"
if [[ ! -f "$templates/windows_release_x86_64.exe" || ! -f "$templates/linux_release.x86_64" ]]; then
  if [[ ! -f "$SUMMIT_TOOL_ROOT/templates.tpz" ]]; then
    curl -fL --retry 2 "$release/Godot_v4.6.3-stable_export_templates.tpz" -o "$SUMMIT_TOOL_ROOT/templates.tpz"
  fi
  python3 - "$SUMMIT_TOOL_ROOT" <<'PY'
import hashlib, pathlib, sys, zipfile
root=pathlib.Path(sys.argv[1])
expected=next(s.split()[0] for s in (root/'SHA512-SUMS.txt').read_text().splitlines() if s.split()[-1]=='Godot_v4.6.3-stable_export_templates.tpz')
with (root/'templates.tpz').open('rb') as f:
    assert hashlib.file_digest(f,'sha512').hexdigest()==expected, 'Templates checksum mismatch'
out=root/'data/godot/export_templates/4.6.3.stable'; out.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(root/'templates.tpz') as z:
    for name in ['windows_release_x86_64.exe','linux_release.x86_64','version.txt']:
        (out/name).write_bytes(z.read('templates/'+name))
print('Official export template checksums verified; templates installed.')
PY
fi
"$GODOT_BIN" --headless --path . --editor --import --quit
