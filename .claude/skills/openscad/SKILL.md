---
name: openscad
description: Create versioned OpenSCAD (.scad) files for 3D printing, render previews, and compare iterations. Use this when designing or iterating on 3D models.
allowed-tools:
  - Bash(*/render-scad.sh*)
  - Bash(*/version-scad.sh*)
  - Bash(*/export-stl.sh*)
  - Bash(*openscad*)
  - Bash(*python*)
  - Bash(*blender*)
  - Read
  - Write
  - Glob
  - Task
---

# OpenSCAD Design Skill

Create versioned OpenSCAD files, render previews, and compare iterations for 3D printing designs.

## Quality Defaults (always)

Start every hand-written .scad file with:

```openscad
include <BOSL2/std.scad>   // when using BOSL2 (default for mechanical parts)
$fa = 1; $fs = 0.4;        // production curve quality
```

- **Never set a low global `$fn`** (e.g. `$fn=48`) — it makes small holes polygonal and large curves faceted at the same time. `$fa=1; $fs=0.4;` adapts facet count to feature size.
- Add per-feature `$fn` only on small round features where you want explicit control, e.g. `cylinder(d=3, h=10, $fn=32)` for a screw hole.
- High facet counts are cheap: the render/export scripts pass `--backend Manifold` automatically (fast boolean engine, default in current OpenSCAD snapshots).

## Exact Dimensions First

Before writing geometry for a functional part:

1. Collect exact datasheet or measured dimensions (PCB size, hole spacing, screw sizes, clearances). Ask the user or search for the component's datasheet — do not guess critical dimensions.
2. Declare them as named parameters at the top of the file, with a comment citing the source.
3. Give the exporter the expected outer bounding box: `export-stl.sh model.scad --expect-size X,Y,Z` — export fails if the real footprint drifts from spec.

## BOSL2 (default for mechanical/functional parts)

BOSL2 is installed in the OpenSCAD library path. **Read `references/bosl2-cheatsheet.md` (in this skill directory) before writing BOSL2 code** — it contains the API subset that matters, the gotchas, and compile-verified idiomatic examples.

Reach for BOSL2 whenever a part needs rounded/chamfered edges, screw holes or threads, anchored feature placement (`attach`/`position` instead of coordinate math), repeated features (`grid_copies`, `zrot_copies`), enclosures, hinges, or gears. Plain OpenSCAD primitives remain fine for trivial single-primitive parts.

## Workflow

### 1. Determine the Next Version Number

Before creating a new .scad file, find existing versions:

```bash
.claude/skills/openscad/scripts/version-scad.sh <name>
```

This returns the next version number and filename. For example, if `piano_001.scad` exists, it returns `piano_002`.

### 2. Create the Versioned .scad File

Write the OpenSCAD code to the versioned filename (e.g., `piano_002.scad`).

### 3. Render Multi-View Previews

```bash
.claude/skills/preview-scad/scripts/render-scad.sh <name>_<version>.scad --views std
```

This produces four full renders: `<name>_<version>_iso.png`, `_front.png`, `_right.png`, `_top.png`. **Read ALL four images** — a single view hides missing features, wrong depths, and XY misplacement. (For a quick shape check mid-iteration, a single fast preview `render-scad.sh file.scad` is fine; always do a `--views std` pass before exporting.)

If the script prints `COMPILE/GEOMETRY ERROR`, enter the retry protocol below.

### 4. Critique Against the Rubric

For every iteration, explicitly answer each point before touching code:

1. **Completeness** — is every feature from the spec visible in at least one view (holes, posts, lips, chamfers, text)?
2. **Proportions** — do relative sizes match the stated dimensions? Check front/right for heights, top for footprint.
3. **Placement** — are features in the right location and orientation? The top view catches XY offsets; front/right catch Z errors and flipped parts.
4. **Printability** — overhangs steeper than 45° without support? floating/disconnected geometry? walls thinner than 0.8 mm? features accidentally fused?
5. **Regression** — compared to the previous version's images, did anything get worse?

Also compare with the previous version's renders (e.g., `piano_001_iso.png` vs `piano_002_iso.png`) to confirm the change did what you intended.

