#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/tool-env.sh
"$GODOT_BIN" --headless --path . --script tests/smoke.gd
mkdir -p builds
"$GODOT_BIN" --headless --path . --export-release 'Windows Desktop' builds/Summit.exe
python3 - <<'PY'
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib
out=Path('builds/Summit-Windows-x64.zip')
with ZipFile(out,'w',ZIP_DEFLATED,compresslevel=9) as z:
    z.write('builds/Summit.exe','Summit.exe')
    z.write('builds/PLAY.txt','PLAY.txt')
out.with_suffix('.zip.sha256').write_text(hashlib.sha256(out.read_bytes()).hexdigest()+'  '+out.name+'\n')
print('Packaged:',out, '(%d bytes)' % out.stat().st_size)
PY
