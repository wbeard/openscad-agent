"""Stylized 'Clicker' bust on a pedestal — organic SDF build, v003.

v002 -> v003:
  - single larger face mass tucked directly under the canopy (no pinch gap)
  - mouth carved as a deep angled cavity (no floating rim ring)
  - thicker neck, beefier shoulders that keep their mass after blending
  - wider mushroom-crown head with a fuller brim; front grooves toned down

Layout (mm, Z up, front faces -Y):
  z 0..69    stepped stone plinth
  z 61..128  torso + shoulders + straps
  z 118..152 neck + face with open mouth
  z 145..196 fungal head canopy
"""

import math
import random

from sdf import *

rng = random.Random(42)

# ---------------------------------------------------------------- plinth
plinth = box((60, 60, 8)).translate((0, 0, 2))
plinth |= rounded_box((52, 52, 6), 1.5).translate((0, 0, 8.5))
plinth |= rounded_box((42, 42, 50), 1.5).translate((0, 0, 36))
plinth |= rounded_box((50, 50, 5), 1.5).translate((0, 0, 61.5))
plinth |= rounded_box((56, 56, 5), 1.2).translate((0, 0, 66.5))

# creeping tendrils hugging the shaft faces (shaft half-width 21)
tendrils = None
tendril_pts = [
    ((-14, -21.5, 8), (-5, -21.5, 38)),
    ((-5, -21.5, 38), (7, -21.5, 62)),
    ((7, -21.5, 62), (12, -25.5, 68)),
    ((14, -21.5, 10), (17, -21.5, 44)),
    ((21.5, -10, 10), (21.5, 5, 50)),
    ((21.5, 5, 50), (21.5, 14, 64)),
    ((-21.5, 12, 8), (-21.5, -4, 46)),
    ((-21.5, -4, 46), (-18, -10, 66)),
    ((-8, 21.5, 12), (4, 21.5, 58)),
]
for a, b in tendril_pts:
    t = capsule(a, b, 1.7)
    tendrils = t if tendrils is None else tendrils | t
plinth = plinth | tendrils.k(1.5)

# fungal growth shelf spilling off one plinth corner
shelf = ellipsoid((7, 5, 3.5)).translate((22, -18, 40))
shelf |= ellipsoid((5.5, 4.5, 3)).translate((20, -21, 33)).k(2.5)
plinth = plinth | shelf.k(2)

# ---------------------------------------------------------------- torso
torso = ellipsoid((27, 18, 32)).translate((0, 0, 92))
torso |= ellipsoid((23, 16, 18)).translate((0, 1, 116)).k(8)     # upper chest / traps
# collapsed chest ribs: shallow scoops that just graze the front surface
for z in (80, 87, 94, 101):
    rib = capsule((-13, -19.5, z), (13, -19.5, z), 2.6)
    torso = torso - rib.k(2)
# shoulders: big lumpy fungal masses, overhanging the plinth
for sx in (-1, 1):
    torso = torso | ellipsoid((15, 13, 12)).translate((sx * 29, 0, 112)).k(5)
    for i in range(7):
        r = rng.uniform(3.0, 5.5)
        ang = rng.uniform(0, 2 * math.pi)
        torso = torso | sphere(r).translate((
            sx * (29 + 10 * abs(math.cos(ang))),
            7 * math.sin(ang),
            112 + rng.uniform(-7, 8),
        )).k(2.2)

# tank-top straps lying on the torso surface
straps = None
for sx in (-1, 1):
    front = capsule((sx * 12, -14, 82), (sx * 16, -4, 122), 2.8)
    back = capsule((sx * 16, -4, 122), (sx * 12, 14, 82), 2.8)
    s = front | back
    straps = s if straps is None else straps | s
torso = torso | straps.k(1.2)

# melt the torso onto the plinth cap
bust = plinth | torso.k(4)

# ---------------------------------------------------------------- neck + face
neck = capped_cone((0, 2, 110), (0, -2, 140), 14, 10)
face = ellipsoid((11, 12, 14)).translate((0, -5, 146))
head_base = neck | face.k(5)
# deep angled mouth cavity low on the face
mouth = ellipsoid((6, 10, 6.5)).rotate(-0.5, X).translate((0, -15, 139))
head_base = head_base - mouth.k(1.4)

bust = bust | head_base.k(4)

# ---------------------------------------------------------------- fungal head
core = ellipsoid((18, 17, 15)).translate((0, 1, 168))
head = core
# wide brim ring flaring outward, fuller and lower at the front
for i in range(11):
    a = i / 11 * 2 * math.pi
    x = 23 * math.sin(a)
    y = -20 * math.cos(a) + 3          # i=0 lands at the front
    z = 166 + rng.uniform(-3, 3) - 4 * math.cos(a)   # front plates hang lower
    head = head | sphere(rng.uniform(8.5, 11)).translate((x, y, z)).k(3.2)
# front canopy lobes hooding right over the face
for x, y, z, r in ((-9, -16, 158, 8), (9, -16, 158, 8), (0, -19, 161, 8.5)):
    head = head | sphere(r).translate((x, y, z)).k(3.5)
# upper dome cluster
for i in range(18):
    a = rng.uniform(0, 2 * math.pi)
    rad = rng.uniform(2, 14)
    x = rad * math.cos(a)
    y = rad * math.sin(a) * 0.9 + 2
    z = 178 + rng.uniform(2, 12)
    head = head | sphere(rng.uniform(5.5, 8.5)).translate((x, y, z)).k(3)
# small nodules for fungal texture
for i in range(30):
    a = rng.uniform(0, 2 * math.pi)
    el = rng.uniform(-0.3, 1.2)
    x = 26 * math.cos(a) * math.cos(el)
    y = 23 * math.sin(a) * math.cos(el) + 2
    z = 170 + 18 * math.sin(el)
    head = head | sphere(rng.uniform(2.5, 4.5)).translate((x, y, z)).k(1.6)

# one subtle central cleft splitting the front plates
cleft = box((1.8, 14, 34)).rotate(0.15, X).translate((0, -25, 174))
head = head - cleft.k(1.5)

bust = bust | head.k(4)

# flat, crisp bottom for the print bed
f = bust & slab(z0=0)

f.save('clicker_bust/clicker_bust_003.stl', samples=2**22, verbose=False)