### 5. Iterate

If the design fails any rubric point:
1. Write down what's wrong — be specific (e.g., "screw posts 2mm too far apart in top view", "lip missing in front view")
2. Create the next version (e.g., `piano_003.scad`)
3. Render and critique again

### Retry on Execution Error (max 3 attempts)

When a render or export prints an error (parse error, BOSL2 assertion, geometry failure):

1. Read the exact error text — OpenSCAD errors name the file/line; BOSL2 assertions name the exact parameter and constraint that failed.
2. Fix only that cause and re-run the same command.
3. After 3 failed attempts, stop tweaking: rebuild the failing feature a different way (or drop it) and tell the user what you changed.

The same protocol applies to validation gate failures from `export-stl.sh` (exit code 2): the `FAIL:` lines state the defect (open edges, non-manifold edge, inconsistent winding, bbox out of tolerance) — fix the .scad source and re-export.

## Matching a Reference Image

When the user provides a reference image to replicate:

1. **Decompose** the reference into distinct elements (cage, ribbon, blob, etc.)
2. **Start with structure** — get the main shape/proportions right first
3. **Layer in details** — add decorative elements one at a time
4. **Compare methodically** — after each render, list specific differences from the reference
5. **Parallelize** — for complex designs, use Task agents to iterate on different elements simultaneously, then combine the best of each

### Parallel Iteration Strategy

For complex models, launch multiple agents working on different aspects:
- Agent A: Ribbon/curves
- Agent B: Organic/blob forms
- Agent C: Structural proportions
- Agent D: Overall composition

Then use a judge agent to pick the best elements and combine them.

## File Naming Convention

```
<model-name>_<version>.scad  ->  <model-name>_<version>.png
```

- Use underscores in model names
- Use 3-digit zero-padded version numbers (001, 002, etc.)
- For parallel agents: `<model-name>_<agent>_<version>.scad` (e.g., `pendant_A_001.scad`)

## Render Options

```bash
.claude/skills/preview-scad/scripts/render-scad.sh <input.scad> [options]
```

- `--views <list>` — Multi-view render: `std` (= iso,front,right,top) or any comma list of `iso,front,right,top,back,left,bottom`; outputs `<base>_<view>.png` per view and implies `--render`
- `--output <path>` — Output PNG path (default: `<input>.png`)
- `--size <WxH>` — Image dimensions (default: `800x600`, use `1024x768` for detail)
- `--camera <x,y,z,rx,ry,rz,d>` — Custom camera position
- `--colorscheme <name>` — Color scheme (default: `Cornfield`)
- `--render` — Full render mode (accurate; fast now thanks to Manifold)
- `--preview` — Preview mode (default for single-view)

### Useful Camera Angles

- Default (auto): omit `--camera` for automatic viewall
- Front: `--camera 0,-80,20,11,3.5,20,80`
- 3/4 view: `--camera 30,20,25,11,3.5,20,80`
- Side: `--camera 90,0,20,11,3.5,20,80`

## OpenSCAD Techniques

### Organic/Flowing Shapes
- **Tubular paths**: Chain `hull()` between consecutive `sphere()` placements along a parametric curve
- **Ribbons**: Use `hull()` between `scale([thin, wide, 1]) sphere(r)` pairs for flat ribbon cross-sections
- **Puddles/blobs**: Layer multiple `scale([x,y,z]) sphere(r)` with different flattening factors
- **Smooth transitions**: Use `hull()` to blend between two shapes
- **Wavy forms**: Add `sin()/cos()` perturbation to parametric paths

### Structural/Grid Shapes
- **Bar/rod**: `hull() { translate(p1) sphere(r); translate(p2) sphere(r); }`
- **Rounded cube**: `minkowski() { cube(size - 2*r, center=true); sphere(r); }`
- **Torus/ring**: `rotate_extrude() translate([R,0,0]) circle(r);`

### Key Functions
- `smoothstep(a,b,t)` — Smooth interpolation for transitions
- Curve quality: `$fa=1; $fs=0.4;` globally; per-feature `$fn` only on small round features (see Quality Defaults above)

