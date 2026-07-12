# build123d Cheat-Sheet (read before writing any build123d code)

Runs in `~/.venv-cad3d` (Python 3.12). All units are **mm**. Two styles exist; **algebra mode** (plain expressions) is the default here — it's explicit and easy to debug. Builder mode (`with BuildPart()`) is shown where it's genuinely nicer (hole helpers).

```python
from build123d import *
```

## Primitives (algebra mode — all centered at origin by default)

```python
Box(30, 20, 10)
Cylinder(radius=5, height=20)
Cone(bottom_radius=8, top_radius=3, height=15)
Sphere(radius=10)
Torus(major_radius=15, minor_radius=3)

# align: sit on the XY plane instead of centered
Box(30, 20, 10, align=(Align.CENTER, Align.CENTER, Align.MIN))
```

## Placement and booleans

```python
part = Box(30, 20, 10)
part = part + Pos(0, 0, 5) * Cylinder(4, 10)        # union
part = part - Pos(10, 0, 0) * Cylinder(2, 20)        # difference
part = part & Sphere(14)                              # intersection
part = Rot(0, 0, 45) * part                           # rotate (degrees, XYZ)
part = Plane.XZ * part                                # reorient onto a plane
```

## Selectors — how you pick edges/faces for fillets and features

```python
part.edges()                                  # all edges (ShapeList)
part.edges().filter_by(Axis.Z)                # edges parallel to Z (vertical edges)
part.edges().filter_by(GeomType.CIRCLE)       # circular edges
part.edges().group_by(Axis.Z)[0]              # lowest group (bottom edges)
part.edges().group_by(Axis.Z)[-1]             # highest group (top rim)
part.faces().sort_by(Axis.Z)[-1]              # topmost face
part.faces().filter_by(Plane.XY)              # faces parallel to XY
new_edges = part.edges() - old_edges          # edges created since a snapshot
```

Selectors return a `ShapeList`. An empty selection raises on fillet/chamfer — print `len(...)` when debugging.

## Fillet / chamfer / shell — the reasons to use build123d

```python
part = fillet(part.edges().filter_by(Axis.Z), radius=3)
part = chamfer(part.faces().sort_by(Axis.Z)[-1].edges(), length=0.6)

# Shell: hollow out, leaving wall thickness, with an open face
top = part.faces().sort_by(Axis.Z)[-1]
part = offset(part, amount=-2, openings=top)   # 2 mm wall, open top
```

Fillet radius must be smaller than adjacent face sizes — `StdFail_NotDone` / "failed to create fillet" means the radius doesn't fit; reduce it or fillet fewer edges at once.

## Sketch → 3D

```python
profile = Rectangle(30, 20) + Pos(15, 0) * Circle(10)   # 2D booleans work too
part = extrude(profile, amount=8)
part = revolve(Plane.XZ * Pos(10, 0) * Circle(4), Axis.Z)  # torus; profile on a plane through the axis, X >= 0
path = Line((0, 0, 0), (0, 0, 30)) + CenterArc((0, 15, 30), 15, 180, 90)
part = sweep(Circle(3), path=Wire(path.edges()))
part = loft([Plane.XY * Circle(15), Plane.XY.offset(20) * Rectangle(20, 20)])
slot = SlotOverall(20, 6)                                 # slot sketch: overall length 20, width 6
txt = Text("v2", font_size=8)                             # 2D text sketch, extrude it
```

## Holes — builder mode is cleanest

```python
with BuildPart() as bp:
    Box(40, 30, 8)
    fillet(bp.edges().filter_by(Axis.Z), 4)
    top = bp.faces().sort_by(Axis.Z)[-1]
    with Locations(top):                         # work on the top face
        with GridLocations(28, 18, 2, 2):        # 2x2 grid, 28 x 18 spacing
            CounterBoreHole(1.7, 3.1, 3)         # M3: pilot r, cbore r, cbore depth
    chamfer(bp.edges().group_by(Axis.Z)[-1], 0.6)
part = bp.part
```

Also: `Hole(radius, depth=None)` (through-all when depth omitted), `CounterSinkHole(radius, counter_sink_radius)`.
In builder mode, operations mutate the implicit context; get the result from `bp.part`.

## Export — always with explicit tolerance

```python
export_stl(part, "name_001.stl", tolerance=0.01, angular_tolerance=0.1)
print("bbox:", part.bounding_box())     # print this — compare against spec dims
export_step(part, "name_001.step")      # optional: exact B-rep for CAD handoff
```

`tolerance` = max deviation from the true surface in mm. 0.01 is production quality; no $fn anywhere.

## Gotchas

- Everything is **centered** by default — use `align=` or `Pos()` to sit parts on Z=0.
- Algebra operations return **new** objects; always reassign (`part = part + ...`).
- `fillet`/`chamfer` after big booleans can fail on tangent edges — apply them as early as the geometry allows, or fillet fewer edges per call.
- `offset()` (shell) needs the opening face(s) from the *current* shape — select the face right before the call.
- Degrees for `Rot`, radians only in `angular_tolerance`.
- Empty `ShapeList` from a selector = your filter matched nothing (wrong axis/group index). Inspect with `print(len(...))`.
- If an API question comes up, search local docs: `~/.venv-cad3d/bin/python .claude/skills/cad-docs/scripts/docsearch.py "query" --lib build123d`.

## Few-shot examples (compile-verified)

### 1. Enclosure base: shell, corner posts, pilot holes, rim chamfer (algebra mode)

```python
from build123d import *

# Datasheet dims: outer 56 x 36 x 14, wall 2, M3 pilots in posts
L, W, H, wall, rnd = 56, 36, 14, 2, 3

body = Box(L, W, H)
body = fillet(body.edges().filter_by(Axis.Z), rnd)
body = fillet(body.edges().group_by(Axis.Z)[0], 1.5)                    # soften bottom
part = offset(body, -wall, openings=body.faces().sort_by(Axis.Z)[-1])   # open-top shell

for x in (-21.5, 21.5):
    for y in (-11.5, 11.5):
        post = Pos(x, y, -H/2 + wall) * Cylinder(3.2, H - wall - 2,
                   align=(Align.CENTER, Align.CENTER, Align.MIN))
        hole = Pos(x, y, -H/2 + wall + 2) * Cylinder(1.4, H,
                   align=(Align.CENTER, Align.CENTER, Align.MIN))
        part = part + post - hole
part = chamfer(part.faces().sort_by(Axis.Z)[-1].edges(), 0.4)           # break rim edges

export_stl(part, "enclosure_001.stl", tolerance=0.01, angular_tolerance=0.1)
print("bbox:", part.bounding_box())
```

### 2. Mounting plate with counterbored screw grid (builder mode)

```python
from build123d import *

with BuildPart() as bp:
    Box(40, 30, 8)
    fillet(bp.edges().filter_by(Axis.Z), 4)
    top = bp.faces().sort_by(Axis.Z)[-1]
    with Locations(top):
        with GridLocations(28, 18, 2, 2):
            CounterBoreHole(1.7, 3.1, 3)      # M3 socket-head fits flush
    chamfer(bp.edges().group_by(Axis.Z)[-1], 0.6)

export_stl(bp.part, "plate_001.stl", tolerance=0.01, angular_tolerance=0.1)
print("bbox:", bp.part.bounding_box())
```
