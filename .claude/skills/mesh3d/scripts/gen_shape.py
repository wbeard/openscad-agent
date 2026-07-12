#!/usr/bin/env python3
"""gen_shape.py — image -> mesh via the shape server (HTTP client, nothing more).

The shape model runs behind MESH3D_SHAPE_ENDPOINT. This script is a client:
it health-checks (so a dead box fails in <5s, not after a 3-minute timeout),
posts the prepped PNG, and reports stats. It NEVER retries internally —
whether to retry with a new seed, a new image, or not at all is a judgment
call that belongs to the agent (SKILL.md step 7).

Server contract (2026-07, the real deployed server):
  GET  {endpoint}/health -> {"ok", "image_model_loaded", "shape_model_loaded",
                             "device", "vram_free_mb"}
  POST {endpoint}/shape  body = raw PNG bytes, Content-Type: image/png
       query params: ?seed=<int>&steps=<int>&octree_resolution=<int>
       -> GLB bytes (model/gltf-binary), synchronous (minutes on MPS)
       headers: X-Seed, X-Tris, X-Watertight
  NOTE the server is single-worker: it blocks (even /health) while any
  image or shape job runs. Requests queue; use generous timeouts.

Usage:
  gen_shape.py --image PREPPED.png --output DIR
               [--seed N] [--steps 30] [--octree-resolution 256]
               [--timeout 3600]

Env:
  MESH3D_SHAPE_ENDPOINT  (required)   e.g. http://localhost:8081
  MESH3D_SHAPE_KEY       (optional)   bearer token — never passed on argv

Outputs in --output:
  mesh.<fmt>        canonical mesh as served (usually glb)
  raw_preview.stl   trimesh conversion FOR PREVIEW/RENDER ONLY — this is not
                    print prep; printprep.py consumes mesh.<fmt>
  metrics.json

Exit 0 ok, 1 execution/provider error (structured JSON line on stdout).
"""

import argparse
import json
import os
import random
import sys
import time


def body_count(mesh):
    """Connected components over ALL shared edges, scipy-free (light venv).

    Do NOT use trimesh.face_adjacency here: it only pairs faces at manifold
    edges (shared by exactly 2 faces). Raw shape-model GLBs are full of
    non-manifold edges, which fragments the count absurdly (observed: 64k
    "bodies" on a 187k-tri mesh that really has ~270). Union faces across
    every shared sorted edge instead, regardless of how many faces meet it.
    """
    import numpy as np
    n = len(mesh.faces)
    edges = np.sort(mesh.edges, axis=1)
    face_idx = np.repeat(np.arange(n), 3)
    _, inv = np.unique(edges, axis=0, return_inverse=True)
    parent = np.arange(n)

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    order = np.argsort(inv)
    si, sf = inv[order], face_idx[order]
    boundaries = np.searchsorted(si, np.arange(si[-1] + 2))
    for s, e in zip(boundaries[:-1], boundaries[1:]):
        if e - s < 2:
            continue
        f0 = sf[s]
        for f1 in sf[s + 1:e]:
            r0, r1 = find(f0), find(f1)
            if r0 != r1:
                parent[r0] = r1
    return len({find(i) for i in range(n)})


