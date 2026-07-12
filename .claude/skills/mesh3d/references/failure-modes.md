# mesh3d failure catalog

Known ways this pipeline goes wrong. Some were hit while building it; the
rest are documented so the next agent doesn't have to hit them.

## Upstream (image)

- **A pretty image is not a good conditioning image.** The image model's
  aesthetic defaults (dramatic lighting, shallow DoF, glossy materials, tight
  crops) are actively hostile to 3D reconstruction. Cast shadows in
  particular get reconstructed *as geometry*. If you're writing "epic,
  cinematic, 8k" into a prompt, stop.
- **Blaming the shape model for an image defect.** Missing limbs, fused arms,
  and hollow backs are almost always upstream. **Look at the reference image
  first.** If the defect is visible (or ambiguous) in the reference, it is an
  IMAGE defect: new prompt or new reference. A new seed against a wingless
  reference produces a wingless mesh, forever. This is the most commonly
  misdiagnosed bucket.

- **Prompt-prior hijacking.** A strong-prior noun phrase in the prompt
  overrides a weak-prior subject: "soot sprite chess pawn" renders a
  *literal Staunton pawn*, "castle with bird legs" renders *flying birds*.
  Diagnostic: the modifier's object appears literally in the output. Fix:
  remove the hijacking phrase and describe the geometry another way. The
  converse also works — a strong character name ("Totoro", "No-Face")
  rescues a description the model would otherwise genericize.
- **The model may simply not know a named entity.** One full round (4
  candidates) of a named subject coming back generic = no prior exists
  (e.g. Howl's Moving Castle). Stop iterating prompt wordings; switch
  strategy: user-supplied reference image, or describe the object's
  geometry without the name.
- **No width budget.** Height is not the only constraint: chibi/figurine
  subjects run 0.7–1.0 width-to-height, so a Staunton-height chess piece
  overflows its square. If the piece is constrained in more than height,
  measure the candidate image's subject bbox ratio (numpy, 5 lines)
  *before* spending GPU on shape gen, and put pose words ("slender",
  "narrow", "arms at sides") in the prompt when it fails.

## Mid-stream (shape)

- **Retrying inside the client.** `gen_shape.py` deliberately does not retry.
  Whether to reroll the seed, fix the image, or give up is a judgment call —
  it belongs to the agent, not a retry loop.
- **Sending text to the shape model.** Never. The image is always the
  conditioning signal; text goes through `gen_image.py`. Native text-to-3D is
  a lottery and skips the inspectable intermediate.
- **Anything mentioning `custom_rasterizer`, `hy3dpaint`, `texgen`, or CUDA
  on macOS** means the texture stage is being invoked. The fix is always
  "don't." STL carries no texture; those components don't build on macOS.

- **Thin features survive, shatter, or web — they never disappear cleanly.**
  Whiskers/antler tines/mane wisps in the reference become: needle spikes
  (survive even 0.4 voxel remesh), hundreds of floater fragments (strip
  them), or thin webs fused to body AND base (only a new seed or an edited
  reference removes those). If a thin feature is unwanted, remove it at the
  IMAGE stage; mesh surgery afterwards is painful and scipy/networkx-free
  trimesh makes hole-capping manual.
- **Side-view conditioning can produce layered-shell garments.** A cloak
  seen edge-on reconstructed as concentric open shells on every face
  (visible as onion ridges in renders). A new seed on the same image can
  fix it; prefer three-quarter references for draped clothing.

## Downstream (prep/export)

- **`bpy.ops.export_mesh.stl` does not exist** on Blender ≥ 4.1. It's
  `bpy.ops.wm.stl_export`. Every LLM and every StackOverflow answer will hand
  you the old name. Highest-frequency generated bug in this domain.
- **"Just export the GLB to STL"** is a one-line trimesh call that produces
  an unprintable file — normalized units, non-manifold, floating shells.
  Format conversion is not print prep. The pipeline must never terminate at
  `trimesh.load(...).export(...)`; `raw_preview.stl` from gen_shape.py exists
  for *rendering only*.
- **GLB is a scene graph.** `trimesh.load(path)` returns a `Scene`, not a
  `Trimesh`. Use `force='mesh'`.
- **Remeshing before scaling.** The printprep order (scale → voxel remesh →
  base trim → hollow → decimate) is load-bearing. Remesh first and `--voxel`
  becomes a meaningless unit that silently destroys the model.
- **Validating without looking.** Voxel remesh silently smooths detail. A
  mesh can pass every geometric check and be a featureless blob. The
  post-prep render is not optional; compare it against the pre-prep render.
- **Hollowing caveat:** `--hollow` produces no drain holes. For resin
  printing a sealed hollow is a suction/leak problem — either keep it solid
  or note the caveat to the user.
- **"Not watertight after remesh" usually means floaters, not resolution.**
  Base-trim slices floating fragments open, so the whole-file watertight
  check fails even though the main body is closed. Before raising
  `--voxel`, strip to the largest connected component (union-find over
  `face_adjacency` — `mesh.split()` needs a graph engine this venv doesn't
  ship) and re-check. King: 194 parts → 1, instantly watertight.
- **Blender's glTF import re-rotates axes.** For composed/pre-rotated GLBs
  (e.g. after grafting a pedestal in trimesh), `--rotate-x` values become
  guesswork and the height scale can land on the wrong axis. Fix
  empirically after prep: try all six axis rotations, pick the one whose
  bottom 1 mm slab has the largest footprint (the pedestal), then rescale
  Z to target height.
- **Pedestal grafting needs no booleans.** Overlap a trimesh cylinder into
  the body, `concatenate`, and let the voxel remesh fuse them — the same
  pass that guarantees manifoldness performs the union.
- **The subject_fraction gate misfires on spindly/tall subjects.** An elk
  (thin legs, antlers) or a 1:2.5 standing figure cannot reach 0.4 pixel
  fraction even filling the frame. Auto-crop to the subject bbox first; if
  the fraction still fails but the bbox fills the frame, override with a
  note — the metric penalizes thin geometry, not bad framing.

## Defect classification cheat table

| Symptom | Bucket | Action |
|---|---|---|
| missing wings/limbs the user asked for | IMAGE | new prompt/reference |
| fused limbs where reference had overlap | IMAGE | new reference, limbs separated |
| lump where reference had a cast shadow | IMAGE | re-light: flat ambient |
| hollow/undefined back | IMAGE | three-quarter view reference |
| clean reference, blobby/floater mesh | SHAPE | new seed (not more steps) |
| right shape, too smooth | PREP | lower `--voxel` |
| right shape, wrong size | PREP | fix `--height` |
| no flat base | PREP | `--base-trim` |
| not watertight after prep | PREP | strip to largest component first; then raise `--voxel` |
| body_count > 1 after prep | PREP/SHAPE | strip floaters; if fused-to-body webs persist, new seed |
| modifier object rendered literally ("chess pawn" → Staunton) | IMAGE | remove hijacking phrase, re-describe |
| named entity comes back generic across a full round | IMAGE | model lacks the prior: user ref or geometry description |
| piece wider than its physical budget | IMAGE | measure bbox ratio pre-GPU; re-prompt pose ("slender", "arms at sides") |
| garment as concentric open shells | SHAPE | new seed; prefer three-quarter reference |
| thin web fused to body and base | SHAPE/IMAGE | new seed; if persistent, edit feature out of reference |
