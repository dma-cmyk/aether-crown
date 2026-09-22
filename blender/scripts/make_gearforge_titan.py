"""Gearforge titan: steam siege engine, ~10m tall.
Generates:
  blender/source/gearforge_titan.blend
  blender/exports/gearforge_titan.glb
Conventions: metric 1unit=1m, forward -Z, up +Y, origin ground center,
snake_case, Principled BSDF only. Titan budget Mid-High, keep < 8k tris
by using low segment counts. No fine detail invisible from RTS camera.
Cannon points -Z. Muzzle anchor: empty object `muzzle` at barrel tip.
Run: blender --background --python blender/scripts/make_gearforge_titan.py
"""
import math
import os

import bpy

ASSET = "gearforge_titan"
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


def box(name, size_xyz, loc, mat, rot=None):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    o = bpy.context.active_object
    o.name = name
    if rot is not None:
        o.rotation_euler = rot
    o.scale = (size_xyz[0], size_xyz[1], size_xyz[2])
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(rotation=True)
    bpy.ops.object.transform_apply(scale=True)
    if mat is not None:
        o.data.materials.append(mat)
    return o


def cylinder(name, radius, depth, loc, mat, vertices=10, rot=None):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, location=loc, vertices=vertices)
    o = bpy.context.active_object
    o.name = name
    if rot is not None:
        o.rotation_euler = rot
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.transform_apply(rotation=True)
    if mat is not None:
        o.data.materials.append(mat)
    return o


def main():
    clear_scene()
    bpy.context.scene.unit_settings.system = "METRIC"
    bpy.context.scene.unit_settings.scale_length = 1.0

    iron = make_pbr(ASSET + "_iron", (0.24, 0.25, 0.29), 0.75, 0.55)
    brass = make_pbr(ASSET + "_brass", (0.62, 0.46, 0.20), 0.85, 0.38)
    copper = make_pbr(ASSET + "_copper", (0.70, 0.36, 0.18), 0.8, 0.45)
    dark = make_pbr(ASSET + "_dark", (0.12, 0.12, 0.14), 0.5, 0.8)
    glow = make_pbr(ASSET + "_glow", (0.20, 0.50, 1.0), 0.0, 0.4,
                    emission_color=(0.20, 0.50, 1.0), emission_strength=2.5)
    heat = make_pbr(ASSET + "_heat", (1.0, 0.55, 0.20), 0.0, 0.4,
                    emission_color=(1.0, 0.5, 0.15), emission_strength=2.0)

    # Legs: two mech legs (feet at y~0, hips at y~3.4)
    for sx in (-1.4, 1.4):
        box(ASSET + "_foot_%d" % int(sx * 10), (1.6, 0.5, 2.4), (sx, 0, 0.3), dark)
        box(ASSET + "_shin_%d" % int(sx * 10), (0.9, 0.9, 2.2), (sx, 0, 1.6), iron)
        box(ASSET + "_knee_%d" % int(sx * 10), (1.1, 1.1, 0.6), (sx, 0, 2.8), brass)
        box(ASSET + "_thigh_%d" % int(sx * 10), (1.0, 1.0, 1.6), (sx, 0, 3.6), iron)
        cylinder(ASSET + "_piston_%d" % int(sx * 10), radius=0.14, depth=1.8,
                 loc=(sx, 0.65, 2.2), mat=copper, vertices=8)

    # Hip platform + hull
    box(ASSET + "_hips", (4.2, 1.0, 3.0), (0, 0, 4.6), iron)
    box(ASSET + "_hull", (3.6, 2.2, 2.8), (0, 0, 6.0), brass)
    box(ASSET + "_hull_trim", (3.8, 0.25, 3.0), (0, 0, 5.0), iron)
    # Front armor prow (silhouette wedge, -Z face)
    box(ASSET + "_prow", (2.4, 1.6, 0.8), (0, -1.6, 5.8), iron,
        rot=(math.radians(-12), 0, 0))

    # Boiler + chimney (steam identity)
    boiler = cylinder(ASSET + "_boiler", radius=0.9, depth=2.2, loc=(-1.0, 0, 7.4),
                      mat=copper, vertices=12, rot=(0, 0, math.radians(90)))
    cylinder(ASSET + "_stack", radius=0.32, depth=1.8, loc=(1.2, 0, 8.0), mat=iron, vertices=10)
    cylinder(ASSET + "_stack_lip", radius=0.4, depth=0.25, loc=(1.2, 0, 9.0), mat=heat, vertices=10)

    # Cabin with faction glow windows
    box(ASSET + "_cabin", (2.2, 1.6, 1.8), (0, 0.2, 7.6), iron)
    box(ASSET + "_cabin_glow", (1.8, 0.1, 0.6), (0, -0.65, 7.5), glow)

    # Side sponson guns (short barrels, silhouette width)
    for sx in (-2.2, 2.2):
        gun = cylinder(ASSET + "_sponson_%d" % int(sx * 10), radius=0.18, depth=1.8,
                       loc=(sx, 0, 5.6), mat=dark, vertices=8,
                       rot=(math.radians(90), 0, 0))

    # MAIN CANNON along -Z at y~5.6: breech + long barrel, tip at z ~ -5.2
    box(ASSET + "_breech", (1.2, 1.2, 1.6), (0, 0.4, 4.6), dark)
    barrel = cylinder(ASSET + "_barrel", radius=0.32, depth=4.6, loc=(0, 0, 1.6),
                      mat=iron, vertices=12, rot=(math.radians(90), 0, 0))
    cylinder(ASSET + "_barrel_ring_a", radius=0.42, depth=0.3, loc=(0, 0, 0.6), mat=brass, vertices=12,
             rot=(math.radians(90), 0, 0))
    cylinder(ASSET + "_barrel_ring_b", radius=0.42, depth=0.3, loc=(0, 0, 2.6), mat=brass, vertices=12,
             rot=(math.radians(90), 0, 0))
    # Muzzle brake (heat glow ring near tip)
    cylinder(ASSET + "_muzzle_brake", radius=0.45, depth=0.5, loc=(0, 0, -0.5), mat=heat, vertices=12,
             rot=(math.radians(90), 0, 0))

    # Faction banner plates (blue glow, both flanks)
    for sx in (-1.85, 1.85):
        plate = box(ASSET + "_plate_%d" % int(sx * 10), (0.1, 1.2, 1.6), (sx, 0, 6.0), glow)

    # Muzzle anchor empty at barrel tip (Godot reads world pos for FX spawn)
    bpy.ops.object.empty_add(type="PLAIN_AXES", location=(0, 0, -0.9))
    muzzle = bpy.context.active_object
    muzzle.name = "muzzle"
    muzzle.empty_display_size = 0.5

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
