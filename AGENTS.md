# OpenSCAD Agent

This project provides Claude Code skills for creating, iterating, and validating 3D printable models across three CAD backends.

## Backend Decision Guide (pick first, before writing code)

| Shape class | Backend | Skill |
|-------------|---------|-------|
| Mechanical/functional parts: enclosures, brackets, fixtures, anything with fillets/shells/counterbores/tolerances | **build123d** (preferred) | `/build123d` |
| Quick simple parametric parts, or when a .scad file is the deliverable | OpenSCAD + BOSL2 | `/openscad` |
| Smooth organic-but-**parametric**: vases, grips, blended sculptural forms | **sdf** | `/sdf-shapes` |
| Figurines, creatures, faces, freeform sculpture — from text or a photo; anything no code can author | **generative 3D** | `/mesh3d` |
| Flat 2D outlines extruded to 3D | SVG workflow | `/openscad` (SVG section) |
| Legacy: swept ribbons/metaballs | Blender Python | `/openscad` (Blender section) |

The `/mesh3d` ↔ code-CAD boundary is hard: generative meshes cannot hold a
dimension, so anything with a tolerance or mating face goes to code-CAD even
if it "looks organic" — and code-CAD cannot author a face or drapery, so
sculpture goes to `/mesh3d` even if the user mentions millimeters (that's the
print height, not a tolerance).

Every backend feeds the same loop: **multi-view render → rubric critique → validation gates**.

## Complete Workflow

```
1. Write model source (.scad via /openscad, or .py via /build123d //sdf-shapes)
2. /preview-scad →  Multi-view render (--views std), critique against the rubric
                    (Python backends: render the auto-generated <name>_view.scad)
3. Validate      →  /export-stl for .scad; validate-stl.py directly for Python-
                    produced STLs. Hard gates: watertight, manifold, open edges,
                    bbox-vs-spec. Exit 2 = fix source and retry (max 3)
```

All OpenSCAD scripts use the Manifold backend automatically — full renders and high facet counts are fast.

## Documentation Search (use it — don't guess APIs)

Before using an unfamiliar BOSL2/build123d/sdf API, or after any API error:

```bash
~/.venv-cad3d/bin/python .claude/skills/cad-docs/scripts/docsearch.py "query" --lib bosl2|build123d|sdf
```

## Quality Defaults

- Start files with `$fa = 1; $fs = 0.4;` — never a low global `$fn`. Use per-feature `$fn` only on small round features (e.g. `$fn=32` on a 3 mm hole).
- Use **BOSL2** (installed) for mechanical/functional parts: rounded boxes, screw holes, threads, anchored placement. Read `.claude/skills/openscad/references/bosl2-cheatsheet.md` before writing BOSL2 code.
- For functional parts, collect exact datasheet/measured dimensions first, declare them as named parameters, and pass `--expect-size X,Y,Z` to export-stl so dimension drift fails the gate.
- On any compile/geometry error or gate failure: read the exact error, fix that cause, retry — at most 3 attempts before rebuilding the failing feature differently.

## Available Skills

### `/build123d` - Mechanical Parts (B-rep CAD, preferred for functional parts)

Write build123d Python scripts (`<name>_<ver>.py`) run via `run-cad-py.sh` in the `~/.venv-cad3d` venv. Real fillets/chamfers/shells/counterbores; STL smoothness is one `export_stl(tolerance=0.01)` knob. Read `.claude/skills/build123d/references/build123d-cheatsheet.md` first.

### `/sdf-shapes` - Organic Forms (signed distance fields)

fogleman/sdf scripts with smooth-blended booleans (`.k(mm)`), shells, twists, bends. Resolution = `samples` parameter. Read `.claude/skills/sdf-shapes/references/sdf-cheatsheet.md` first. Always `verbose=False` in `.save()`.

### `/mesh3d` - Generative 3D (text/image → STL)

Text → conditioning image (templated for reconstruction, not aesthetics) →
GPU shape server (HTTP, `MESH3D_SHAPE_ENDPOINT`) → Blender voxel-remesh print
prep → suite gates. Iterate on the *image* (cheap), not the mesh (GPU
dollars); classify every defect as IMAGE / SHAPE / PREP before acting — see
`.claude/skills/mesh3d/references/failure-modes.md`.

### `/cad-docs` - Local Documentation Search

BM25 over BOSL2 wiki + build123d docs + sdf README in `~/.cad-docs`. Query before writing unfamiliar API calls and after API errors.

### `/openscad` - Create Versioned 3D Models

Creates versioned OpenSCAD files with automatic version numbering and preview rendering.

**Workflow:**
1. Use `version-scad.sh <name>` to find the next version number
2. Write the .scad file with that version (e.g., `piano_001.scad`)
3. Render to PNG with matching version (e.g., `piano_001.png`)
4. Compare with previous versions to evaluate changes
5. Iterate until the design meets requirements

