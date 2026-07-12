# Blender-side print prep. Runs ONLY inside `blender -b -P` (see printprep.py).
# argv after '--': mesh_in stl_out height voxel base_trim hollow decimate rotate_x
#
# OPERATION ORDER IS LOAD-BEARING — do not reorder:
#   scale -> voxel remesh -> base trim -> hollow -> decimate
# Remeshing before scaling makes the voxel size a meaningless unit.

import math
import sys

import bpy

argv = sys.argv[sys.argv.index("--") + 1:]
MESH_IN, STL_OUT = argv[0], argv[1]
HEIGHT, VOXEL, BASE_TRIM, HOLLOW = map(float, argv[2:6])
DECIMATE = int(argv[6])
ROTATE_X = float(argv[7])


def marker(k, v):
    print(f"PRINTPREP {k} = {v}", flush=True)


# ── clean scene, import ─────────────────────────────────────
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete()

low = MESH_IN.lower()
if low.endswith((".glb", ".gltf")):
    bpy.ops.import_scene.gltf(filepath=MESH_IN)
elif low.endswith(".stl"):
    bpy.ops.wm.stl_import(filepath=MESH_IN)
elif low.endswith(".obj"):
    bpy.ops.wm.obj_import(filepath=MESH_IN)
elif low.endswith(".ply"):
    bpy.ops.wm.ply_import(filepath=MESH_IN)
else:
    raise SystemExit(f"unsupported input format: {MESH_IN}")

# keep only mesh objects, join into one
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
if not meshes:
    raise SystemExit("no mesh objects in input")
for o in bpy.context.scene.objects:
    o.select_set(o.type == "MESH")
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
obj = bpy.context.active_object
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
marker("tris_in", len(obj.data.polygons))

# ── orient ──────────────────────────────────────────────────
if ROTATE_X:
    obj.rotation_euler[0] = math.radians(ROTATE_X)
    bpy.ops.object.transform_apply(rotation=True)

# ── 1. scale: bbox Z -> HEIGHT mm (1 blender unit = 1 mm) ───
zs = [v.co.z for v in obj.data.vertices]
span = max(zs) - min(zs)
if span <= 0:
    raise SystemExit("degenerate input: zero height")
s = HEIGHT / span
obj.scale = (s, s, s)
bpy.ops.object.transform_apply(scale=True)

# ── 2. voxel remesh (mandatory: guarantees manifold) ────────
rm = obj.modifiers.new("remesh", "REMESH")
rm.mode = "VOXEL"
rm.voxel_size = VOXEL
bpy.ops.object.modifier_apply(modifier=rm.name)
marker("tris_after_remesh", len(obj.data.polygons))

# rest on the build plate: min Z = 0
minz = min(v.co.z for v in obj.data.vertices)
obj.location.z -= minz
bpy.ops.object.transform_apply(location=True)

# ── 3. base trim: exact-boolean a cutter box below z=BASE_TRIM ──
# (boolean keeps the mesh closed; a bisect+fill does not reliably)
if BASE_TRIM > 0:
    from mathutils import Vector
    bb = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    cx = sum(v.x for v in bb) / 8
    cy = sum(v.y for v in bb) / 8
    span = max(max(v.x for v in bb) - min(v.x for v in bb),
               max(v.y for v in bb) - min(v.y for v in bb)) * 2 + 20
    bpy.ops.mesh.primitive_cube_add(size=1)
    cutter = bpy.context.active_object
    depth = BASE_TRIM + 50
    cutter.scale = (span, span, depth)
    cutter.location = (cx, cy, BASE_TRIM - depth / 2)
    bpy.context.view_layer.objects.active = obj
    bo = obj.modifiers.new("basetrim", "BOOLEAN")
    bo.operation = "DIFFERENCE"
    bo.solver = "EXACT"
    bo.object = cutter
    bpy.ops.object.modifier_apply(modifier=bo.name)
    bpy.data.objects.remove(cutter, do_unlink=True)
    minz = min(v.co.z for v in obj.data.vertices)
    obj.location.z -= minz
    bpy.ops.object.transform_apply(location=True)

# ── 4. hollow (optional): boolean-subtract an eroded copy ───
if HOLLOW > 0:
    bpy.ops.object.duplicate()
    inner = bpy.context.active_object
    disp = inner.modifiers.new("erode", "DISPLACE")
    disp.mid_level = 0.0
    disp.strength = -HOLLOW
    bpy.ops.object.modifier_apply(modifier=disp.name)
    rm2 = inner.modifiers.new("remesh2", "REMESH")
    rm2.mode = "VOXEL"
    rm2.voxel_size = VOXEL
    bpy.ops.object.modifier_apply(modifier=rm2.name)
    bpy.context.view_layer.objects.active = obj
    bo = obj.modifiers.new("hollow", "BOOLEAN")
    bo.operation = "DIFFERENCE"
    bo.object = inner
    bpy.ops.object.modifier_apply(modifier=bo.name)
    bpy.data.objects.remove(inner, do_unlink=True)
    marker("hollow_wall_mm", HOLLOW)

# ── 5. decimate (optional) ──────────────────────────────────
if DECIMATE > 0 and len(obj.data.polygons) > DECIMATE:
    dec = obj.modifiers.new("decimate", "DECIMATE")
    dec.ratio = DECIMATE / len(obj.data.polygons)
    bpy.ops.object.modifier_apply(modifier=dec.name)

marker("tris_out", len(obj.data.polygons))

# ── export: wm.stl_export (the only STL operator on Blender >= 4.1) ──
obj.select_set(True)
bpy.ops.wm.stl_export(filepath=STL_OUT, export_selected_objects=True,
                      ascii_format=False)
marker("stl", STL_OUT)
