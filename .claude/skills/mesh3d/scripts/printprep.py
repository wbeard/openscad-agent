#!/usr/bin/env python3
"""printprep.py — generative mesh -> print-ready STL, via headless Blender.

Blender runs as a SUBPROCESS (never `pip install bpy` — it version-locks
Python and poisons the skill venv). The bpy-side work is in _printprep_bpy.py.

Operation order is load-bearing and must not be reordered:
    scale -> voxel remesh -> base trim -> hollow -> decimate
Remeshing before scaling would make --voxel a meaningless unit and silently
destroy the model. Voxel remesh is mandatory: it is the only step in the
pipeline that guarantees a manifold result.

Usage:
  printprep.py MESH --output FILE.stl --height MM
               [--voxel MM] [--base-trim MM] [--hollow MM] [--decimate N]
               [--rotate-x DEG]

--voxel is the fidelity dial: FDM 0.3-0.5, resin 0.1-0.2 (default 0.4).

Exit 0 ok, 1 execution error, 2 result failed local sanity (not watertight).
"""

import argparse
import json
import os
import shutil
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BPY_SCRIPT = os.path.join(SCRIPT_DIR, "_printprep_bpy.py")


def find_blender():
    for cand in (
        shutil.which("blender"),
        "/Applications/Blender.app/Contents/MacOS/Blender",
        "C:/Program Files/Blender Foundation/Blender/blender.exe",
    ):
        if cand and os.path.exists(cand):
            return cand
    return None


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("mesh", help="input mesh (glb/gltf/stl/obj/ply)")
    ap.add_argument("--output", required=True, help="output STL path")
    ap.add_argument("--height", type=float, required=True, help="target print height, mm (Z)")
    ap.add_argument("--voxel", type=float, default=0.4,
                    help="voxel remesh size, mm (FDM 0.3-0.5, resin 0.1-0.2)")
    ap.add_argument("--base-trim", type=float, default=0.0,
                    help="slice this many mm off the bottom for a flat base")
    ap.add_argument("--hollow", type=float, default=0.0,
                    help="hollow with this wall thickness, mm (0 = solid; no drain holes)")
    ap.add_argument("--decimate", type=int, default=0,
                    help="target triangle count (0 = keep)")
    ap.add_argument("--rotate-x", type=float, default=0.0,
                    help="pre-rotation about X, degrees (stand the model up)")
    args = ap.parse_args()

    if not os.path.isfile(args.mesh):
        print(f"FAIL: input mesh not found: {args.mesh}")
        return 1
    blender = find_blender()
    if not blender:
        print("FAIL: Blender not found — install with: brew install --cask blender")
        return 1

    out = os.path.abspath(args.output)
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    if os.path.exists(out):
        os.remove(out)  # stale output must not masquerade as success

    cmd = [blender, "-b", "--factory-startup", "-noaudio", "-P", BPY_SCRIPT, "--",
           os.path.abspath(args.mesh), out,
           str(args.height), str(args.voxel), str(args.base_trim),
           str(args.hollow), str(args.decimate), str(args.rotate_x)]
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=1800)

    # Blender is chatty; surface only our own marker lines plus errors
    tris_in = None
    for line in proc.stdout.splitlines():
        if line.startswith("PRINTPREP "):
            print(line.removeprefix("PRINTPREP "))
            if line.startswith("PRINTPREP tris_in"):
                tris_in = int(line.split("=")[1])

    if not os.path.isfile(out):
        print("FAIL: Blender did not produce the STL. stderr tail:")
        tail = (proc.stderr or proc.stdout).splitlines()[-15:]
        print("\n".join(tail))
        return 1

    # ── local sanity via trimesh (this venv), before the suite's full gates ──
    import trimesh
    mesh = trimesh.load(out, force="mesh")
    bbox = [round(float(v), 2) for v in mesh.extents]
    metrics = {
        "tris_in": tris_in,
        "tris_out": int(len(mesh.faces)),
        "bbox_mm": bbox,
        "voxel_mm": args.voxel,
        "volume_mm3": round(float(mesh.volume), 1) if mesh.is_watertight else None,
        "watertight": bool(mesh.is_watertight),
    }
    with open(out + ".metrics.json", "w") as f:
        json.dump(metrics, f, indent=2)
    for k, v in metrics.items():
        print(f"{k} = {v}")

    if abs(bbox[2] - args.height) > 0.5:
        print(f"WARN: bbox Z {bbox[2]} differs from --height {args.height} by >0.5mm "
              f"(base trim / rotation can account for small offsets)")
    if not mesh.is_watertight:
        print("FAIL: output not watertight after voxel remesh — raise --voxel and re-prep")
        return 2

    print(f"Success: {out}")
    print(f"Next: render it ({bbox[2]}mm tall) and compare against the PRE-prep render —")
    print("      the remesh mutates the model; then run the suite's validate-stl.py.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