### Common Pitfalls
- `hull()` of many spheres is expensive — keep step count reasonable (200-400)
- `minkowski()` is slow — avoid in loops; prefer BOSL2 `cuboid(..., rounding=r)` for rounded boxes
- Always wrap overlapping geometry in `union()` to avoid self-intersection in STL
- Shapes touching at exactly one face/edge produce non-manifold meshes — overlap them by ≥0.01 mm (BOSL2 `attach(..., inside=true, shiftout=0.01)` handles this)
- Flat shapes (scale Z near 0) can cause degenerate faces — keep minimum 0.2

## Full Pipeline

```
/openscad → /preview-scad (--views std) → rubric critique → /export-stl
    ↑______________|                            |               |
    (iterate until rubric passes)               |               ↓
    ↑___________________________________________|    trimesh + prusa-slicer gates
    ↑                                                (watertight, manifold, bbox)
    ↑____________________________________________________________| (exit 2 = fix & retry, max 3)
```

## SVG-Based Workflow (Recommended for Complex Shapes)

For complex organic curves, blobs, ribbons, and detailed 2D outlines, generate SVG paths with Python instead of building shapes purely in OpenSCAD. This approach is **100-1000x faster** (sub-second vs 2+ minutes) and produces more precise geometry.

### When to Use SVG vs Pure OpenSCAD

| Use SVG + linear_extrude | Use OpenSCAD + BOSL2 |
|--------------------------|----------------------|
| Organic curves, ribbons, S-shapes | Boxes, cylinders, enclosures (rounded via BOSL2) |
| Complex outlines, blobs, puddles | Boolean operations (difference, union, diff/tag) |
| Detailed grids with many bars | Parametric mechanical parts |
| Bezier curves, smooth paths | Rotate_extrude shapes (torus, etc.) |
| Text or logo silhouettes | Screw threads, gears (BOSL2 screws/threading/gears) |

### The Pipeline

```
Python generates SVG  -->  OpenSCAD imports SVG  -->  linear_extrude to 3D  -->  render/export
  (sub-second)              import("file.svg")       height = thickness         .png / .stl
```

### Python SVG Generation Pattern

Use filled shapes only -- OpenSCAD 2021 only imports filled SVG elements (not strokes). Convert all strokes to filled rectangles or paths.

```python
import math

def svg_header(width, height):
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg"
     width="{width}mm" height="{height}mm"
     viewBox="0 0 {width} {height}">
'''

def svg_footer():
    return '</svg>\n'

# Bars as filled rectangles (NOT strokes)
def hbar(x1, y, x2, w=1.3):
    r = w / 2
    return f'  <rect x="{min(x1,x2):.3f}" y="{y-r:.3f}" width="{abs(x2-x1):.3f}" height="{w:.3f}" rx="{r:.3f}" fill="black"/>\n'

def vbar(x, y1, y2, w=1.3):
    r = w / 2
    return f'  <rect x="{x-r:.3f}" y="{min(y1,y2):.3f}" width="{w:.3f}" height="{abs(y2-y1):.3f}" rx="{r:.3f}" fill="black"/>\n'

# Organic shapes as bezier paths
def blob(cx, cy, r):
    d = (f"M {cx},{cy-r} "
         f"C {cx+r*1.2},{cy-r} {cx+r*1.2},{cy+r} {cx},{cy+r} "
         f"C {cx-r*1.2},{cy+r} {cx-r*1.2},{cy-r} {cx},{cy-r} Z")
    return f'  <path d="{d}" fill="black"/>\n'

# Ring (donut) using even-odd fill rule
def ring(cx, cy, outer_r, tube_r):
    inner_r = outer_r - tube_r
    outer_r2 = outer_r + tube_r
    d = (f"M {cx-outer_r2:.3f},{cy:.3f} "
         f"A {outer_r2:.3f},{outer_r2:.3f} 0 1,0 {cx+outer_r2:.3f},{cy:.3f} "
         f"A {outer_r2:.3f},{outer_r2:.3f} 0 1,0 {cx-outer_r2:.3f},{cy:.3f} Z "
         f"M {cx-inner_r:.3f},{cy:.3f} "
         f"A {inner_r:.3f},{inner_r:.3f} 0 1,1 {cx+inner_r:.3f},{cy:.3f} "
         f"A {inner_r:.3f},{inner_r:.3f} 0 1,1 {cx-inner_r:.3f},{cy:.3f} Z")
    return f'  <path d="{d}" fill="black" fill-rule="evenodd"/>\n'
```

