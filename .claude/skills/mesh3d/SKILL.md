---
name: mesh3d
description: Text or image → generative 3D → print-ready STL, for figurines, organic sculpture, faces, creatures — anything code-CAD cannot author. NOT for mechanical parts; anything with a tolerance or mating face routes to /build123d.
allowed-tools:
  - Bash(*/gen_image.py*)
  - Bash(*/prep_image.py*)
  - Bash(*/gen_shape.py*)
  - Bash(*/printprep.py*)
  - Bash(*/render-scad.sh*)
  - Bash(*/validate-stl.py*)
  - Read
  - Write
  - Glob
---

# mesh3d — generative 3D skill

Two entry points that converge: text → conditioning image → mesh, or a user
image → mesh. Everything downstream of the mesh reuses the suite:
`render-scad.sh` (accepts .stl directly) for eyes, `validate-stl.py` for
gates. This skill adds four verbs; the loop below is the control flow — there
is no orchestrator.

## Environment

- `MESH3D_SHAPE_ENDPOINT` (required) — the GPU shape server, e.g. `http://localhost:8081`
- `MESH3D_IMAGE_ENDPOINT` (required for text entry) — the image server (same
  box/port serves both; it is single-worker and blocks even `/health` while
  generating — requests queue, use generous timeouts)
- `MESH3D_SHAPE_KEY` / `MESH3D_IMAGE_KEY` (optional) — bearer tokens, env only, never argv
- Scripts run with `~/.venv-mesh3d/bin/python` (light: trimesh, requests, pillow, numpy)
- printprep needs Blender ≥ 4.1 installed (subprocess, auto-detected)

## Settled constraints (do not relitigate)

- The **image is always the conditioning signal**; user text never reaches
  the shape model.
- **Iterate on the image, not the mesh** — image gen is seconds/cents, shape
  gen is minutes/dollars.
- **Shape stage only.** Never invoke the texture/paint stage (CUDA-only
  liability on this host; STL carries no texture anyway — see
  `references/failure-modes.md`).
- **Voxel remesh is mandatory** — it is the only manifoldness guarantee.

## Autonomy budget

- Iterate **freely on images** — but show the chosen candidate to the user
  before spending GPU time.
- Iterate **freely on printprep parameters** (local, free).
- **Ask the user before regenerating the shape** (GPU time costs real money).

## The loop

### 1. ROUTE

Figurine / organic / sculptural / creature / face → continue.
**Mechanical part — enclosure, bracket, anything with a tolerance, a
dimension that matters, or a mating face → STOP.** Hand off to `/build123d`
(or `/openscad`). Generative meshes cannot hold a dimension; this redirect
prevents the most expensive failure in the suite.

### 2. Establish print parameters

Target height (mm) and process. These set the prep dials:
- FDM: `--voxel 0.3–0.5`
- resin: `--voxel 0.1–0.2`

If the piece has a **width/footprint budget** too (game pieces, shelf slots,
multi-part assemblies), write it down now and screen candidate images by
subject bbox ratio *before* shape gen — figurine subjects run 0.7–1.0
width-to-height, and scaling to a height target silently blows the width
budget (see failure catalog).

### 3. Get a reference image

- User supplied one → step 5.
- Text only →

```bash
~/.venv-mesh3d/bin/python .claude/skills/mesh3d/scripts/gen_image.py \
    --prompt "<bare subject, ≤60 chars>" --output <name>_img/ --n 4 \
    [--pedestal] [--negative "extra, negatives"]
```

The SERVER owns all conditioning (three-quarter slightly-above view, flat
lighting, matte, white background, quality suffix) and appends it for free —
`assets/conditioning-prompt.md` documents the discipline but is no longer
sent by the client. Pass the *bare subject only*, within the 60-character
budget (over-budget → clean 422, client pre-checks). `--pedestal` adds the
round-plinth clause server-side — use it for every print-destined figurine.
Strong character names beat descriptions; avoid strong-prior phrases that
hijack weak subjects (see failure catalog).

### 4. LOOK AT THE IMAGE — spend the iteration budget HERE

Read every candidate. Reject on:
- wrong subject / missing feature the user asked for
- occlusion: limbs crossing the body
- hard shadows, dramatic lighting
- cropping, extreme perspective
- glossy / reflective surfaces