def fail(kind, **detail):
    print(json.dumps({"error": kind, **detail}))
    print(f"FAIL: {kind}: {detail}")
    return 1


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--image", required=True, help="prepped conditioning image (png)")
    ap.add_argument("--output", required=True, help="output directory")
    ap.add_argument("--seed", type=int, help="reproducibility handle; generated if omitted")
    ap.add_argument("--steps", type=int, default=None,
                    help="sampler steps; omit to use the server default")
    ap.add_argument("--octree-resolution", type=int, default=None,
                    help="shape octree resolution; omit to use the server default")
    ap.add_argument("--timeout", type=int, default=3600,
                    help="request timeout (s) — the server queues serially")
    args = ap.parse_args()

    if not os.path.isfile(args.image):
        return fail("image_not_found", path=args.image)

    endpoint = os.environ.get("MESH3D_SHAPE_ENDPOINT")
    if not endpoint:
        return fail("endpoint_not_configured",
                    hint="export MESH3D_SHAPE_ENDPOINT=http://host:port")
    endpoint = endpoint.rstrip("/")

    import requests

    headers = {}
    key = os.environ.get("MESH3D_SHAPE_KEY")
    if key:
        headers["Authorization"] = f"Bearer {key}"

    # ── health check first: dead box fails fast ──────────────
    # NOTE: a BUSY server also fails to answer /health (single worker blocks
    # the event loop while generating). Distinguish dead from busy only by
    # whether the port accepts the connection at all.
    try:
        h = requests.get(f"{endpoint}/health", headers=headers, timeout=5)
        h.raise_for_status()
        health = h.json()
    except requests.RequestException as e:
        return fail("shape_server_unreachable_or_busy", endpoint=endpoint,
                    detail=str(e),
                    hint="dead box OR mid-generation (server is single-worker); "
                         "check MESH3D_SHAPE_ENDPOINT, retry after current job")
    if not health.get("ok") or not health.get("shape_model_loaded"):
        return fail("shape_server_not_ready", health=health,
                    hint="server up but shape model not loaded — wait for warm-up")
    print(f"health = ok (device {health.get('device', '?')}, "
          f"vram_free_mb {health.get('vram_free_mb', '?')})")

    seed = args.seed if args.seed is not None else random.randrange(2**31)
    os.makedirs(args.output, exist_ok=True)
    t0 = time.time()

    # ── submit: raw PNG body, params in the query string, GLB back ──
    params = {"seed": seed}
    if args.steps is not None:
        params["steps"] = args.steps
    if args.octree_resolution is not None:
        params["octree_resolution"] = args.octree_resolution
    try:
        with open(args.image, "rb") as f:
            r = requests.post(f"{endpoint}/shape",
                              headers={**headers, "Content-Type": "image/png"},
                              params=params, data=f.read(),
                              timeout=args.timeout)
        r.raise_for_status()
    except requests.RequestException as e:
        return fail("shape_request_failed", detail=str(e), seed=seed)

    ctype = r.headers.get("Content-Type", "")
    if "gltf" not in ctype and "octet" not in ctype:
        return fail("unexpected_response", content_type=ctype,
                    body_head=r.text[:200], seed=seed)

    mesh_path = os.path.join(args.output, "mesh.glb")
    with open(mesh_path, "wb") as f:
        f.write(r.content)
    server_meta = {
        "seed": r.headers.get("X-Seed", str(seed)),
        "tris": r.headers.get("X-Tris"),
        "watertight": r.headers.get("X-Watertight"),
    }
    print(f"server = seed {server_meta['seed']}, tris {server_meta['tris']}, "
          f"watertight {server_meta['watertight']} (pre-remesh; printprep fixes)")

    # ── local stats + preview conversion ─────────────────────
    # GLB is a scene graph: force='mesh' collapses it to a single Trimesh.
    import trimesh
    mesh = trimesh.load(mesh_path, force="mesh")
    preview = os.path.join(args.output, "raw_preview.stl")
    mesh.export(preview)  # PREVIEW ONLY — not print prep (see failure-modes.md)

    bbox = [round(float(v), 2) for v in mesh.extents]
    metrics = {
        "seed": int(server_meta["seed"]),       # server echo wins; ours is the fallback
        "tris": int(len(mesh.faces)),
        "watertight": bool(mesh.is_watertight),
        "body_count": body_count(mesh),
        "bbox": bbox,
        "elapsed_s": round(time.time() - t0, 1),
        "mesh": mesh_path,
        "raw_preview": preview,
    }
    with open(os.path.join(args.output, "metrics.json"), "w") as f:
        json.dump(metrics, f, indent=2)

    for k in ("seed", "tris", "watertight",
              "body_count", "bbox", "elapsed_s"):
        print(f"{k} = {metrics[k]}")
    print(f"Success: mesh at {mesh_path}")
    print(f"Next: render {preview} multi-view and critique against the reference")
    print("      image (SKILL.md step 7) BEFORE printprep.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