A full template script is available at `.claude/skills/openscad/scripts/generate-svg-template.py`.

### OpenSCAD Import Pattern

```openscad
// Import SVG and extrude to 3D
// rotate([90,0,0]) flips the SVG from XY-plane to XZ-plane (standing up)
rotate([90, 0, 0])
    linear_extrude(height = 1.5)
        import("layer_grid.svg");

// Different layers can have different thicknesses for 3D depth effect
rotate([90, 0, 0])
    linear_extrude(height = 2.5)
        import("layer_ribbon.svg");

rotate([90, 0, 0])
    linear_extrude(height = 3.0)
        import("layer_blob.svg");
```

### Multi-Layer SVG Strategy

For 3D depth, split the design into separate SVG files per layer:

1. **Background layer** (thin, e.g. 1.5mm): Grid bars, structural elements
2. **Mid layer** (medium, e.g. 2.5mm): Ribbons, flowing shapes
3. **Foreground layer** (thick, e.g. 3.0mm): Accent blobs, cubes, focal elements

Each layer is a separate SVG, imported and extruded at different heights, then combined with `union()`.

### Key Gotchas

- **Filled shapes only**: OpenSCAD 2021 ignores `stroke` -- use `fill="black"` on all elements
- **Coordinate system**: SVG Y-axis points down; use `rotate([90,0,0])` in OpenSCAD to stand the shape up
- **Units**: Set SVG `width`/`height` in mm and matching `viewBox` for correct scale
- **Even-odd fill rule**: Use `fill-rule="evenodd"` for donut/ring shapes (hole inside a shape)
- **Performance**: A complex SVG with 300+ path points imports in under 1 second vs 2+ minutes for equivalent hull/sphere chains

## Blender Python Workflow (Recommended for Complex 3D Shapes)

For complex organic, sculptural, or jewelry-like 3D models (swept ribbons, metaball blobs, curved tubes, rounded forms), use Blender's headless Python scripting instead of OpenSCAD or SVG. This approach produces **true 3D geometry** (not extruded 2D) and exports STL in milliseconds.

### When to Use Blender vs OpenSCAD vs SVG

| Use Blender Python | Use OpenSCAD | Use SVG + linear_extrude |
|--------------------|--------------|--------------------------|
| Organic/jewelry shapes (pendants, sculptures) | Simple mechanical parts (boxes, gears, brackets) | Flat 2D outlines extruded to 3D |
| Swept curves & ribbons (tube along 3D path) | Boolean operations on primitives | Logo/text silhouettes |
| Metaballs (blobby, melting, dripping forms) | Parametric mechanical assemblies | Grid patterns, bar layouts |
| Rounded cubes via subdivision surface | Screw threads, snap-fit joints | Bezier outlines (2D only) |
| Torus/ring shapes with fine control | Quick single-primitive prototypes | When only a flat profile matters |
| Any shape requiring true 3D swept cross-sections | rotate_extrude shapes | When OpenSCAD import is the final step |

### Why Blender is Superior for Complex Shapes

- **True mesh tube ribbons**: Sweep an elliptical cross-section along any 3D parametric path, producing real tubular geometry. OpenSCAD requires chaining hundreds of `hull(sphere(), sphere())` pairs (slow, faceted).
- **Metaballs**: Define overlapping spheres/ellipsoids that automatically merge into smooth organic blobs. No equivalent in OpenSCAD.
- **Curves with bevel**: A single `bpy.data.curves.new()` with `bevel_depth` creates a perfect cylindrical bar between two points. Replaces `hull() { sphere(); sphere(); }`.
- **Subdivision surfaces**: Add a `SUBSURF` modifier to any mesh for instant smooth rounding. Replaces `minkowski() { cube(); sphere(); }` (which is extremely slow).
- **Performance**: STL export takes ~2ms vs minutes in OpenSCAD for complex geometry. No `$fn`-related slowdowns.
- **Full Python math**: Use `math`, `numpy`, `mathutils.Vector` for parametric generation with no language limitations.

