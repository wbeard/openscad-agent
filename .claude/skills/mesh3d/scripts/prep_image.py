#!/usr/bin/env python3
"""prep_image.py — condition a reference image for the shape model, and gate it.

Background removal -> crop to subject -> square pad -> contrast normalize.
Generated images are NOT exempt: this gate runs on gen_image.py output too.

Emits WARN: lines (not just transforms) so SKILL.md can loop back to
gen_image.py BEFORE spending GPU time.

Usage:
  prep_image.py IMAGE --output DIR [--size 1024] [--no-rembg]

Background removal strategy (skill venv stays light — rembg is NOT a dependency):
  1. existing alpha channel, if meaningful
  2. rembg, if importable in this python (optional, user-installed)
  3. corner flood-fill (works well on the plain backgrounds the
     conditioning template enforces)

Exit 0 (warnings are WARN: lines, not failures), 1 on execution error.
"""

import argparse
import json
import os
import sys

import numpy as np
from PIL import Image, ImageOps


def flood_background_mask(rgb, tol=28):
    """Estimate background by flood-filling from the four corners."""
    h, w, _ = rgb.shape
    img = rgb.astype(np.int16)
    bg = np.zeros((h, w), dtype=bool)
    from collections import deque
    seeds = [(0, 0), (0, w - 1), (h - 1, 0), (h - 1, w - 1)]
    for sy, sx in seeds:
        if bg[sy, sx]:
            continue
        ref = img[sy, sx]
        q = deque([(sy, sx)])
        visited = bg
        while q:
            y, x = q.popleft()
            if visited[y, x]:
                continue
            if np.abs(img[y, x] - ref).max() > tol:
                continue
            visited[y, x] = True
            if y > 0: q.append((y - 1, x))
            if y < h - 1: q.append((y + 1, x))
            if x > 0: q.append((y, x - 1))
            if x < w - 1: q.append((y, x + 1))
    return ~bg  # subject mask


