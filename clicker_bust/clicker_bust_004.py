"""Stylized 'Clicker' bust on a pedestal — organic SDF build, v004.

v003 -> v004:
  - face moved forward/down with a chin bump under the mouth (mouth reads as a
    gaping jaw instead of a donut hole in the neck)
  - canopy underside lobes swallow the top of the face
  - strap ends buried inside the torso (no protruding nubs)
  - ribs shorter/shallower + vertical sternum groove; brim lobes less smoothed

Layout (mm, Z up, front faces -Y):
  z 0..69    stepped stone plinth
  z 61..128  torso + shoulders + straps
  z 118..156 neck + face with open mouth
  z 150..198 fungal head canopy
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
# vertical sternum groove
sternum = capsule((0, -19, 78), (0, -20, 112), 1.8)
torso = torso - sternum.k(1.5)
# collapsed chest ribs: short shallow scoops angled down toward the sternum
for z in (84, 91, 98, 105):
    for sx in (-1, 1):
        rib = capsule((sx * 4, -19.5, z - 1), (sx * 13, -18.5, z + 2), 1.9)
        torso = torso - rib.k(1.3)
# shoulders: big lumpy fungal arm-stubs
for sx in (-1, 1):
    torso = torso | ellipsoid((14, 13, 13)).translate((sx * 28, 0, 110)).k(5)
    for i in range(7):
        r = rng.uniform(3.0, 5.5)
        ang = rng.uniform(0, 2 * math.pi)
        torso = torso | sphere(r).translate((
            sx * (28 + 9 * abs(math.cos(ang))),
            7 * math.sin(ang),
            110 + rng.uniform(-7, 8),
        )).k(2.2)

# tank-top straps lying on the torso surface, ends buried in the chest mass
straps = None
for sx in (-1, 1):
    front = capsule((sx * 11, -9, 76), (sx * 16, -4, 122), 2.8)
    back = capsule((sx * 16, -4, 122), (sx * 11, 9, 76), 2.8)
    s = front | back
    straps = s if straps is None else straps | s
torso = torso | straps.k(1.2)

# melt the torso onto the plinth cap
bust = plinth | torso.k(4)

# ---------------------------------------------------------------- neck + face
neck = capped_cone((0, 2, 110), (0, -3, 142), 14, 10.5)
face = ellipsoid((10.5, 11, 13)).translate((0, -8, 148))
chin = ellipsoid((7, 6.5, 5.5)).translate((0, -13, 137))
head_base = neck | face.k(4.5) | chin.k(2.5)
# gaping jaw carved between chin and canopy
mouth = ellipsoid((5.5, 9, 5.5)).rotate(-0.55, X).translate((0, -16.5, 145))
head_base = head_base - mouth.k(1.3)

bust = bust | head_base.k(4)

# ---------------------------------------------------------------- fungal head
core = ellipsoid((18, 17, 15)).translate((0, 1, 170))
head = core
# wide brim ring flaring outward, fuller and lower at the front
for i in range(11):
    a = i / 11 * 2 * math.pi
    x = 23 * math.sin(a)
    y = -20 * math.cos(a) + 3          # i=0 lands at the front
    z = 168 + rng.uniform(-3, 3) - 4 * math.cos(a)
    head = head | sphere(rng.uniform(8.5, 11)).translate((x, y, z)).k(2.6)
# underside lobes swallowing the top of the face
for x, y, z, r in ((-9, -14, 158, 7.5), (9, -14, 158, 7.5),
                   (0, -17, 160, 8), (-5, -19, 165, 6.5), (5, -19, 165, 6.5)):
    head = head | sphere(r).translate((x, y, z)).k(3)
# upper dome cluster
for i in range(18):
    a = rng.uniform(0, 2 * math.pi)
    rad = rng.uniform(2, 14)
    x = rad * math.cos(a)
    y = rad * math.sin(a) * 0.9 + 2
    z = 180 + rng.uniform(2, 12)
    head = head | sphere(rng.uniform(5.5, 8.5)).translate((x, y, z)).k(2.8)
# small nodules for fungal texture
for i in range(36):
    a = rng.uniform(0, 2 * math.pi)
    el = rng.uniform(-0.3, 1.2)
    x = 26 * math.cos(a) * math.cos(el)
    y = 23 * math.sin(a) * math.cos(el) + 2
    z = 172 + 18 * math.sin(el)
    head = head | sphere(rng.uniform(2.8, 5)).translate((x, y, z)).k(1.5)

# one subtle central cleft splitting the front plates
cleft = box((1.8, 12, 30)).rotate(0.15, X).translate((0, -26, 178))
head = head - cleft.k(1.5)

bust = bust | head.k(3.5)

# flat, crisp bottom for the print bed
f = bust & slab(z0=0)

f.save('clicker_bust/clicker_bust_004.stl', samples=2**22, verbose=False)
