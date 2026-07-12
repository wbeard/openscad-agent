# Why the conditioning template looks the way it does

A conditioning image and a nice picture are different, often opposed,
objectives. Image models default to aesthetics — dramatic lighting, shallow
depth of field, glossy materials, tight crops — and every one of those
defaults is actively hostile to 3D reconstruction. The template in
`assets/conditioning-prompt.md` exists to fight them. Each clause suppresses
a specific, observed reconstruction failure:

| Template clause | Reconstruction failure it suppresses |
|---|---|
| flat, even, ambient lighting; no cast shadows | **shadows reconstructed as geometry** — the #1 killer. A hard shadow under a figure becomes a lump fused to its base. |
| plain neutral background, isolated subject | segmentation bleed: background texture becomes mesh surface |
| full subject in frame, margin on all sides | truncated/missing features — a cropped wingtip is a missing wingtip |
| limbs and appendages clear of the body | fused geometry: an arm crossing the torso becomes one blob; the model cannot invent the occluded boundary |
| matte surfaces; no gloss/chrome/wet/glass | specular highlights read as surface detail (bumps and craters that aren't there) |
| everything in sharp focus | defocused regions reconstruct as mush |
| orthographic-ish neutral lens | wide-angle/low-angle perspective bakes wrong proportions into the mesh |
| three-quarter view default | maximizes visible surface area; front-only views leave the model guessing the entire back |

The negative prompt is not optional. It carries the image model's favorite
aesthetic vocabulary — `dramatic lighting, cinematic, rim light, hard shadows,
bokeh, depth of field, motion blur, glossy, reflective, busy background,
cropped, close-up, fisheye, low angle` — precisely because those are the
things it will otherwise add unprompted.

If you find yourself adding "epic, cinematic, 8k" to this template, you have
already lost.

## Editing the template

`assets/conditioning-prompt.md` is data, not code — edit it freely, no script
changes needed. Keep the discipline: every clause you add should name the
reconstruction failure it suppresses, in this file.

## Why iterate here and not on the mesh

Image generation costs seconds and cents; shape generation costs minutes and
GPU dollars. Every defect visible in the reference will appear in the mesh,
and none of them can be fixed downstream. Burn the critique budget on the
image. A new shape seed against a wingless reference produces a wingless
mesh, forever.
