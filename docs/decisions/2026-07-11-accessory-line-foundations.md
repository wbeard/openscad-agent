# 2026-07-11 — Mac mini accessory line: foundations

## Context

Kicked off a seven-product accessory line for the M4 Mac mini (letterboard, louver,
backlog counter, labyrinth, cable comb, monolith sleeve, chimney shelf), anchored on
the existing OpenClaw case. Before designing, every external dimension was verified
against published sources and teardown photogrammetry.

## Decisions

### 1. Repo layout: one folder per product
New products live in their own folder (`letterboard/`, `louver/`, `counter/`,
`labyrinth/`, `cable_comb/`, `monolith_sleeve/`, `chimney_shelf/`,
`openclaw_case/` for case v005+). The .scad, PNG renders, and STLs stay together.
`version-scad.sh` is run from inside the product folder. openclaw_case_001–004 and
other pre-existing files remain at the repo root.

### 2. Dimension corrections to openclaw_case_004 (carried into 005)
- **Front cutouts were wrong.** Real M4 front layout (Chargerlab teardown
  photogrammetry, scale anchored to a 127.11mm caliper shot, ±0.7mm): USB-C are
  VERTICAL pills ~2.7×9.0 at x=−39.2/−23.5 (both left of center), LED at +25.4,
  headphone jack (~4.2 aperture) at +38.2, centerline z=20.3 above desk. v004's
  horizontal 15×8 slots at ±10 (jack +32, LED −32) matched nothing real.
  v005 cutouts: pills 6×13, LED d5, jack d9, all z=20.3 (≥1.5mm slop).
- **Cavity corner radius bound.** Mini corner radius ≈22mm (sources range
  22–23.5); v004's rc_in=26 gives ~0.5mm interference on the corner diagonals.
  v005 uses rc_in=23.
- Chassis 127.1×127.1×49.7 confirmed (Apple + caliper). Airflow is BOTTOM-ONLY:
  intake at the front/central arcs of the base ring, exhaust at the rear arc.
  No rear-wall vents. Power button: bottom, left-rear corner viewed from front.
  Base foot ring outer d≈110, contact disc d≈100, shell edge 3.4mm above desk
  (photogrammetry ±1mm — foot-ring registration features stay `VERIFY on hardware`).

### 3. Faceplate interface v1 (contract in openclaw_case_005.scad)
Raised bezel frame 100×44 r11 on the case front (3mm embedded / 3mm proud) with a
90×36×3 recessed plate pocket (+0.4/side), 4× N35 6×2 magnets at plate-local
(±34, ±12.5), 20mm finger notch, 1.2mm rim chamfer, vent grid (8× 10×3 slots,
upper band) through the pocket floor that the louver plate meters and every other
plate seals. Every faceplate copies the interface param block verbatim (repo has no
include/use convention for parameters). Mechanisms stack OUTWARD (proud housings);
only 1.75mm of wall remains behind the case-side magnet pockets.

### 4. Magnet pockets are CLEARANCE fit, not interference
Pocket d6.15 for a d6.0±0.1 magnet (+0.15 nominal clearance). FDM holes print
undersize, so this yields a physical press fit; modeled interference cracks thin
walls. CA glue is the primary retention (magnet-to-magnet attraction pulls both
outward). Polarity convention: case magnets N-out, plate magnets S-out.
`fit_coupon` PART (pocket corner + d6.05/6.15/6.25 test pockets) prints first.

### 5. Monolith sleeve: no power brick, 40mm chase
The M4 mini has an internal PSU. The sleeve's gear deck carries parametric bays
sized from real hardware: hub 135×58×16, SSD 112×36×15. Cable chase depth 40mm
(molded C7 plug protrudes ~22–28mm, no published figure — measure Apple cord
923-11979; a right-angle C7 cord allows 24).

### 6. Bottom-only airflow drives both thermal products
Monolith: transverse baffle under the mini at ~60% depth splits the plinth plenum
(front intake scallops / rear exhaust into chase → low rear louvers). Chimney
shelf: both minis sit on split-plenum standoffs; rear arcs duct into a 110×16
flue (1760mm²); front/sides stay open as the cool path. Stack draft is only a few
Pa — the honest win is low-resistance blower discharge + exhaust/intake
separation; thermocouple channels (T1 hot / T2 cool) let us publish delta-T.

### 7. Faceplate mounting chirality (bug found in review, fixed in contract)
A plate modeled with its cosmetic face at z=0 (face-down print) mounts with
plate-local +x mapping to case −x (proper rotation: face normal −z→−y, up
+y→+z forces x→−x). Consequence: plate-local pass-through x-coordinates are
the NEGATION of case port positions, and asymmetric face art/text must be
mirrored in model space. `plate_passthroughs()` in openclaw_case_005.scad is
wrapped in `mirror([1,0,0])` and the contract comment documents the rule.
(Found by the letterboard build agent; the assembly render had masked it
because the seated preview plate was built directly in case coords.)

### 8. Tooling learnings (this OpenSCAD build + updated skill scripts)
- Include-override is LAST-assignment-wins in this OpenSCAD build: `PART="x"`
  placed BEFORE `include <file.scad>` gets overwritten (warning), but placed
  AFTER the include it works. Alternatives: `openscad -D 'PART="x"'` for
  renders; for STL export, temporarily sed the PART default, run
  `export-stl.sh`, restore.
- `render-scad.sh` gained `--views std` (iso/front/right/top). It always passes
  `--viewall --autocenter`, so custom cameras control angle, not framing.
- `export-stl.sh` now runs trimesh + prusa-slicer validation gates (needed
  `pip install --user scipy`). Multi-body plates (tile sets, accessories,
  captive print-in-place mechanisms) need `--allow-multi-part`.
- `generate-svg-template.py` referenced by the openscad skill is an empty file.

## Follow-ups
- Caliper-verify on real hardware before printing: front port positions, corner
  radius, foot-ring diameter, C7 plug protrusion.
- Consider back-porting the v005 front-cutout/corner fixes to a v004 patch note.
