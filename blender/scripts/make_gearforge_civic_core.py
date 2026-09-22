"""Gearforge civic core: representative city building (Phase 2.5A).
Art-direction anchor for the production building set: stone base, iron
hall, brass trims, copper boiler, tall chimney, Aether clock dial and
windows, furnace mouth. Readable silhouette at RTS distance.
Generates:
  blender/source/gearforge_civic_core.blend
  blender/exports/gearforge_civic_core.glb
Conventions: metric 1unit=1m, Blender Z-up (footprint X/Y, height Z),
origin ground center, snake_case, shared material_lib palette.
Footprint ~12.5x10.5m, top ~11m.
Run: blender --background --python blender/scripts/make_gearforge_civic_core.py
"""
import math
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import material_lib

ASSET = "gearforge_civic_core"
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SOURCE_BLEND = os.path.join(ROOT, "blender", "source", ASSET + ".blend")
EXPORT_GLB = os.path.join(ROOT, "blender", "exports", ASSET + ".glb")


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.actions):
        for x in list(coll):
            try:
                coll.remove(x)
            except Exception:
                pass


def box(name, size_xyz, loc, mat):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = (size_xyz[0], size_xyz[1], size_xyz[2])
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(scale=True)
    if mat is not None:
        o.data.materials.append(mat)
    return o


def cylinder(name, radius, depth, loc, mat, vertices=12):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, location=loc, vertices=vertices)
    o = bpy.context.active_object
    o.name = name
    if mat is not None:
        o.data.materials.append(mat)
    return o


def main():
    clear_scene()
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0
    m = material_lib.palette()

    # Blender Z-up: footprint X/Y, height Z. Godot converts to Y-up.
    box(ASSET + "_pad", (12.5, 10.5, 0.3), (0, 0, 0.15), m["stone"])
    box(ASSET + "_hall", (8.0, 6.5, 3.8), (0, 0, 2.2), m["stone"])
    box(ASSET + "_hall_band", (8.2, 6.7, 0.3), (0, 0, 3.3), m["brass"])
    box(ASSET + "_roof", (8.6, 7.1, 0.4), (0, 0, 4.3), m["dark_iron"])
    box(ASSET + "_roof_trim", (8.8, 7.3, 0.2), (0, 0, 4.0), m["brass"])

    # Clock tower (south-west of hall center) + brass cap + Aether dial.
    box(ASSET + "_tower", (2.4, 2.4, 7.5), (-2.5, 0.5, 4.05), m["stone"])
    box(ASSET + "_tower_cap", (2.8, 2.8, 0.4), (-2.5, 0.5, 8.0), m["brass"])
    cylinder(ASSET + "_spire", 0.3, 1.6, (-2.5, 0.5, 9.0), m["copper"], vertices=8)
    dial = cylinder(ASSET + "_dial", 0.8, 0.12, (-2.5, -0.76, 6.5), m["aether_glow"], vertices=16)
    dial.rotation_euler = (math.radians(90), 0, 0)
    bpy.context.view_layer.objects.active = dial
    bpy.ops.object.transform_apply(rotation=True)

    # Tall chimney (main smoke anchor) with brass bands + furnace lip.
    cylinder(ASSET + "_chimney", 0.6, 5.0, (2.8, 1.5, 7.0), m["dark_iron"])
    cylinder(ASSET + "_chimney_band_a", 0.7, 0.25, (2.8, 1.5, 5.5), m["brass"])
    cylinder(ASSET + "_chimney_band_b", 0.7, 0.25, (2.8, 1.5, 8.0), m["brass"])
    cylinder(ASSET + "_chimney_lip", 0.67, 0.3, (2.8, 1.5, 9.6), m["furnace_glow"])

    # Copper boiler (east side, axis X, sits on pad top 0.3).
    tank = cylinder(ASSET + "_boiler", 0.9, 2.6, (3.0, -1.8, 1.2), m["copper"])
    tank.rotation_euler = (0, math.radians(90), 0)
    bpy.context.view_layer.objects.active = tank
    bpy.ops.object.transform_apply(rotation=True)

    # East annex with brass roof.
    box(ASSET + "_annex", (2.8, 4.0, 2.2), (5.0, 0.5, 1.4), m["stone"])
    box(ASSET + "_annex_roof", (3.2, 4.4, 0.25), (5.0, 0.5, 2.6), m["brass"])

    # Aether windows (south face) + furnace mouth.
    for wx in (-2.2, 0.0, 2.2):
        box(ASSET + "_window_%d" % int(wx * 10), (1.2, 0.12, 1.4), (wx, -3.28, 2.0), m["aether_glow"])
    box(ASSET + "_furnace_mouth", (1.4, 0.15, 1.0), (0, -3.28, 0.9), m["furnace_glow"])
    box(ASSET + "_furnace_frame", (1.8, 0.12, 1.4), (0, -3.25, 0.9), m["dark_iron"])

    # Copper pipes: vertical west run + horizontal roof run to chimney.
    cylinder(ASSET + "_pipe_v", 0.13, 4.0, (-4.4, 0, 2.3), m["copper"], vertices=8)
    pipe_h = cylinder(ASSET + "_pipe_h", 0.13, 7.0, (-0.8, 0, 4.62), m["copper"], vertices=8)
    pipe_h.rotation_euler = (0, math.radians(90), 0)
    bpy.context.view_layer.objects.active = pipe_h
    bpy.ops.object.transform_apply(rotation=True)

    bpy.ops.object.select_all(action="SELECT")
    os.makedirs(os.path.dirname(SOURCE_BLEND), exist_ok=True)
    os.makedirs(os.path.dirname(EXPORT_GLB), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)
    print(f"SAVE_BLEND_OK {SOURCE_BLEND}")
    bpy.ops.export_scene.gltf(
        filepath=EXPORT_GLB,
        export_format="GLB",
        use_selection=False,
        export_apply=True,
        export_yup=True,
        export_normals=True,
        export_materials="EXPORT",
        export_animations=False,
    )
    print(f"EXPORT_GLB_OK {EXPORT_GLB}")


if __name__ == "__main__":
    main()
