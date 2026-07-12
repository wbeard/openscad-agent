---
name: preview-scad
description: Render OpenSCAD (.scad) files to PNG images for visual verification. Use this after creating or modifying .scad files to see the 3D result and self-correct if needed.
allowed-tools:
  - Bash(*/render-scad.sh*)
  - Read
---

# OpenSCAD Preview Skill

Render OpenSCAD files to PNG images so you can visually verify your work. Uses the Manifold backend automatically (fast full renders).

## Usage

```
/preview-scad <file.scad> [options]
```

## Workflow

1. After creating or editing a `.scad` file, render it — use multi-view for any design decision:

```bash
.claude/skills/preview-scad/scripts/render-scad.sh <input.scad> --views std
```

2. Read **all** generated PNGs (`<base>_iso.png`, `_front.png`, `_right.png`, `_top.png`)
3. Critique against the rubric below
4. If anything fails, fix the code and re-render
5. If the script prints `COMPILE/GEOMETRY ERROR`, read the exact error text, fix that cause, and retry (max 3 attempts before rethinking the approach)

### Options

- `--views <list>` - `std` (= iso,front,right,top) or comma list of `iso,front,right,top,back,left,bottom`; outputs `<base>_<view>.png` per view, implies full `--render`
- `--output <path>` - Custom output path (default: `<input>.png`)
- `--size <WxH>` - Image dimensions (default: `800x600`)
- `--camera <x,y,z,rx,ry,rz,d>` - Custom camera position (single-view only)
- `--colorscheme <name>` - Color scheme (default: `Cornfield`)
- `--render` - Full render mode (accurate)
- `--preview` - Preview mode (fast; default for single view)

A single fast preview (`render-scad.sh file.scad`) is fine for a quick mid-iteration shape check; always do a `--views std` pass before exporting.

## Critique Rubric

For each render pass, explicitly answer:

1. **Completeness** — every feature from the spec visible in at least one view?
2. **Proportions** — relative sizes match the stated dimensions?
3. **Placement** — features in the right position/orientation? (top view catches XY offsets; front/right catch Z errors)
4. **Printability** — overhangs >45°, floating geometry, walls under 0.8 mm, accidentally fused features?
5. **Regression** — anything worse than the previous version's renders?

## Next Steps

Once the rubric passes:

1. **Export to STL**: Use `/export-stl` — it runs hard geometry gates (trimesh + prusa-slicer)

## Full Pipeline

```
/openscad → /preview-scad (--views std + rubric) → /export-stl (validation gates)
```
