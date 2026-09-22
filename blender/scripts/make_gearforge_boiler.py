"""Gearforge boiler house: industrial building with tall chimney.
Generates:
  blender/source/gearforge_boiler_house.blend
  blender/exports/gearforge_boiler_house.glb
Conventions: metric 1unit=1m, -Z forward +Y up, origin ground center,
snake_case, Principled BSDF only. Footprint ~8x6m, chimney top ~9m.
Run: blender --background --python blender/scripts/make_gearforge_boiler.py
"""
import math
import os

import bpy

ASSET = "gearforge_boiler_house"
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


def make_pbr(name, base_color, metallic=0.6, roughness=0.5, emission_color=None, emission_strength=0.0):
    mat = bpy.data.materials.new(name=name + "_mat")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        if "Base Color" in bsdf.inputs:
            bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
        if "Metallic" in bsdf.inputs:
            bsdf.inputs["Metallic"].default_value = metallic
        if "Roughness" in bsdf.inputs:
            bsdf.inputs["Roughness"].default_value = roughness
        if emission_color is not None:
            if "Emission Color" in bsdf.inputs:
                bsdf.inputs["Emission Color"].default_value = (*emission_color, 1.0)
            elif "Emission" in bsdf.inputs:
                try:
                    bsdf.inputs["Emission"].default_value = (*emission_color, 1.0)
                except Exception:
                    pass
            if "Emission Strength" in bsdf.inputs:
                bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat


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

    iron = make_pbr(ASSET + "_iron", (0.23, 0.24, 0.28), 0.7, 0.6)
    brass = make_pbr(ASSET + "_brass", (0.60, 0.44, 0.20), 0.85, 0.4)
    copper = make_pbr(ASSET + "_copper", (0.70, 0.36, 0.18), 0.8, 0.45)
    brick = make_pbr(ASSET + "_brick", (0.42, 0.26, 0.20), 0.1, 0.9)
    glow = make_pbr(ASSET + "_glow", (0.20, 0.45, 1.0), 0.0, 0.4,
                    emission_color=(0.20, 0.45, 1.0), emission_strength=2.0)
    furnace = make_pbr(ASSET + "_furnace", (1.0, 0.55, 0.20), 0.0, 0.4,
                       emission_color=(1.0, 0.5, 0.15), emission_strength=2.2)

    box(ASSET + "_pad", (9.0, 0.3, 7.0), (0, 0, 0.15), brick)
    box(ASSET + "_hall", (6.4, 3.0, 5.0), (-0.6, 0, 1.8), brick)
    box(ASSET + "_roof", (6.8, 0.3, 5.4), (-0.6, 0, 3.45), iron)
    box(ASSET + "_roof_trim", (7.0, 0.18, 5.6), (-0.6, 0, 3.2), brass)

    # Tall chimney (main steam/smoke anchor)
    cylinder(ASSET + "_chimney", radius=0.55, depth=6.0, loc=(2.2, 0, 6.0), mat=iron, vertices=12)
    cylinder(ASSET + "_chimney_band_a", radius=0.65, depth=0.25, loc=(2.2, 0, 4.5), mat=brass, vertices=12)
    cylinder(ASSET + "_chimney_band_b", radius=0.65, depth=0.25, loc=(2.2, 0, 7.0), mat=brass, vertices=12)
    cylinder(ASSET + "_chimney_lip", radius=0.62, depth=0.3, loc=(2.2, 0, 9.1), mat=furnace, vertices=12)

    # Boiler tanks
    for i, tx in enumerate((-1.8, 0.2)):
        tank = cylinder(ASSET + "_tank_%d" % i, radius=0.85, depth=2.4,
                        loc=(tx, 1.8, 1.2), mat=copper, vertices=12)
        tank.rotation_euler = (math.radians(90), 0, 0)
        bpy.context.view_layer.objects.active = tank
        bpy.ops.object.transform_apply(rotation=True)

    # Furnace mouth (warm glow, readable at distance)
    box(ASSET + "_furnace_mouth", (1.4, 0.15, 1.0), (-0.6, -2.55, 0.9), furnace)
    box(ASSET + "_furnace_frame", (1.8, 0.12, 1.4), (-0.6, -2.52, 0.9), iron)

    # Pipes: vertical + horizontal run
    cylinder(ASSET + "_pipe_v", radius=0.13, depth=3.2, loc=(-3.2, 1.0, 1.8), mat=copper, vertices=8)
    pipe_h = cylinder(ASSET + "_pipe_h", radius=0.13, depth=5.5, loc=(-1.0, 1.0, 3.3), mat=copper, vertices=8)
    pipe_h.rotation_euler = (0, math.radians(90), 0)
    bpy.context.view_layer.objects.active = pipe_h
    bpy.ops.object.transform_apply(rotation=True)

    # Faction lamp posts (blue glow markers)
    for px in (-3.8, 2.6):
        cylinder(ASSET + "_lamp_pole_%d" % int(px * 10), radius=0.07, depth=2.6,
                 loc=(px, 0, -3.0), mat=iron, vertices=8)
        box(ASSET + "_lamp_head_%d" % int(px * 10), (0.35, 0.35, 0.35), (px, 0, 2.9), glow)

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
