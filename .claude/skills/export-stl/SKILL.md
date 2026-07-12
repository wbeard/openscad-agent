---
name: export-stl
description: Export OpenSCAD (.scad) files to STL format with hard geometry validation gates (trimesh + prusa-slicer). Fails on non-watertight meshes, non-manifold edges, open edges, and bounding-box drift.
allowed-tools:
  - Bash(*/export-stl.sh*)
  - Bash(*/validate-stl.py*)
  - Read
---

# Export STL Skill

Convert OpenSCAD files to STL for 3D printing, then run hard printability gates. Uses the Manifold backend automatically.

## When to Use

Use this skill after:
1. The design passed the multi-view rubric critique in previews
2. You're ready to export for 3D printing

## Usage

```bash
.claude/skills/export-stl/scripts/export-stl.sh <input.scad> [options]
```

### Options

- `--output <path>` - Custom output path (default: `<input>.stl`)
- `--expect-size <X,Y,Z>` - Expected outer bounding box in mm; **always pass this for functional parts** so dimension drift is caught
- `--tolerance <mm>` - Allowed bbox deviation per axis (default 0.5)
- `--allow-multi-part` - Don't fail on disconnected parts (for intentionally multi-piece exports)
- `--no-validate` - Skip gates (debugging only)
- `--binary` / `--ascii` - STL format (binary default)

### Exit Codes

- `0` - exported and all gates passed
- `1` - export failed (compile/render error; the exact `ERROR:` lines are printed)
- `2` - exported but validation gates **FAILED** — read the `FAIL:` lines, fix the .scad source, re-export (max 3 attempts, then rethink the failing feature)

## Validation Gates

After export, `validate-stl.py` runs two independent checkers:

**trimesh** (hard gates):
- watertight (no open edges / holes in the surface)
- no non-manifold edges (edge shared by >2 faces)
- consistent face winding, positive volume
- single connected part (unless `--allow-multi-part`)
- bounding box within `--tolerance` of `--expect-size`

**prusa-slicer --info** (cross-check): `manifold = yes`, open edges, bbox, volume.

Warnings (degenerate faces, missing optional tools) do not fail the gate.

## Example

```bash
.claude/skills/export-stl/scripts/export-stl.sh enclosure_003.scad --expect-size 56,36,14
```

```
--- trimesh ---
watertight          = True
...
VALIDATION: PASS — mesh is watertight, manifold, and within tolerance
RESULT: Export successful — all gates passed
```

## Fixing Common Gate Failures

- **NOT watertight / open edges** — a shape isn't a closed solid (2D primitive in 3D context, unclosed polyhedron)
- **Non-manifold edges** — shapes touching at exactly one edge or face: overlap them by ≥0.01 mm and `union()` (BOSL2: `attach(..., inside=true, shiftout=0.01)`)
- **Inconsistent winding / negative volume** — inverted geometry, often from negative `scale()` or hand-built polyhedra
- **bbox out of tolerance** — a dimension parameter is wrong, or walls/roundings changed the outer size; compare the reported bbox against your parameters
- **Multiple parts** — floating geometry that touches nothing; connect it or export it as its own model

## Notes

- The validator can be run standalone on any STL: `python3 .claude/skills/export-stl/scripts/validate-stl.py file.stl --expect-size X,Y,Z`
- Requires `trimesh` (pip) and PrusaSlicer (both installed); each check degrades to a warning if its tool is missing
- Binary STL is recommended (smaller files, faster to process)
