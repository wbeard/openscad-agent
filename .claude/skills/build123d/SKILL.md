---
name: build123d
description: Create mechanical parts with build123d (Python B-rep CAD on OpenCascade). Preferred backend for functional/mechanical parts — real fillets, chamfers, shells, counterbores, and toleranced arbitrary-smooth STL export.
allowed-tools:
  - Bash(*/run-cad-py.sh*)
  - Bash(*/render-scad.sh*)
  - Bash(*/validate-stl.py*)
  - Bash(*/docsearch.py*)
  - Read
  - Write
  - Glob
---

# build123d Mechanical CAD Skill

Write parametric mechanical parts as build123d Python scripts. build123d is a B-rep kernel (OpenCascade), so fillets/chamfers/shells are exact surface operations — not mesh approximations — and STL smoothness is a single export tolerance knob.

## When to Use (vs the other backends)

- **build123d (this skill)** — default for mechanical/functional parts: enclosures, brackets, fixtures, anything with fillets, shells, counterbores, press fits, exact tolerances
- **OpenSCAD + BOSL2** (`/openscad`) — quick simple parts, or when the user wants a .scad file
- **sdf** (`/sdf-shapes`) — smooth organic-but-parametric forms (grips, vases, blended sculpts)
- Blender/SVG — see `/openscad` skill for those niches

## Workflow

1. **Read the cheat-sheet first**: `references/build123d-cheatsheet.md` (in this skill directory) — API subset, selectors, gotchas, compile-verified examples.
2. **Dimensions first**: collect exact datasheet/measured dimensions, declare them as named parameters at the top with source comments (same rule as `/openscad`).
3. **Write a versioned script** `<name>_<version>.py` (same `_001` convention) ending with:

```python
export_stl(part, "<name>_<version>.stl", tolerance=0.01, angular_tolerance=0.1)
```

4. **Run it**:

```bash
.claude/skills/build123d/scripts/run-cad-py.sh <name>_<version>.py
```

The runner executes the script in the CAD venv (`~/.venv-cad3d`) and auto-writes `<name>_<version>_view.scad` so the STL flows into the standard preview pipeline.

5. **Preview multi-view + rubric critique** (same rubric as `/preview-scad`):

```bash
.claude/skills/preview-scad/scripts/render-scad.sh <name>_<version>_view.scad --views std
```

6. **Validate gates**:

```bash
python3 .claude/skills/export-stl/scripts/validate-stl.py <name>_<version>.stl --expect-size X,Y,Z
```

Exit 2 = gate failure; the `FAIL:` lines state the defect.

## Retry on Error (max 3 attempts)

- Python traceback → read the exact exception. build123d errors are specific (`fillet radius too large`, empty ShapeList from a selector, etc.). Fix that cause only, re-run.
- Unfamiliar API or persistent error → **search the local docs** before guessing:

```bash
~/.venv-cad3d/bin/python .claude/skills/cad-docs/scripts/docsearch.py "your question" --lib build123d
```

- After 3 failed attempts, rebuild the failing feature differently and tell the user.

## STL Quality

`tolerance` is max linear deviation in mm (0.01 = production quality), `angular_tolerance` in radians (0.1 default). Lower = smoother = more triangles. There is no $fn — curvature is exact until meshing.