### `/preview-scad` - Render OpenSCAD to PNG

Renders .scad files to PNG images for visual verification. Use `--views std` for iso/front/right/top renders and critique all four against the rubric (completeness, proportions, placement, printability, regression).

### `/export-stl` - Export to STL with Hard Validation Gates

Converts finalized OpenSCAD designs to STL and runs trimesh + prusa-slicer gates:
- FAILS (exit 2) on: non-watertight mesh, open edges, non-manifold edges, inconsistent winding, disconnected parts, bbox outside `--expect-size` tolerance
- Warns on degenerate faces
- The `FAIL:` lines state the specific defect to fix in the .scad source

**When to use:** After iterating on the design and confirming the multi-view rubric passes.

## File Naming Convention

```
<model-name>_<version>.scad  →  <model-name>_<version>.png  →  <model-name>_<version>.stl
```

- Use underscores in model names
- Use 3-digit zero-padded version numbers (001, 002, etc.)
- Each version gets matching .scad, .png, and .stl files

Examples:
- `phone_stand_001.scad` → `phone_stand_001.png` → `phone_stand_001.stl`
- `gear_002.scad` → `gear_002.png` → `gear_002.stl`

## Iterative Design Process

When creating 3D models:

1. **Start simple** - Create a basic version first
2. **Render and inspect** - Always preview after changes
3. **Compare versions** - Read both current and previous PNGs to see what changed
4. **Document changes** - Tell the user what improved between versions
5. **Export when ready** - Only export to STL once the design looks correct
6. **Check validation** - Review geometry warnings and fix if needed

## Printability Guidelines

When designing for 3D printing:

- **Minimum wall thickness**: 0.4mm (single extrusion width)
- **Overhangs**: Keep under 45° or add supports/chamfers
- **Bridging**: Short bridges (<10mm) print better
- **Connected parts**: All geometry must be connected or touching the bed
- **Tolerances**: Add 0.2-0.5mm clearance for parts that fit together
- **Manifold geometry**: All shapes must be closed solids (no holes in mesh)

## Blender Python Workflow (Recommended for Complex 3D Shapes)

For complex organic, sculptural, or jewelry-like 3D models (swept ribbons, metaball blobs, curved tubes, rounded forms), use **Blender's headless Python scripting** instead of OpenSCAD or SVG:

```
blender --background --python script.py  -->  STL (instant)  -->  OpenSCAD import for preview
```

Key advantages over OpenSCAD:
- **True 3D swept tubes/ribbons** along arbitrary parametric paths (not extruded 2D)
- **Metaballs** for organic blobby shapes that automatically merge
- **Curves with bevel** for cylindrical bars (replaces slow hull/sphere chains)
- **Subdivision surfaces** for rounded cubes (replaces slow minkowski)
- **Instant STL export** (~2ms vs minutes in OpenSCAD)

**Decision guide:**
- **Blender**: Organic shapes, swept curves, metaballs, complex jewelry, anything with true 3D swept geometry
- **OpenSCAD**: Simple geometric/mechanical parts, boolean operations, quick prototypes
- **SVG**: Flat 2D outlines extruded to 3D only

See the full guide in `.claude/skills/openscad/SKILL.md` and the template script at `.claude/skills/openscad/scripts/blender-template.py`.

## SVG-Based Workflow

For flat 2D-to-3D shapes (outlines, grid patterns, text silhouettes), use the SVG-based workflow:

1. **Generate SVG with Python** -- use filled shapes (not strokes), output in mm units
2. **Import in OpenSCAD** -- `rotate([90,0,0]) linear_extrude(height) import("file.svg");`
3. **Multi-layer depth** -- split into separate SVGs, extrude each at different heights

This is 100-1000x faster than equivalent hull/sphere chains for 2D geometry. See the full guide in `.claude/skills/openscad/SKILL.md` and the template script at `.claude/skills/openscad/scripts/generate-svg-template.py`.

## OpenSCAD Tips

- Curve quality: `$fa=1; $fs=0.4;` globally; per-feature `$fn` only on small round features
- Use `module` to create reusable components
- Use `difference()` to subtract shapes, `union()` to combine
- Use `translate()`, `rotate()`, `scale()` for positioning
- Use `hull()` for organic shapes and smooth transitions (or SVG workflow for complex cases)
- Use `minkowski()` for rounded edges (but it's slow)
- Always use `union()` when combining overlapping shapes to avoid self-intersection

## Decision Documentation

This project maintains a decision log at `docs/decisions/`. At the start of
every session, read the most recent entry for context. At the end of every
session that involves code changes, create a new entry documenting the
decisions made. See docs/decisions/INDEX.md for the full history.