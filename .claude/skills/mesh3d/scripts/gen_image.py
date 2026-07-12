#!/usr/bin/env python3
"""gen_image.py — text -> conditioning image candidates for 3D reconstruction.

This script's job is not "make a nice picture." It is "make a picture a 3D
reconstructor can eat." As of the 2026-07 server contract the SERVER owns all
view/lighting conditioning (three-quarter slightly-above, flat light, matte,
white background) and appends it for free — the client sends ONLY the bare
subject, which must fit the server's 60-character subject budget. The old
client-side template wrap is gone; --raw is now meaningless and removed.

Usage:
  gen_image.py --prompt SUBJECT --output DIR
               [--n 4] [--seed N] [--pedestal] [--negative TEXT]

Env:
  MESH3D_IMAGE_ENDPOINT   (required)  e.g. http://localhost:8081
  MESH3D_IMAGE_KEY        (optional)  bearer token

Server contract (POST {endpoint}/image, JSON body):
  {"text", "seed"?, "n"?, "negative_prompt"?, "pedestal"?}
  n == 1 -> raw PNG; n > 1 -> zip, entries image_{i:02d}_seed_{seed+i}.png
  headers: X-Seed (base seed), X-Prompt-Final (percent-encoded)
  422 with char_budget/char_count if the subject exceeds the budget.

Contract (suite convention): key = value lines on stdout, WARN:/FAIL: prefixed
issues, metrics.json sidecar in --output. Exit 0 ok, 1 execution error.
Candidates land as candidate_{i:02d}_seed_{seed}.png in --output.
"""

import argparse
import io
import json
import os
import random
import sys
import zipfile
from urllib.parse import unquote

SUBJECT_CHAR_BUDGET = 60  # mirrors the server; checked client-side for a fast fail


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--prompt", required=True,
                    help="bare subject only — server appends all styling")
    ap.add_argument("--output", required=True, help="output directory")
    ap.add_argument("--n", type=int, default=4, help="number of candidates (default 4)")
    ap.add_argument("--seed", type=int, help="base seed; candidate i uses seed+i")
    ap.add_argument("--pedestal", action="store_true",
                    help="server appends 'standing on a simple thick round pedestal' "
                         "(recommended for every print-destined figure)")
    ap.add_argument("--negative", default=None,
                    help="extra negative_prompt terms, merged with server defaults")
    ap.add_argument("--timeout", type=int, default=1800,
                    help="per-request timeout (MPS box takes ~3 min per image)")
    args = ap.parse_args()

    if len(args.prompt) > SUBJECT_CHAR_BUDGET:
        print(f"FAIL: subject is {len(args.prompt)} chars; budget is "
              f"{SUBJECT_CHAR_BUDGET} — the server will 422. Shorten it; "
              f"view/lighting/pedestal wording is appended server-side for free.")
        return 1

    endpoint = os.environ.get("MESH3D_IMAGE_ENDPOINT")
    if not endpoint:
        print("FAIL: MESH3D_IMAGE_ENDPOINT not set — cannot reach the image server")
        return 1

    import requests

    os.makedirs(args.output, exist_ok=True)
    seed = args.seed if args.seed is not None else random.randrange(2**31)
    headers = {"Content-Type": "application/json"}
    key = os.environ.get("MESH3D_IMAGE_KEY")
    if key:
        headers["Authorization"] = f"Bearer {key}"

    payload = {"text": args.prompt, "seed": seed, "n": args.n,
               "pedestal": bool(args.pedestal)}
    if args.negative:
        payload["negative_prompt"] = args.negative

    print(f"subject = {args.prompt}")
    print(f"seed = {seed}")
    print(f"pedestal = {payload['pedestal']}")

    try:
        r = requests.post(f"{endpoint.rstrip('/')}/image", json=payload,
                          headers=headers, timeout=args.timeout)
    except requests.RequestException as e:
        print(f"FAIL: image server unreachable: {e}")
        return 1

    if r.status_code == 422:
        try:
            body = r.json()
            print(f"FAIL: server rejected subject: {body.get('error', body)}")
        except Exception:
            print(f"FAIL: 422 from server: {r.text[:300]}")
        return 1
    if r.status_code != 200:
        print(f"FAIL: image server returned {r.status_code}: {r.text[:300]}")
        return 1

    prompt_final = unquote(r.headers.get("X-Prompt-Final", ""))
    base_seed = r.headers.get("X-Seed", str(seed))
    print(f"prompt_final = {prompt_final}")

    written = []
    ctype = r.headers.get("Content-Type", "")
    if "zip" in ctype:
        with zipfile.ZipFile(io.BytesIO(r.content)) as z:
            for name in z.namelist():
                # server names entries image_{i:02d}_seed_{seed+i}.png
                out = os.path.join(args.output,
                                   name.replace("image_", "candidate_"))
                with open(out, "wb") as f:
                    f.write(z.read(name))
                written.append(out)
    else:
        out = os.path.join(args.output, f"candidate_00_seed_{base_seed}.png")
        with open(out, "wb") as f:
            f.write(r.content)
        written.append(out)

    for w in written:
        print(f"candidate = {w}")

    with open(os.path.join(args.output, "metrics.json"), "w") as f:
        json.dump({"subject": args.prompt, "base_seed": int(base_seed),
                   "n": args.n, "pedestal": bool(args.pedestal),
                   "negative_extra": args.negative,
                   "prompt_final": prompt_final,
                   "candidates": written}, f, indent=1)

    print(f"Success: {len(written)} candidate(s) in {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
