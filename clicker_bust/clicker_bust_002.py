"""Stylized 'Clicker' bust on a pedestal — organic SDF build, v002.

v001 -> v002:
  - tendrils now hug the plinth shaft (+-21.5) and drape over the cap
  - torso widened, shoulders lowered/overhanging, straps embedded in the surface
  - fungal head enlarged and lumpier (smaller blend k so blobs read as growths)
  - face pushed forward with a visible open mouth under an overhanging canopy

Layout (mm, Z up, front faces -Y):
  z 0..69    stepped stone plinth
  z 61..125  torso + shoulders + straps
  z 120..148 neck + face with open mouth
  z 140..195 fungal head canopy
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
    ((7, -21.5, 62), (12, -25.5, 68)),      # drapes over the cap lip
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
torso |= ellipsoid((22, 16, 18)).translate((0, 1, 116)).k(8)     # upper chest / traps
# collapsed chest ribs: shallow scoops that just graze the front surface
for z in (80, 87, 94, 101):
    rib = capsule((-13, -19.5, z), (13, -19.5, z), 2.6)
    torso = torso - rib.k(2)
# shoulders: lumpy fungal masses, overhanging the plinth
for sx in (-1, 1):
    torso = torso | ellipsoid((13, 11, 14)).translate((sx * 27, 1, 108)).k(7)
    for i in range(7):
        r = rng.uniform(3.0, 5.0)
        ang = rng.uniform(0, 2 * math.pi)
        torso = torso | sphere(r).translate((
            sx * (27 + 9 * abs(math.cos(ang))),
            1 + 8 * math.sin(ang),
            108 + rng.uniform(-10, 10),
        )).k(2.2)

# tank-top straps lying on the torso surface (ends buried in the chest mass)
straps = None
for sx in (-1, 1):
    front = capsule((sx * 12, -13, 82), (sx * 15, -4, 120), 2.8)
    back = capsule((sx * 15, -4, 120), (sx * 12, 13, 82), 2.8)
    s = front | back
    straps = s if straps is None else straps | s
torso = torso | straps.k(1.2)

# melt the torso onto the plinth cap
bust = plinth | torso.k(4)

# ---------------------------------------------------------------- neck + face
neck = capped_cone((0, 2, 112), (0, -2, 142), 12, 8.5)
face = ellipsoid((10, 11, 12)).translate((0, -7, 144))
chin = ellipsoid((6.5, 6, 5)).translate((0, -11, 134))
head_base = neck | face.k(4) | chin.k(3)
# gaping mouth on the lower face
mouth = ellipsoid((6, 7, 7.5)).translate((0, -16, 138))
head_base = head_base - mouth.k(1.2)

bust = bust | head_base.k(3.5)

# ---------------------------------------------------------------- fungal head
core = ellipsoid((17, 16, 14)).translate((0, 1, 165))
head = core
# ring of large plates flaring outward (fuller at the front, overhanging the face)
for i in range(11):
    a = i / 11 * 2 * math.pi
    x = 21 * math.sin(a)
    y = -19 * math.cos(a) + 2          # i=0 lands at the front
    z = 166 + rng.uniform(-4, 3)
    head = head | sphere(rng.uniform(8, 11)).translate((x, y, z)).k(3.2)
# front canopy lobes hooding over the face
for x, y, z, r in ((-8, -17, 156, 7.5), (8, -17, 156, 7.5), (0, -20, 160, 8)):
    head = head | sphere(r).translate((x, y, z)).k(3)
# upper dome cluster
for i in range(18):
    a = rng.uniform(0, 2 * math.pi)
    rad = rng.uniform(2, 15)
    x = rad * math.cos(a)
    y = rad * math.sin(a) * 0.9 + 1
    z = 176 + rng.uniform(2, 14)
    head = head | sphere(rng.uniform(5.5, 8.5)).translate((x, y, z)).k(3)
# small nodules for fungal texture
for i in range(30):
    a = rng.uniform(0, 2 * math.pi)
    el = rng.uniform(-0.3, 1.2)
    x = 25 * math.cos(a) * math.cos(el)
    y = 22 * math.sin(a) * math.cos(el) + 1
    z = 168 + 18 * math.sin(el)
    head = head | sphere(rng.uniform(2.5, 4.5)).translate((x, y, z)).k(1.6)

# two shallow radiating grooves splitting the front plates
for ang in (-0.3, 0.3):
    groove = box((2, 16, 40)).rotate(ang, Y).translate((math.sin(ang) * 10, -22, 172))
    head = head - groove.k(1.6)

bust = bust | head.k(3)

# flat, crisp bottom for the print bed
f = bust & slab(z0=0)

f.save('clicker_bust/clicker_bust_002.stl', samples=2**22, verbose=False)
