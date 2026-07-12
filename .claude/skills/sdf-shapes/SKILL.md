---
name: sdf-shapes
description: Create smooth organic-but-parametric 3D forms (vases, ergonomic grips, blended sculptural shapes) with the fogleman/sdf Python library. Signed distance fields give free smooth blending; resolution is one knob.
allowed-tools:
  - Bash(*/run-cad-py.sh*)
  - Bash(*/render-scad.sh*)
  - Bash(*/validate-stl.py*)
  - Bash(*/docsearch.py*)
  - Read
  - Write
  - Glob
---

# SDF Organic Shapes Skill

Model with signed distance fields via fogleman/sdf: compose primitives with smooth-blended booleans, then mesh at any resolution. The right tool when a shape should *flow* — every union/difference can be rounded by one parameter.

## When to Use

- **sdf (this skill)** — organic-but-parametric: vases, ergonomic grips, handles, blended sculptural forms (e.g. a chess knight as blended volumes), anything where features should melt together smoothly
- **build123d** (`/build123d`) — mechanical parts, exact dimensions/tolerances
- **OpenSCAD + BOSL2** (`/openscad`) — quick simple parts, .scad deliverables

## Workflow

1. **Read the cheat-sheet first**: `references/sdf-cheatsheet.md` (in this skill directory).
2. **Write a versioned script** `<name>_<version>.py` ending with:

```python
f.save('<name>_<version>.stl', samples=2**22, verbose=False)   # always verbose=False
```

3. **Run it**:

```bash
.claude/skills/sdf-shapes/scripts/run-cad-py.sh <name>_<version>.py
```

The runner executes in the CAD venv and writes `<name>_<version>_view.scad` so the STL flows into the standard preview pipeline.

4. **Preview multi-view + rubric critique**:

```bash
.claude/skills/preview-scad/scripts/render-scad.sh <name>_<version>_view.scad --views std
```

5. **Validate gates** (SDF meshes are usually watertight by construction, but marching cubes can produce defects — always gate):

```bash
python3 .claude/skills/export-stl/scripts/validate-stl.py <name>_<version>.stl --expect-size X,Y,Z
```

## Resolution — the one knob

- `samples=2**22` (~4M): good default, seconds to mesh
- `samples=2**24`: final export of detailed models
- Or fix the cell size directly: `f.save(path, step=0.15, verbose=False)` (mm)
- Too-low resolution shows as stair-stepping in previews and can merge/sever thin features — bump samples before changing geometry

## Retry on Error (max 3 attempts)

Same protocol as the other backends: read the traceback, fix the exact cause, re-run. Empty mesh (`0 triangles`) usually means the shape has no interior (subtracted everything, or `&` with a non-overlapping region). For API questions search local docs:

```bash
~/.venv-cad3d/bin/python .claude/skills/cad-docs/scripts/docsearch.py "your question" --lib sdf
```
