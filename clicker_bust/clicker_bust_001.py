"""Stylized 'Clicker' bust on a pedestal — organic SDF build.

Layout (mm, Z up, front faces -Y):
  z 0..69    stepped stone plinth
  z 61..130  torso (blended onto plinth cap), shoulders, tank-top straps
  z 130..150 neck + lower face with open mouth
  z 150..192 fungal head: blended blob cluster with radiating front grooves
"""

import math
import random

from sdf import *

rng = random.Random(42)

# ---------------------------------------------------------------- plinth
plinth = box((60, 60, 8)).translate((0, 0, 2))                 # base slab (cut flat at z=0 later)
plinth |= rounded_box((52, 52, 6), 1.5).translate((0, 0, 8.5))
plinth |= rounded_box((42, 42, 50), 1.5).translate((0, 0, 36))
plinth |= rounded_box((50, 50, 5), 1.5).translate((0, 0, 61.5))
plinth |= rounded_box((56, 56, 5), 1.2).translate((0, 0, 66.5))

# creeping tendrils on the plinth faces
tendrils = None
tendril_pts = [
    ((-20, -30.5, 4), (-8, -30.5, 40)),
    ((-8, -30.5, 40), (6, -30.5, 66)),
    ((16, -30.5, 6), (22, -30.5, 46)),
    ((30.5, -14, 8), (30.5, 4, 52)),
    ((30.5, 4, 52), (30.5, 18, 66)),
    ((-30.5, 10, 6), (-30.5, -6, 48)),
    ((-12, 30.5, 10), (2, 30.5, 60)),
]
for a, b in tendril_pts:
    t = capsule(a, b, 1.6)
    tendrils = t if tendrils is None else tendrils | t
plinth = plinth | tendrils.k(1.2)

# ---------------------------------------------------------------- torso
torso = ellipsoid((25, 16, 33)).translate((0, 0, 96))
# collapsed chest ribs: shallow horizontal scoops on the front
for z in (84, 92, 100, 108):
    rib = capsule((-14, -17.5, z), (14, -17.5, z), 3.2)
    torso = torso - rib.k(2.5)
# shoulders: lumpy fungal masses
for sx in (-1, 1):
    torso = torso | sphere(12.5).translate((sx * 25, 1, 112)).k(6)
    for i in range(6):
        r = rng.uniform(3.0, 5.5)
        ang = rng.uniform(0, 2 * math.pi)
        torso = torso | sphere(r).translate((
            sx * (25 + 8.5 * abs(math.cos(ang))),
            1 + 9 * math.sin(ang),
            112 + rng.uniform(-8, 9),
        )).k(2.5)

# tank-top straps draped over the shoulders
straps = None
for sx in (-1, 1):
    front = capsule((sx * 13, -15.5, 96), (sx * 16, -2, 121), 2.6)
    back = capsule((sx * 16, -2, 121), (sx * 13, 15.5, 96), 2.6)
    s = front | back
    straps = s if straps is None else straps | s
torso = torso | straps.k(1.5)

# melt the torso onto the plinth cap (overgrowth spilling over the edge)
bust = plinth | torso.k(4)

# ---------------------------------------------------------------- neck + face
neck = capsule((0, 1, 118), (0, -3, 150), 9.5)
face = ellipsoid((10.5, 10, 13)).translate((0, -6, 148))
head_base = neck | face.k(5)
# gaping mouth
mouth = sphere(5.5).translate((0, -15, 145)).elongate((0, 0, 2))
head_base = head_base - mouth.k(1.5)

bust = bust | head_base.k(4)

# ---------------------------------------------------------------- fungal head
core = ellipsoid((15, 14, 13)).translate((0, 0, 165))
head = core
# ring of large plates flaring outward
for i in range(9):
    a = i / 9 * 2 * math.pi
    x = 19 * math.cos(a)
    y = 17 * math.sin(a) + 2
    z = 168 + rng.uniform(-3, 3)
    head = head | sphere(rng.uniform(8.5, 11.5)).translate((x, y, z)).k(4.5)
# upper dome cluster
for i in range(16):
    a = rng.uniform(0, 2 * math.pi)
    rad = rng.uniform(3, 15)
    x = rad * math.cos(a)
    y = rad * math.sin(a) * 0.9 + 1
    z = 176 + rng.uniform(0, 10)
    head = head | sphere(rng.uniform(5.5, 9)).translate((x, y, z)).k(4)
# small nodules for texture
for i in range(22):
    a = rng.uniform(0, 2 * math.pi)
    el = rng.uniform(-0.2, 1.1)
    x = 22 * math.cos(a) * math.cos(el)
    y = 20 * math.sin(a) * math.cos(el) + 2
    z = 168 + 16 * math.sin(el)
    head = head | sphere(rng.uniform(2.5, 4.5)).translate((x, y, z)).k(2)

# radiating grooves splitting the front plates (the "bloomed" look)
for ang in (-0.55, -0.18, 0.18, 0.55):
    groove = box((2.2, 34, 44)).rotate(ang, Y).translate((0, -14, 170)).rotate(ang * 0.6, Z)
    head = head - groove.k(2.2)

bust = bust | head.k(5)

# flat, crisp bottom for the print bed
f = bust & slab(z0=0)

f.save('clicker_bust/clicker_bust_001.stl', samples=2**22, verbose=False)
