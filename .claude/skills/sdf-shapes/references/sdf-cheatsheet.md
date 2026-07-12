# fogleman/sdf Cheat-Sheet (read before writing any sdf code)

Runs in `~/.venv-cad3d`. Treat units as **mm**. Everything is a function `f(points) -> distances`; compose with operators, mesh with `.save()`.

```python
from sdf import *
```

## 3D primitives (centered at origin unless noted)

```python
sphere(10)                          # radius
box(20)  /  box((30, 20, 10))       # cube / box by size
rounded_box((30, 20, 10), 3)        # box with radius-3 edges
torus(15, 3)                        # major, minor radius
capsule(-Z*20, Z*20, 5)             # line segment with radius (great limb builder)
capped_cylinder(-Z*10, Z*10, 8)     # finite cylinder between two points
capped_cone(-Z*10, Z*10, 8, 3)      # radius a at first point, b at second
ellipsoid((15, 10, 8))
plane(Z)                            # half-space; plane(Z, (0,0,5)) offsets it
slab(z0=-10, z1=10)                 # intersection helper: slab(x0=,x1=,y0=,y1=,z0=,z1=)
```

`X`, `Y`, `Z` are unit vectors: `-Z*20` = `(0,0,-20)`.

## Booleans — smooth blending is the whole point

```python
f = a | b            # union
f = a - b            # difference
f = a & b            # intersection
f = a | b.k(4)       # smooth union, 4 mm blend radius
f = a - b.k(4)       # smooth subtraction (rounded pocket edges)
f = a & b.k(4)       # smooth intersection
f = a.blend(b, k=0.5)  # weighted blend between two shapes
```

`.k(v)` attaches the smoothing amount (absolute distance) to the *operand*.

## Transforms and deformations

```python
f.translate((x, y, z))
f.scale(2)  /  f.scale((1, 2, 1))       # non-uniform scale distorts distances slightly
f.rotate(pi/4)  /  f.rotate(pi/4, X)    # radians, about Z by default
f.orient(X)                              # point the shape's Z axis along X
f.shell(2)                               # hollow shell, 2 mm wall (both sides of surface)
f.elongate((0, 0, 10))                   # stretch the middle
f.twist(0.02)                            # radians per mm along Z
f.bend(0.02)                             # bend in XY
f.bend_linear(-Z*30, Z*30, X*4)          # gradual bend between two points
f.repeat(30, padding=...) / f.circular_array(8, 20)   # patterns
f.dilate(1) / f.erode(1)                 # grow / shrink by distance
```

## 2D → 3D

```python
f2 = rectangle((20, 10)) | circle(8).translate((15, 0)).k(3)
f = f2.extrude(10)                # straight extrude
f = f2.extrude_to(circle(5), 20)  # loft-like transition between two 2D shapes
f = f2.revolve()                  # 2D X-offset becomes radius
t = text('Arial.ttf', 'Hello')    # 2D text sdf (font first!); extrude it
```

## Meshing / export

```python
f.save('name_001.stl', samples=2**22, verbose=False)   # ALWAYS verbose=False (progress bar floods output)
f.save('name_001.stl', step=0.15, verbose=False)       # or fix cell size in mm
```

- `samples=2**22` default; `2**24` for final detailed exports
- Bounds are estimated automatically; a shape that reaches infinity (raw `plane`, `cylinder`) must be intersected with something finite (`slab`, `box`) before saving

## Gotchas

- Raw `plane()`/`cylinder()`/`slab()` are infinite — always `&` them with a finite shape
- `.k()` smoothing is absolute mm — a `k` bigger than the feature erases it
- Thin walls below ~2× the cell size vanish or perforate at meshing — raise `samples`/lower `step` before debugging geometry
- `scale()` with non-uniform factors bends distances; deformations after it (shell, k-blends) may be slightly off — apply non-uniform scale last if possible
- Empty mesh (0 triangles) = no interior volume: check for over-subtraction or non-overlapping `&`
- Output can still fail validation gates occasionally — that's why we always run `validate-stl.py`

## Few-shot examples (verified: watertight, gates passed)

### 1. Ergonomic grip — blended finger scallops

```python
from sdf import *

f = capsule(-Z*30, Z*30, 14)                       # core grip column
f = f.bend_linear(-Z*30, Z*30, X*4)                # slight ergonomic curve
for z in (-22, -7, 8, 23):                          # four finger scallops
    f = f - sphere(9).translate((16, 0, z)).k(4)   # smooth subtraction
f = f & slab(z0=-35, z1=35)                        # flat top/bottom
f.save('grip_001.stl', samples=2**22, verbose=False)
```

### 2. Twisted vase — shell + open top + blended base

```python
from sdf import *

f = rounded_box((45, 45, 100), 12).twist(0.02)     # soft square, gentle twist
f = f.shell(2.4)                                    # 2.4 mm wall
f = f & slab(z1=48)                                 # cut the top open
f = f | rounded_box((42, 42, 3), 8).translate((0, 0, -47.5)).k(2)  # solid base, blended in
f.save('vase_001.stl', samples=2**22, verbose=False)
```