If none are good: refine the prompt (more specific subject wording, not
style adjectives) and re-run gen_image.py. This is CHEAP — iterate freely.
Do not proceed to the GPU with a mediocre reference: every downstream defect
will be traceable to it and none will be fixable.

**Show the user the chosen candidate and get buy-in before generating.**

### 5. Prep and gate

```bash
~/.venv-mesh3d/bin/python .claude/skills/mesh3d/scripts/prep_image.py \
    <chosen.png> --output <name>_prep/
```

If any `WARN:` lines appear (small subject, multiple subjects, low contrast,
probable cast shadow) → go back to step 3/4. **Do not push through
warnings** — for a user-supplied photo, explain the problem and offer to
generate a better reference instead.

### 6. Generate the shape

```bash
~/.venv-mesh3d/bin/python .claude/skills/mesh3d/scripts/gen_shape.py \
    --image <name>_prep/prepped.png --output <name>_mesh/
```

Health check fires first — a dead GPU box fails in <5s. **Record the seed
from the output**; it is the reproducibility handle. The script never
retries: retry decisions are yours (step 7).

### 7. RENDER AND LOOK — the load-bearing judgment

```bash
.claude/skills/preview-scad/scripts/render-scad.sh <name>_mesh/raw_preview.stl --views std
```

Read all four views **side-by-side with the reference image**. Name each
defect concretely, then classify into exactly one bucket:

| Bucket | Symptoms | Action |
|---|---|---|
| **IMAGE** | missing wings/limbs the user asked for; fused geometry where the reference had overlap; lumps where the reference had cast shadows; hollow/undefined back | → **step 3.** New prompt or reference. A new seed against a wingless reference produces a wingless mesh, forever. |
| **SHAPE** | reference is clean and unambiguous, but the mesh has artifacts, floaters, blobby topology | → new **seed** (ask the user first). Not more steps. Not prep params. |
| **PREP** | correct form, but too smooth / wrong size / no flat base | → tune printprep params. Free. |

**Rule of thumb: if the defect is visible in the reference image, it is an
IMAGE defect.** Look at the reference before blaming the shape model — this
is the most commonly misdiagnosed bucket.

### 8. Print prep

```bash
~/.venv-mesh3d/bin/python .claude/skills/mesh3d/scripts/printprep.py \
    <name>_mesh/mesh.glb --output <name>_001.stl --height <MM> --voxel <MM> \
    [--base-trim 1.5] [--rotate-x 90] [--hollow 2.5] [--decimate 300000]
```

`--voxel` is the fidelity dial. Operation order inside is fixed
(scale → remesh → trim → hollow → decimate) — never reorder it. Note
`--hollow` makes no drain holes; mention that to resin users.

### 9. RENDER AGAIN, post-prep

```bash
.claude/skills/preview-scad/scripts/render-scad.sh <name>_001.stl --views std
```

The remesh mutates the model; detail that survived generation can die here.
Compare with the step-7 renders. Lost detail → lower `--voxel` and re-prep.
**Do NOT regenerate the shape for a prep problem.**

### 10. Validate (suite gates)

```bash
python3 .claude/skills/export-stl/scripts/validate-stl.py <name>_001.stl
```

Map each failure to a parameter:
- not watertight → raise `--voxel`
- `body_count > 1` → floaters; raise `--voxel`, or (ask, then) regenerate
- thin-wall worries → raise `--height`, or warn the user and accept
- height mismatch → `--height` was wrong; re-prep, don't regenerate

### 11. Deliver

- the STL
- the multi-view contact sheet (post-prep renders)
- the reference image used
- **both seeds** — image seed AND shape seed (full reproducibility)

## Versioning

Suite convention: `<name>_001.stl`, `_002`, … — bump the version when the
*mesh* changes (new image or new seed); prep-only retunes overwrite in place
until the result validates.

## Read before debugging

- `references/failure-modes.md` — the known-failure catalog and the defect
  classification cheat table
- `references/conditioning-images.md` — why the image template is shaped the
  way it is (edit `assets/conditioning-prompt.md`, keep the discipline)
