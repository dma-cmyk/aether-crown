"""Gearforge industry works: Industry District production asset (Phase 2.5A).
Factory hall, tall chimney, horizontal boiler, vertical tanks, copper
pipe runs, twin furnace mouths, rust vent accents. Silhouette reads as
heavy machinery at RTS distance, distinct from civic/aether assets.
Generates:
  blender/source/gearforge_industry_works.blend
  blender/exports/gearforge_industry_works.glb
Conventions: metric 1unit=1m, Blender Z-up (footprint X/Y, height Z),
origin ground center, snake_case, shared material_lib palette.
Footprint ~10.5x8.5m, chimney top ~10.5m.
Run: blender --background --python blender/scripts/make_gearforge_industry.py
"""
import math
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import material_lib

ASSET = "gearforge_industry_works"
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
    box(ASSET + "_pad", (10.5, 8.5, 0.3), (0, 0, 0.15), m["stone"])
    box(ASSET + "_hall", (7.0, 5.5, 3.2), (-0.5, 0, 1.9), m["dark_iron"])
    box(ASSET + "_hall_trim", (7.2, 5.7, 0.3), (-0.5, 0, 3.0), m["brass"])
    box(ASSET + "_roof", (7.4, 5.9, 0.35), (-0.5, 0, 3.65), m["steel"])
    # Rust vent accents on the roof (industrial wear, cheap detail).
    box(ASSET + "_vent_a", (1.2, 1.2, 0.7), (-2.5, -1.5, 4.1), m["rust"])
    box(ASSET + "_vent_b", (1.0, 1.0, 0.6), (1.5, 1.5, 4.05), m["rust"])

    # Big chimney (main smoke anchor).
    cylinder(ASSET + "_chimney", 0.75, 7.0, (2.5, 0, 6.9), m["dark_iron"])
    cylinder(ASSET + "_chimney_band_a", 0.86, 0.3, (2.5, 0, 4.6), m["brass"])
    cylinder(ASSET + "_chimney_band_b", 0.86, 0.3, (2.5, 0, 8.4), m["brass"])
    cylinder(ASSET + "_chimney_lip", 0.83, 0.35, (2.5, 0, 10.5), m["furnace_glow"])

    # Horizontal boiler (south side, axis X, sits on pad top 0.3).
    boiler = cylinder(ASSET + "_boiler", 1.0, 3.0, (0, -3.4, 1.3), m["copper"])
    boiler.rotation_euler = (0, math.radians(90), 0)
    bpy.context.view_layer.objects.active = boiler
    bpy.ops.object.transform_apply(rotation=True)
    cylinder(ASSET + "_boiler_cap_a", 1.06, 0.25, (-1.5, -3.4, 1.3), m["brass"])
    cap_a = bpy.context.active_object
    cap_a.rotation_euler = (0, math.radians(90), 0)
    bpy.context.view_layer.objects.active = cap_a
    bpy.ops.object.transform_apply(rotation=True)
    cap_b = cylinder(ASSET + "_boiler_cap_b", 1.06, 0.25, (1.5, -3.4, 1.3), m["brass"])
    cap_b.rotation_euler = (0, math.radians(90), 0)
    bpy.context.view_layer.objects.active = cap_b
    bpy.ops.object.transform_apply(rotation=True)

    # Vertical tanks (north side, grounded on pad).
    for i, tx in enumerate((-2.0, 0.2)):
        cylinder(ASSET + "_tank_%d" % i, 0.8, 2.6, (tx, 3.4, 1.6), m["bronze"])
        cylinder(ASSET + "_tank_lid_%d" % i, 0.86, 0.2, (tx, 3.4, 2.95), m["brass"])

    # Twin furnace mouths (south face, warm glow readable at distance).
    for fx in (-1.8, 0.8):
        box(ASSET + "_furnace_mouth_%d" % int(fx * 10), (1.2, 0.15, 0.9), (fx, -2.8, 0.9), m["furnace_glow"])
        box(ASSET + "_furnace_frame_%d" % int(fx * 10), (1.6, 0.12, 1.3), (fx, -2.77, 0.9), m["dark_iron"])

    # Copper pipe runs: vertical east wall + horizontal roof run.
    cylinder(ASSET + "_pipe_v", 0.14, 3.4, (3.2, 1.0, 2.0), m["copper"], vertices=8)
    pipe_h = cylinder(ASSET + "_pipe_h", 0.14, 5.6, (0.4, 1.0, 3.95), m["copper"], vertices=8)
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
