# BOSL2 Cheat-Sheet (read before writing any BOSL2 code)

BOSL2 is installed at `~/Documents/OpenSCAD/libraries/BOSL2`. Start every file with:

```openscad
include <BOSL2/std.scad>   // include, NOT use — BOSL2 requires include
$fa = 1; $fs = 0.4;        // quality defaults (see skill guidance)
```

Specialized modules are NOT in std.scad — include them separately when needed:
`include <BOSL2/screws.scad>`, `<BOSL2/threading.scad>`, `<BOSL2/gears.scad>`,
`<BOSL2/rounding.scad>`, `<BOSL2/hinges.scad>`, `<BOSL2/joiners.scad>`.

## Core 3D shapes (all support anchor/spin/orient, rounding/chamfer)

```openscad
cuboid([30,20,10]);                              // centered cube
cuboid([30,20,10], rounding=2);                  // all edges rounded
cuboid([30,20,10], rounding=2, except=BOT);      // rounded except bottom edges
cuboid([30,20,10], chamfer=1, edges=TOP);        // chamfer only top edges
cyl(h=20, d=10);                                 // centered cylinder (unlike cylinder())
cyl(h=20, d=10, rounding=2);                     // rounded ends
cyl(h=20, d1=10, d2=6, chamfer2=1);              // cone, chamfered top
tube(h=20, od=20, id=16);                        // hollow cylinder (or wall=2)
prismoid(size1=[40,40], size2=[20,20], h=15, rounding=3);  // tapered box, sits on Z=0
spheroid(d=20, style="icosa");                   // better triangulation than sphere()
```

## Anchoring — position parts without coordinate math

Anchor constants: `TOP BOT LEFT RIGHT FWD BACK CENTER`, combinable: `TOP+RIGHT`, `BOT+FWD+LEFT`.

```openscad
cuboid([30,20,10], anchor=BOT);        // sit on the Z=0 plate (bottom at origin)

// position(): put child at a point on the parent (child keeps its orientation)
cuboid([30,20,10]) position(TOP+RIGHT) cyl(d=4, h=8, anchor=BOT);

// attach(): stick child's face onto parent's face (reorients the child)
cuboid([30,20,10]) attach(RIGHT, BOT) cyl(d=8, h=12);   // cylinder grows out of the right face
```

## Boolean operations with tags — the idiomatic difference()

```openscad
diff()
cuboid([40,30,15], rounding=3, except=BOT) {
    // subtracted children get tag("remove")
    tag("remove") attach(TOP, TOP, inside=true, shiftout=0.01)
        cuboid([36,26,13], rounding=2);          // hollow out a box
    tag("remove") position(RIGHT) xcyl(d=8, h=10);  // side hole
    // tag("keep") protects geometry from removal
}
```

`shiftout=0.01` avoids coincident faces (z-fighting / non-manifold results).

## Distributors — repeat children

```openscad
xcopies(spacing=10, n=5) cyl(d=3, h=10);            // row along X
grid_copies(spacing=[20,15], n=[3,2]) cyl(d=3, h=5); // grid
zrot_copies(n=6, r=20) cuboid([5,5,10]);             // polar array
mirror_copy(LEFT) wedge([10,10,10]);                 // original + mirrored
```

## Screws and threads

```openscad
include <BOSL2/screws.scad>
diff()
cuboid([30,30,8], rounding=2, except=BOT)
    tag("remove") position(TOP) screw_hole("M3", head="socket", counterbore=3,
                                           length=10, anchor=TOP);

include <BOSL2/threading.scad>
threaded_rod(d=8, l=20, pitch=1.25, $slop=0.2);   // metric-style thread
threaded_nut(nutwidth=13, id=8, h=6.5, pitch=1.25, $slop=0.2);
```

`$slop = 0.2` is a good FDM printer clearance for mating threads/joints.

## 2D + extrusion

