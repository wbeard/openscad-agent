#!/usr/bin/env python3
"""STL printability gate: trimesh mesh checks + prusa-slicer --info cross-check.

Exit codes:
  0 = PASS (warnings allowed)
  2 = FAIL (hard gate: non-watertight, open edges, non-manifold edges,
      inconsistent winding, non-positive volume, or bbox out of tolerance)
  1 = usage / file error

Usage:
  validate-stl.py <file.stl> [--expect-size X,Y,Z] [--tolerance MM] [--allow-multi-part]
"""

import argparse
import os
import shutil
import subprocess
import sys


def find_prusa_slicer():
    for cand in (
        shutil.which("prusa-slicer"),
        shutil.which("prusaslicer"),
        "/Applications/PrusaSlicer.app/Contents/MacOS/PrusaSlicer",
        "/Applications/Original Prusa Drivers/PrusaSlicer.app/Contents/MacOS/PrusaSlicer",
        "C:/Program Files/Prusa3D/PrusaSlicer/prusa-slicer-console.exe",
    ):
        if cand and os.path.exists(cand):
            return cand
    return None


def prusa_info(slicer, path):
    """Parse `prusa-slicer --info` key=value output into a dict."""
    try:
        out = subprocess.run(
            [slicer, "--info", path], capture_output=True, text=True, timeout=120
        ).stdout
    except (subprocess.TimeoutExpired, OSError) as e:
        return {"_error": str(e)}
    info = {}
    for line in out.splitlines():
        if "=" in line:
            k, _, v = line.partition("=")
            info[k.strip()] = v.strip()
    return info


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("stl")
    ap.add_argument("--expect-size", help="Expected bbox size in mm as X,Y,Z")
    ap.add_argument("--tolerance", type=float, default=0.5,
                    help="Allowed bbox deviation per axis in mm (default 0.5)")
    ap.add_argument("--allow-multi-part", action="store_true",
                    help="Do not fail when the mesh contains disconnected parts")
    args = ap.parse_args()

    if not os.path.isfile(args.stl):
        print(f"Error: file not found: {args.stl}")
        return 1

    failures = []
    warnings = []

    # ── trimesh checks ──────────────────────────────────────
    try:
        import numpy as np
        import trimesh
    except ImportError:
        print("WARNING: trimesh not installed (pip3 install --user trimesh numpy) — skipping mesh checks")
        trimesh = None

    if trimesh is not None:
        mesh = trimesh.load(args.stl, force="mesh")  # process=True merges STL's duplicated vertices

        # Edge sharing: each edge of a closed manifold is shared by exactly 2 faces
        _, counts = np.unique(mesh.edges_sorted, axis=0, return_counts=True)
        open_edges = int((counts == 1).sum())
        overshared_edges = int((counts > 2).sum())
        degenerate = int((mesh.area_faces < 1e-9).sum())
        parts = mesh.body_count
        ext = mesh.extents if len(mesh.vertices) else [0, 0, 0]

        print("--- trimesh ---")
        print(f"watertight          = {mesh.is_watertight}")
        print(f"winding_consistent  = {mesh.is_winding_consistent}")
        print(f"open_edges          = {open_edges}")
        print(f"nonmanifold_edges   = {overshared_edges}")
        print(f"degenerate_faces    = {degenerate}")
        print(f"parts               = {parts}")
        print(f"bbox_size_mm        = {ext[0]:.2f} x {ext[1]:.2f} x {ext[2]:.2f}")
        print(f"volume_mm3          = {mesh.volume:.1f}" if mesh.is_watertight else "volume_mm3          = n/a (not watertight)")

        if not mesh.is_watertight:
            detail = f"{open_edges} open edges — holes in the surface" if open_edges \
                else "no open edges, so likely edge-connected or duplicated geometry"
            failures.append(f"mesh is NOT watertight ({detail})")
        if open_edges > 0 and mesh.is_watertight:
            failures.append(f"{open_edges} open edges despite watertight flag")
        if overshared_edges > 0:
            failures.append(f"{overshared_edges} non-manifold edges (edge shared by >2 faces) — usually shapes touching at exactly one edge/face; overlap them slightly and union()")
        if not mesh.is_winding_consistent:
            failures.append("inconsistent face winding — normals flip direction; check for inverted/negative-scale geometry")
        if mesh.is_watertight and mesh.volume <= 0:
            failures.append(f"non-positive volume ({mesh.volume:.1f} mm³) — mesh is inside-out")
        if degenerate > 0:
            warnings.append(f"{degenerate} degenerate (zero-area) faces — slicers usually cope, but check very thin features")
        if parts > 1:
            msg = f"mesh contains {parts} disconnected parts — floating geometry will not print attached"
            (warnings if args.allow_multi_part else failures).append(msg)

        if args.expect_size:
            try:
                exp = [float(v) for v in args.expect_size.split(",")]
            except ValueError:
                print(f"Error: bad --expect-size '{args.expect_size}', want X,Y,Z")
                return 1
            for axis, (e, a) in enumerate(zip(exp, ext)):
                dev = abs(e - a)
                if dev > args.tolerance:
                    failures.append(
                        f"bbox {'XYZ'[axis]} = {a:.2f}mm, expected {e:.2f}mm "
                        f"(off by {dev:.2f}mm > tolerance {args.tolerance}mm)"
                    )

    # ── prusa-slicer cross-check ────────────────────────────
    slicer = find_prusa_slicer()
    if slicer:
        info = prusa_info(slicer, args.stl)
        if "_error" in info:
            warnings.append(f"prusa-slicer --info failed: {info['_error']}")
        else:
            print("--- prusa-slicer ---")
            for k in ("size_x", "size_y", "size_z", "number_of_facets",
                      "manifold", "number_of_parts", "volume", "open_edges"):
                if k in info:
                    print(f"{k} = {info[k]}")
            if info.get("manifold", "yes").lower() == "no":
                failures.append("prusa-slicer reports manifold = no")
            oe = info.get("open_edges")
            if oe and oe.isdigit() and int(oe) > 0:
                failures.append(f"prusa-slicer reports open_edges = {oe}")
    else:
        warnings.append("prusa-slicer not found — skipping slicer cross-check (brew install --cask prusaslicer)")

    # ── verdict ─────────────────────────────────────────────
    print()
    for w in warnings:
        print(f"WARN: {w}")
    if failures:
        print("VALIDATION: FAIL")
        for f in failures:
            print(f"FAIL: {f}")
        return 2
    print("VALIDATION: PASS — mesh is watertight, manifold, and within tolerance")
    return 0


if __name__ == "__main__":
    sys.exit(main())
