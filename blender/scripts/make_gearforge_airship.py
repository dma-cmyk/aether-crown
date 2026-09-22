"""Gearforge airship: steam balloon cruiser.
Generates:
  blender/source/gearforge_airship.blend
  blender/exports/gearforge_airship.glb
Conventions: metric 1unit=1m. Blender space: X right, Y depth
(front = -Y), Z up. Export maps Blender -Y front to Godot +Z,
matching VisualAirship facing. Origin at gondola center
(flying vehicle exception to ground-origin rule; documented here).
Envelope ~9m long horizontal, total height envelope-top to keel ~6m.
Run: blender --background --python blender/scripts/make_gearforge_airship.py
"""
import math
import os

import bpy

ASSET = "gearforge_airship"
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
    if rot is not None:
        bpy.ops.object.transform_apply(rotation=True)
    bpy.ops.object.transform_apply(scale=True)
    if mat is not None:
        o.data.materials.append(mat)
    return o


def cylinder(name, radius, depth, loc, mat, vertices=12, rot=None):
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

    canvas = make_pbr(ASSET + "_canvas", (0.55, 0.48, 0.36), 0.1, 0.85)
    iron = make_pbr(ASSET + "_iron", (0.24, 0.25, 0.29), 0.75, 0.55)
    brass = make_pbr(ASSET + "_brass", (0.62, 0.46, 0.20), 0.85, 0.38)
    wood = make_pbr(ASSET + "_wood", (0.36, 0.25, 0.15), 0.1, 0.9)
    glow = make_pbr(ASSET + "_glow", (0.20, 0.50, 1.0), 0.0, 0.4,
                    emission_color=(0.20, 0.50, 1.0), emission_strength=2.5)
    heat = make_pbr(ASSET + "_heat", (1.0, 0.65, 0.25), 0.0, 0.4,
                    emission_color=(1.0, 0.6, 0.2), emission_strength=1.8)

    # Envelope: stretched UV sphere along Y (length ~9m, radius ~2m),
    # center z=+2.8 above gondola origin. Scale order (X, Y, Z).
    bpy.ops.mesh.primitive_uv_sphere_add(radius=2.0, location=(0, 0, 2.8), segments=16, ring_count=10)
    env = bpy.context.active_object
    env.name = ASSET + "_envelope"
    env.scale = (1.0, 2.25, 1.0)
    bpy.context.view_layer.objects.active = env
    bpy.ops.object.transform_apply(scale=True)
    env.data.materials.append(canvas)

    # Nose cap (front, Blender -Y) + tail spike (rear, Blender +Y)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.7, location=(0, -4.5, 2.8), segments=10, ring_count=6)
    nose = bpy.context.active_object
    nose.name = ASSET + "_nose"
    nose.data.materials.append(brass)
    tail = cylinder(ASSET + "_tail_spike", radius=0.12, depth=1.6, loc=(0, 5.0, 2.8), mat=brass,
                    vertices=8, rot=(math.radians(90), 0, 0))

    # Faction stripe: torus bands around envelope length axis (Blender Y).
    # Torus default encircles Z; rot 90deg about X to encircle Y.
    for y in (-2.5, 0.0, 2.5):
        bpy.ops.mesh.primitive_torus_add(major_radius=2.02, minor_radius=0.12,
                                         location=(0, y, 2.8), major_segments=20, minor_segments=8)
        band = bpy.context.active_object
        band.name = ASSET + "_band_%d" % int((y + 10) * 10)
        band.rotation_euler = (math.radians(90), 0, 0)
        bpy.context.view_layer.objects.active = band
        bpy.ops.object.transform_apply(rotation=True)
        band.data.materials.append(glow)

    # Fins: vertical + horizontal stabilizers at tail (Blender +Y rear)
    box(ASSET + "_fin_v", (0.18, 1.8, 2.6), (0, 3.8, 4.5), brass,
        rot=(math.radians(8), 0, 0))
    box(ASSET + "_fin_h", (2.8, 1.6, 0.18), (0, 3.8, 3.0), brass)

    # Rigging lines: thin vertical cylinders envelope-bottom -> gondola-top (4x)
    for sx in (-0.72, 0.72):
        for sy in (-1.2, 1.2):
            cylinder(ASSET + "_rig_%d_%d" % (int(sx * 10), int((sy + 10) * 10)),
                     radius=0.03, depth=1.2, loc=(sx, sy, 0.75),
                     mat=iron, vertices=6)

    # Gondola (origin): wooden hull, length along Y 3.6, height 1.2
    box(ASSET + "_gondola", (1.6, 3.6, 1.2), (0, 0, 0.0), wood)
    box(ASSET + "_gondola_trim", (1.7, 3.7, 0.25), (0, 0, -0.6), brass)
    # Cabin glow windows (faction identity): 3 strips along length
    for sy in (-1.0, 0.0, 1.0):
        box(ASSET + "_win_%d" % int((sy + 10) * 10), (1.65, 0.5, 0.4), (0, sy, 0.15), glow)
    # Keel gun: small barrel pointing Blender -Y (forward), attached to
    # gondola front-bottom (not floating below).
    cylinder(ASSET + "_keel_gun", radius=0.12, depth=1.4, loc=(0, -2.0, -0.3), mat=iron,
             vertices=8, rot=(math.radians(90), 0, 0))
    # Engine glow (aft furnace, Blender +Y rear)
    box(ASSET + "_engine_glow", (0.8, 0.4, 0.5), (0, 1.9, 0.0), heat)
    # Propellers: two side props at rear, axis along X
    for sx in (-1.0, 1.0):
        cylinder(ASSET + "_prop_hub_%d" % int(sx * 10), radius=0.12, depth=0.4,
                 loc=(sx, 1.5, 0.0), mat=iron, vertices=8,
                 rot=(0, math.radians(90), 0))
        side = 1.0 if sx > 0 else -1.0
        box(ASSET + "_prop_blade_%d" % int(sx * 10), (0.08, 0.25, 1.6), (sx + 0.25 * side, 1.5, 0.0), wood)

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