### The Blender Pipeline

```
Python script  -->  blender --background --python script.py  -->  STL file
  (parametric)         (headless, no GUI needed)                  (instant export)
```

For preview rendering, import the STL back into OpenSCAD:

```
STL file  -->  OpenSCAD: import("model.stl");  -->  render-scad.sh  -->  PNG
```

This gives consistent preview rendering through the existing OpenSCAD pipeline while using Blender for the actual geometry generation.

### Blender Detection (Cross-Platform)

```bash
# Try common locations
if command -v blender &>/dev/null; then
    BLENDER=blender
elif [ -x "/Applications/Blender.app/Contents/MacOS/Blender" ]; then
    BLENDER="/Applications/Blender.app/Contents/MacOS/Blender"
elif [ -x "C:/Program Files/Blender Foundation/Blender 4.3/blender.exe" ]; then
    BLENDER="C:/Program Files/Blender Foundation/Blender 4.3/blender.exe"
elif [ -x "C:/Program Files/Blender Foundation/Blender 4.2/blender.exe" ]; then
    BLENDER="C:/Program Files/Blender Foundation/Blender 4.2/blender.exe"
fi

# Run headless
"$BLENDER" --background --python script.py
```

### Key Blender Python Patterns

#### Cylindrical Bar via Curve + Bevel

```python
def create_bar(p1, p2, radius=0.65, name="bar"):
    """Create a cylindrical bar between two 3D points."""
    curve_data = bpy.data.curves.new(name=name, type='CURVE')
    curve_data.dimensions = '3D'
    curve_data.resolution_u = 8
    curve_data.bevel_depth = radius
    curve_data.bevel_resolution = 4
    curve_data.use_fill_caps = True

    spline = curve_data.splines.new('POLY')
    spline.points.add(1)  # Already has 1 point, add 1 more
    spline.points[0].co = (*p1, 1)
    spline.points[1].co = (*p2, 1)

    obj = bpy.data.objects.new(name, curve_data)
    bpy.context.collection.objects.link(obj)
    return obj
```

#### Mesh Tube Along Arbitrary 3D Path

```python
def create_tube_along_path(points, radius=1.0, n_ring=12):
    """Sweep a circular cross-section along a list of 3D points."""
    from mathutils import Vector
    verts = []
    faces = []
    for i, center in enumerate(points):
        center = Vector(center)
        # Compute tangent from adjacent points
        if i < len(points) - 1:
            tangent = Vector(points[i + 1]) - center
        else:
            tangent = center - Vector(points[i - 1])
        tangent.normalize()
        # Frenet frame
        up = Vector((0, 0, 1)) if abs(tangent.z) < 0.99 else Vector((1, 0, 0))
        normal = tangent.cross(up).normalized()
        binormal = tangent.cross(normal).normalized()
        # Ring of vertices
        for k in range(n_ring):
            a = 2 * math.pi * k / n_ring
            offset = normal * (radius * math.cos(a)) + binormal * (radius * math.sin(a))
            verts.append(center + offset)
    # Faces connecting adjacent rings
    for i in range(len(points) - 1):
        for k in range(n_ring):
            k_next = (k + 1) % n_ring
            v0 = i * n_ring + k
            v1 = i * n_ring + k_next
            v2 = (i + 1) * n_ring + k_next
            v3 = (i + 1) * n_ring + k
            faces.append((v0, v1, v2, v3))
    mesh = bpy.data.meshes.new("tube_mesh")
    mesh.from_pydata([(v.x, v.y, v.z) for v in verts], [], faces)
    mesh.update()
    obj = bpy.data.objects.new("tube", mesh)
    bpy.context.collection.objects.link(obj)
    return obj
```

#### Metaball Organic Blob

