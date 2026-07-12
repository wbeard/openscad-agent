#!/bin/bash

# Run a Python CAD script (build123d or sdf) in the dedicated CAD venv,
# then wire the resulting STL into the existing preview/validation pipeline.

set -e

VENV_PY="$HOME/.venv-cad3d/bin/python"

if [[ ! -x "$VENV_PY" ]]; then
    echo "Error: CAD venv not found at ~/.venv-cad3d"
    echo "Set it up with:"
    echo "  brew install uv   # or pipx install uv"
    echo "  uv venv --python 3.12 ~/.venv-cad3d"
    echo "  uv pip install --python ~/.venv-cad3d/bin/python \\"
    echo "      build123d trimesh numpy rank-bm25 'git+https://github.com/fogleman/sdf.git'"
    exit 1
fi

INPUT="$1"
if [[ -z "$INPUT" || ! -f "$INPUT" ]]; then
    echo "Usage: run-cad-py.sh <script.py>"
    echo "The script should export an STL named after itself (e.g. bracket_001.py -> bracket_001.stl)"
    exit 1
fi

if ! "$VENV_PY" "$INPUT"; then
    echo ""
    echo "SCRIPT ERROR — read the traceback above, fix that exact cause, and retry (max 3 attempts)."
    exit 1
fi

# Wire the produced STL into the preview pipeline via an OpenSCAD import wrapper
STEM="${INPUT%.py}"
STL="${STEM}.stl"
if [[ -f "$STL" ]]; then
    VIEW_SCAD="${STEM}_view.scad"
    echo "import(\"$(basename "$STL")\");" > "$VIEW_SCAD"
    echo ""
    echo "STL produced: $STL"
    echo "Next steps:"
    echo "  Preview:  .claude/skills/preview-scad/scripts/render-scad.sh $VIEW_SCAD --views std"
    echo "  Validate: python3 .claude/skills/export-stl/scripts/validate-stl.py $STL --expect-size X,Y,Z"
else
    echo ""
    echo "Note: no ${STL} found — the script ran but did not export the expected STL."
    echo "Make sure it calls export_stl(part, \"$(basename "$STL")\", ...) or f.save(\"$(basename "$STL")\", ...)."
fi
