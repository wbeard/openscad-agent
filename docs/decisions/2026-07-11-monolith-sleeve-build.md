# 2026-07-11 — Monolith sleeve: v001–v004 build

## Context

Built the monolith sleeve (friction-fit architectural shell for the M4 Mac mini)
in `monolith_sleeve/`, per the verified device facts in the foundations entry
(bottom-only airflow, base ring d≈110, power button bottom left-rear). Final:
`monolith_sleeve_004.scad`, 6 PARTs, five STLs all passing the export gates
with `--expect-size`.

## Decisions

### 1. No internal protrusion below the mini's top plane, ever
v001 put the deck ledge at z56–62 with the mini top at z60 — a hard 3mm
collision, invisible in renders because no part render shows the mini and the
ledge in contact. Fixed by making the ledge's 45° underchamfer tip land exactly
at the mini top plane (deck_gap 6, loft_h 6; out_z stays 100). Rule of thumb:
in a wrap-around sleeve, every ledge/tab between z(plinth) and z(mini top) is a
collision or an insertion blocker — check insertion PATHS, not just resting
positions.

### 2. Insertion sequencing drove the keying design
The mini can only enter the tube from BELOW (deck/cap ledges block the top).
That killed v001's side-wall key blocks (2.5mm proud at z0–10 — directly in
the mini's entry path). The chassis now keys with 8 prongs (z0–5) that enter
the two front side skirt-scallop pockets from below; asymmetric scallop
spacing + square rear vs r23 front chassis corners make the fit one-way.
Deviation from the spec's "4 corner notches", justified in the header.

### 3. Base-ring keep-clear: low stringers + piers, not relieved rails
Full-height rails with an annular relief (r49–61) over the base ring, plus
airflow arches, severed the rails into floating islands (relief cuts top,
arch cuts bottom → nothing left where they overlap). Replaced with: 2.5mm-tall
stringer grid (plenum air just flows over it) + six 9×9 piers rising to z10
only inside the contact disc (r<49) + the sealing baffle as the only
full-height member, notched where it crosses the ring band.

### 4. STL gate failures: exact coplanarity is the enemy
- Chassis "43 non-manifold edges": the spars' raw outer faces sat exactly on
  the footprint-intersection boundary (x=±63.85). Fix: draw members 0.4
  oversize and let the footprint intersection do ALL the cutting. Also avoid
  same-width stacked members (piers now 9 wide over 8-wide stringers) and
  cut faces coincident with member faces.
- Tray "3 disconnected parts": press-fit tabs placed at y=−55 floated — the
  plate edge at that y is the front corner ARC (starts y=−41.25), 4.7mm away.
  Tabs on offset-outline parts must sit on straight-edge regions only.
- trimesh non-manifold-edge midpoints (Counter over `edges_sorted`) located
  the bad geometry in one shot; guessing wasted a round.

### 5. Renders that "prove" function
`SHOW_SECTION=true` cuts the assembly at x=0 and is rendered with a camera on
the cut side (`--camera 0,20,50,70,0,250,400`); the default camera shows the
intact half and proves nothing. The section view is what caught the plenum
stack reading correctly (scallops → front plenum → ring; rear arc → chase →
louvers) and the ledge/tray/cap seating.

### 6. Cap ledge is segmented because the tray must fall past it
A continuous cap ledge ring (3mm proud) would stop the 127.7-wide tray at
z90. The cap ledge in the mini zone is therefore two side tabs + two front
tabs with matching notches in the tray outline; it is continuous only around
the chase (y>66), where the tray never passes.

### 7. Skill-conformance pass (v004)
The reloaded openscad skill forbids a global `$fn`; v004 replaced `$fn=64`
with `$fa=1; $fs=0.4` (no dimensional change) and exports pin the bbox with
`--expect-size`. Include-override remains last-assignment-wins: view wrappers
put `PART=...` AFTER the include; STL export seds the PART default in place.

## Follow-ups
- Measure Apple cord 923-11979 (C7 protrusion): chase_d=40 is generous, a
  right-angle C7 allows 24 — shrink before printing if it clears.
- Print `PART="rib_coupon"` first: rib-face-to-rib-face is 127.15 vs the
  127.1 mini; real bite depends on FDM rib bulge.
- VERIFY on hardware: base contact disc coplanarity with the foot ring (piers
  assume the disc bears load), cove reach to the power button.