```openscad
rect([30,20], rounding=4);                        // rounded rectangle
linear_sweep(rect([30,20], rounding=4), h=10);    // attachable extrusion
offset_sweep(rect([30,20], rounding=4), height=10,
             bottom=os_circle(r=2), top=os_circle(r=2));  // rounded top AND bottom edges
             // offset_sweep needs include <BOSL2/rounding.scad>
text3d("v2", h=1, size=8, font="Helvetica:style=Bold", anchor=BOT);
```

## Gotchas

- `include`, never `use` — BOSL2 depends on global state.
- `cuboid`/`cyl` are **centered** by default (unlike `cube`/`cylinder`); use `anchor=BOT` to sit on the bed.
- `rounding` must be ≤ half the smallest dimension of the affected edges, or you get an assertion error — the error message tells you the limit.
- `diff()` applies to its **one** child and that child's tagged descendants; wrap multiple parts in a single parent or `union()`.
- Subtracted shapes must protrude past the surface (`shiftout`, or make them longer) to avoid coincident-face artifacts.
- BOSL2 honors `$fa/$fs/$fn` — set `$fn` per-feature only (e.g. `cyl(d=3, h=10, $fn=32)` on tiny holes), keep `$fa=1; $fs=0.4;` global.
- BOSL2 asserts loudly on bad arguments — read the assert message, it names the exact parameter and constraint.

## Few-shot examples (idiomatic BOSL2)

### 1. Electronics enclosure base with corner screw posts

```openscad
include <BOSL2/std.scad>
$fa = 1; $fs = 0.4;

// Datasheet dims: PCB 50 x 30 mm, mount holes inset 3.5 mm, M2 screws
pcb = [50, 30];  wall = 2;  ih = 12;  inset = 3.5;  clearance = 1;
inner = [pcb.x + 2*clearance, pcb.y + 2*clearance];

diff()
cuboid([inner.x + 2*wall, inner.y + 2*wall, ih + wall],
       rounding=2, except=TOP, anchor=BOT) {
    tag("remove") attach(TOP, TOP, inside=true, shiftout=0.01)
        cuboid([inner.x, inner.y, ih], rounding=1, except=BOT);
    // screw posts survive the hollowing because they're added after diff's removal
    tag("keep") position(BOT+CENTER)
        grid_copies(spacing=[pcb.x - 2*inset, pcb.y - 2*inset], n=[2,2])
            up(wall) cyl(d=6, h=ih, anchor=BOT)
                tag("remove") attach(TOP, TOP, inside=true, shiftout=0.01)
                    cyl(d=1.8, h=8);   // M2 self-tap pilot
}
```

### 2. Wall hook, rounded, with countersunk mounting holes

```openscad
include <BOSL2/std.scad>
include <BOSL2/screws.scad>
$fa = 1; $fs = 0.4;

plate = [25, 60, 4];  hook_d = 10;  hook_reach = 25;

diff() {
    cuboid(plate, rounding=3, edges="Z", anchor=BOT) {
        tag("remove") position(TOP) ycopies(spacing=40, n=2)
            screw_hole("M4", head="flat", length=plate.z+0.02, anchor=TOP);
        // hook arm sweeps out of the plate face
        position(FWD+BOT) up(plate.z/2)
            cyl(d=hook_d, h=hook_reach, orient=FWD, anchor=BOT, rounding2=hook_d/2-0.01);
    }
}
```

### 3. Knurled thumb knob on a threaded insert

```openscad
include <BOSL2/std.scad>
include <BOSL2/threading.scad>
$fa = 1; $fs = 0.4;

diff()
cyl(d=24, h=10, rounding=2, texture="diamonds", tex_size=[3,3], anchor=BOT)
    tag("remove") attach(TOP, TOP, inside=true, shiftout=0.01)
        threaded_rod(d=8, l=8.5, pitch=1.25, $slop=0.2, internal=true);
```