```python
def create_metaball_blob(elements, resolution=0.3, threshold=0.6):
    """Create organic blobby shape from metaball elements.
    Each element: {'pos': (x,y,z), 'radius': float, 'type': 'BALL'|'ELLIPSOID',
                   'size': (sx,sy,sz) (optional, for ELLIPSOID)}
    """
    mball = bpy.data.metaballs.new("blob")
    mball.resolution = resolution
    mball.render_resolution = resolution / 2
    mball.threshold = threshold
    for spec in elements:
        elem = mball.elements.new()
        elem.co = spec['pos']
        elem.radius = spec['radius']
        elem.type = spec.get('type', 'BALL')
        if elem.type == 'ELLIPSOID' and 'size' in spec:
            elem.size_x, elem.size_y, elem.size_z = spec['size']
    obj = bpy.data.objects.new("blob", mball)
    bpy.context.collection.objects.link(obj)
    return obj
```

#### Torus / Loop

```python
bpy.ops.mesh.primitive_torus_add(
    location=(x, y, z),
    major_radius=2.5,    # ring radius
    minor_radius=0.7,    # tube radius
    major_segments=32,
    minor_segments=12,
)
```

#### Rounded Cube via Subdivision Surface

```python
bpy.ops.mesh.primitive_cube_add(size=1, location=(x, y, z), scale=(w, d, h))
cube = bpy.context.active_object
subsurf = cube.modifiers.new(name="Subsurf", type='SUBSURF')
subsurf.levels = 2
subsurf.render_levels = 2
```

#### Convert and Join All Objects

```python
def convert_and_join():
    """Convert all curves/metaballs to meshes, then join into one object."""
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = bpy.context.selected_objects[0]
    bpy.ops.object.convert(target='MESH')
    bpy.ops.object.join()
    return bpy.context.active_object
```

#### Export STL

```python
def export_stl(filepath):
    bpy.ops.wm.stl_export(
        filepath=filepath,
        export_selected_objects=False,
        ascii_format=False,
    )
```

### Blender Workflow File Naming

Follow the same versioning convention:

```
<model-name>_blender_<version>.py   ->  <model-name>_blender_<version>.stl
                                    ->  <model-name>_blender_<version>.png (via OpenSCAD import)
```

### Preview via OpenSCAD Import

After generating the STL with Blender, create a minimal `.scad` file to preview it:

```openscad
// Auto-generated preview wrapper
import("model_blender_001.stl");
```

Then render with the standard pipeline:

```bash
.claude/skills/preview-scad/scripts/render-scad.sh preview_wrapper.scad --output model_blender_001.png
```

### Template Script

A reusable Blender Python template with all core functions is available at `.claude/skills/openscad/scripts/blender-template.py`.

### Key Gotchas

- **Headless mode required**: Always use `blender --background --python script.py`. Never rely on GUI.
- **Context matters**: Some `bpy.ops` calls require an active object. Always `select_all()` and set `view_layer.objects.active` before `convert()` or `join()`.
- **Metaball resolution**: Lower `mball.resolution` = finer mesh (more polys). 0.3 is good for preview, 0.15 for final export.
- **Spline point format**: Poly spline points need 4D coordinates `(*xyz, 1)` where the 4th value is the weight.
- **Cap curves**: Set `curve_data.use_fill_caps = True` to close the ends of beveled curves.
- **STL export API**: Use `bpy.ops.wm.stl_export()` (Blender 4.x). Older versions use `bpy.ops.export_mesh.stl()`.
- **No orphan data**: Clean up unused meshes/curves after operations to keep memory usage low.

## Tips

- Start simple and add complexity in iterations
- Use meaningful model names that describe the object
- Keep each version's changes focused on specific improvements
- Document what changed between versions in your response to the user
- Only export to STL once the multi-view rubric critique passes; pass `--expect-size` so the bbox gate has teeth
- For reference matching: iterate at least 5-8 times, comparing each render carefully
- For complex organic shapes, prefer the Blender Python workflow; for flat 2D-to-3D shapes, use the SVG workflow; for mechanical/functional parts, use OpenSCAD + BOSL2