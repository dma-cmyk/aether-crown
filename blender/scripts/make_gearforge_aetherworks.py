"""Gearforge aether works: Aether Works District production asset (Phase 2.5A).
Stone base, iron tower, Aether core with brass cup, coil rings, copper
conduits, ground ring marker. Cyan emissive identity, arcane-industrial
silhouette distinct from civic/industry assets.
Generates:
  blender/source/gearforge_aether_works.blend
  blender/exports/gearforge_aether_works.glb
Conventions: metric 1unit=1m, Blender Z-up (footprint X/Y, height Z),
origin ground center, snake_case, shared material_lib palette.
Footprint ~8.5x8.5m, core top ~9m.
Run: blender --background --python blender/scripts/make_gearforge_aetherworks.py
"""
import math
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import material_lib

ASSET = "gearforge_aether_works"
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
    box(ASSET + "_pad", (8.5, 8.5, 0.3), (0, 0, 0.15), m["stone"])
    cylinder(ASSET + "_base", 2.2, 1.2, (0, 0, 0.9), m["stone"], vertices=16)
    cylinder(ASSET + "_base_trim", 2.32, 0.25, (0, 0, 1.4), m["brass"], vertices=16)

    # Iron tower + brass bands + coil rings (torus, flat in XY = horizontal).
    cylinder(ASSET + "_tower", 1.1, 5.5, (0, 0, 4.25), m["dark_iron"], vertices=12)
    cylinder(ASSET + "_tower_band", 1.2, 0.3, (0, 0, 2.6), m["brass"])
    for i, cz in enumerate((3.4, 4.6, 5.8)):
        bpy.ops.mesh.primitive_torus_add(location=(0, 0, cz), major_radius=1.35, minor_radius=0.15,
                                         major_segments=16, minor_segments=8)
        coil = bpy.context.active_object
        coil.name = ASSET + "_coil_%d" % i
        coil.data.materials.append(m["copper"])

    # Brass cup + Aether core (emissive icosphere, main glow anchor).
    cylinder(ASSET + "_cup", 0.6, 0.5, (0, 0, 7.2), m["brass"])
    bpy.ops.mesh.primitive_ico_sphere_add(radius=0.9, subdivisions=1, location=(0, 0, 8.1))
    core = bpy.context.active_object
    core.name = ASSET + "_core"
    core.data.materials.append(m["aether_glow"])

    # Copper conduits (4 posts with aether strip lights, grounded on pad).
    for px, py in ((-3.0, -3.0), (3.0, -3.0), (-3.0, 3.0), (3.0, 3.0)):
        cylinder(ASSET + "_conduit_%d_%d" % (int(px * 10), int(py * 10)),
                 0.12, 2.4, (px, py, 1.5), m["copper"], vertices=8)
        box(ASSET + "_strip_%d_%d" % (int(px * 10), int(py * 10)),
            (0.2, 0.2, 1.2), (px, py, 2.4), m["aether_glow"])

    # Ground ring marker (flat torus, cyan identity readable at distance).
    bpy.ops.mesh.primitive_torus_add(location=(0, 0, 0.35), major_radius=2.9, minor_radius=0.14,
                                     major_segments=24, minor_segments=8)
    ring = bpy.context.active_object
    ring.name = ASSET + "_ring"
    ring.data.materials.append(m["aether_glow"])

    # Side shed (iron + copper pipe stub, grounds the composition).
    box(ASSET + "_shed", (2.2, 1.8, 1.6), (-3.0, 1.5, 1.1), m["dark_iron"])
    box(ASSET + "_shed_roof", (2.5, 2.1, 0.2), (-3.0, 1.5, 2.0), m["brass"])
    cylinder(ASSET + "_shed_pipe", 0.12, 1.8, (-2.2, 1.5, 1.2), m["copper"], vertices=8)

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
        export_normals=True,
        export_materials="EXPORT",
        export_animations=False,
    )
    print(f"EXPORT_GLB_OK {EXPORT_GLB}")


if __name__ == "__main__":
    main()