def connected_components(mask):
    """Count significant connected components (>1% of subject area)."""
    from collections import deque
    h, w = mask.shape
    labels = np.zeros((h, w), dtype=np.int32)
    sizes = []
    nxt = 0
    for sy in range(h):
        for sx in range(w):
            if mask[sy, sx] and labels[sy, sx] == 0:
                nxt += 1
                size = 0
                q = deque([(sy, sx)])
                labels[sy, sx] = nxt
                while q:
                    y, x = q.popleft()
                    size += 1
                    for ny, nx_ in ((y-1,x),(y+1,x),(y,x-1),(y,x+1)):
                        if 0 <= ny < h and 0 <= nx_ < w and mask[ny, nx_] and labels[ny, nx_] == 0:
                            labels[ny, nx_] = nxt
                            q.append((ny, nx_))
                sizes.append(size)
    total = sum(sizes) or 1
    return sum(1 for s in sizes if s / total > 0.01)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("image")
    ap.add_argument("--output", required=True, help="output directory")
    ap.add_argument("--size", type=int, default=1024)
    ap.add_argument("--no-rembg", action="store_true", help="skip rembg even if installed")
    ap.add_argument("--downscale", type=int, default=256,
                    help="analysis resolution for masks (default 256)")
    args = ap.parse_args()

    if not os.path.isfile(args.image):
        print(f"FAIL: file not found: {args.image}")
        return 1
    os.makedirs(args.output, exist_ok=True)

    im = Image.open(args.image).convert("RGBA")
    warnings = []

    # ── subject mask ─────────────────────────────────────────
    small = im.resize((args.downscale, args.downscale), Image.LANCZOS)
    arr = np.asarray(small)
    method = None
    if arr[..., 3].min() < 250:                       # meaningful alpha already
        mask_small = arr[..., 3] > 128
        method = "alpha"
    elif not args.no_rembg:
        try:
            from rembg import remove  # optional; NOT a skill dependency
            im = remove(im)
            small = im.resize((args.downscale, args.downscale), Image.LANCZOS)
            arr = np.asarray(small)
            mask_small = arr[..., 3] > 128
            method = "rembg"
        except ImportError:
            pass
    if method is None:
        mask_small = flood_background_mask(arr[..., :3])
        method = "floodfill"

    subject_fraction = float(mask_small.mean())
    parts = connected_components(mask_small)

    # ── gates: warn, don't silently transform ────────────────
    if subject_fraction < 0.05:
        print(f"FAIL: no meaningful subject found (subject_fraction {subject_fraction:.2f})")
        return 1
    if subject_fraction < 0.4:
        warnings.append(f"subject_fraction {subject_fraction:.2f} < 0.4 — subject too small in frame")
    if parts > 1:
        warnings.append(f"{parts} separate subjects detected — shape model wants exactly one")

    ys, xs = np.where(mask_small)
    bh, bw = ys.max() - ys.min() + 1, xs.max() - xs.min() + 1
    aspect = max(bh, bw) / max(1, min(bh, bw))
    if aspect > 3.0:
        warnings.append(f"extreme subject aspect ratio {aspect:.1f} — check for cropping or perspective")

    gray = np.asarray(small.convert("L")).astype(np.float32)
    fg_lum, bg_lum = gray[mask_small].mean(), gray[~mask_small].mean() if (~mask_small).any() else 255.0
    if abs(fg_lum - bg_lum) < 20:
        warnings.append(f"low contrast against background (fg {fg_lum:.0f} vs bg {bg_lum:.0f})")

    # cast-shadow heuristic: dark background pixels hugging the subject's
    # lower half (mask dilation by shifting — no scipy in the light venv)
    dil = mask_small.copy()
    for dy, dx in ((0,1),(0,-1),(1,0),(-1,0),(1,1),(1,-1),(2,0),(0,2),(0,-2)):
        dil |= np.roll(np.roll(mask_small, dy, 0), dx, 1)
    halo = dil & ~mask_small
    halo[: args.downscale // 2] = False          # only look below the midline
    if halo.any():
        halo_lum = gray[halo].mean()
        if bg_lum - halo_lum > 30:
            warnings.append(f"probable cast shadow under subject (halo {halo_lum:.0f} vs bg {bg_lum:.0f}) — shadows reconstruct as geometry")

    # ── transform: crop -> square pad -> normalize -> resize ─
    scale_y, scale_x = im.height / args.downscale, im.width / args.downscale
    pad = 0.06
    x0 = max(0, int(xs.min() * scale_x - pad * im.width))
    x1 = min(im.width, int((xs.max() + 1) * scale_x + pad * im.width))
    y0 = max(0, int(ys.min() * scale_y - pad * im.height))
    y1 = min(im.height, int((ys.max() + 1) * scale_y + pad * im.height))
    im = im.crop((x0, y0, x1, y1))

    side = max(im.width, im.height)
    canvas = Image.new("RGBA", (side, side), (255, 255, 255, 255))
    canvas.paste(im, ((side - im.width) // 2, (side - im.height) // 2), im)

    rgb = ImageOps.autocontrast(canvas.convert("RGB"), cutoff=1)
    out = rgb.resize((args.size, args.size), Image.LANCZOS)
    out_path = os.path.join(args.output, "prepped.png")
    out.save(out_path)

    metrics = {
        "subject_fraction": round(subject_fraction, 3),
        "has_alpha": method in ("alpha", "rembg"),
        "mask_method": method,
        "subjects": parts,
        "aspect": round(float(aspect), 2),
        "warnings": warnings,
        "prepped": out_path,
    }
    with open(os.path.join(args.output, "metrics.json"), "w") as f:
        json.dump(metrics, f, indent=2)

    print(f"subject_fraction = {subject_fraction:.3f}")
    print(f"mask_method = {method}")
    print(f"subjects = {parts}")
    print(f"aspect = {aspect:.2f}")
    for w in warnings:
        print(f"WARN: {w}")
    print(f"Success: prepped image at {out_path}")
    if warnings:
        print("Warnings present — fix the reference (SKILL.md steps 3-4) before gen_shape.py.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
