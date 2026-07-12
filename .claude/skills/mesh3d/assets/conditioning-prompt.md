# Conditioning image prompt template
#
# Used by gen_image.py. Lines starting with '#' are ignored.
# {SUBJECT} is replaced with the user's subject description.
# {VIEW} is replaced with the view clause selected by --view.
# The NEGATIVE: line (single line) is sent as the negative prompt.
#
# Every clause suppresses a specific 3D-reconstruction failure — see
# references/conditioning-images.md before editing. This is not an
# aesthetics template; do not add quality/cinematic vocabulary.

PROMPT:
{SUBJECT}, {VIEW}, full subject entirely in frame with margin on all
sides, single subject isolated on a plain uniform light-gray studio
background, flat even ambient lighting with no cast shadows, matte
non-reflective surfaces, all limbs and appendages posed clear of the
body without overlap, everything in sharp focus, neutral lens with
orthographic-like perspective, physical sculpture reference sheet style

NEGATIVE: dramatic lighting, cinematic, rim light, hard shadows, bokeh, depth of field, motion blur, glossy, reflective, busy background, cropped, close-up, fisheye, low angle

VIEW three-quarter: three-quarter view seen slightly from above
VIEW front: straight-on front view
VIEW side: straight-on side profile view
