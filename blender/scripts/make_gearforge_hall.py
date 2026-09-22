"""Gearforge civic hall: central city building for visual slice.
Generates:
  blender/source/gearforge_civic_hall.blend
  blender/exports/gearforge_civic_hall.glb
Conventions: metric 1unit=1m, -Z forward +Y up, origin ground center,
snake_case, Principled BSDF only. No invisible detail (RTS distance).
Footprint ~12x10m, height ~9m with clock tower ~11m.
Run: blender --background --python blender/scripts/make_gearforge_hall.py
"""
import math
import os

import bpy

ASSET = "gearforge_civic_hall"
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


def setup_units():
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0


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
    setup_units()

    brass = make_pbr(ASSET + "_brass", (0.62, 0.46, 0.20), 0.85, 0.38)
    iron = make_pbr(ASSET + "_iron", (0.22, 0.23, 0.27), 0.7, 0.6)
    copper = make_pbr(ASSET + "_copper", (0.70, 0.36, 0.18), 0.8, 0.45)
    stone = make_pbr(ASSET + "_stone", (0.32, 0.31, 0.30), 0.1, 0.9)
    glow_blue = make_pbr(ASSET + "_glow", (0.20, 0.45, 1.0), 0.0, 0.4,
                         emission_color=(0.20, 0.45, 1.0), emission_strength=2.0)
    glass_warm = make_pbr(ASSET + "_glass", (1.0, 0.80, 0.42), 0.0, 0.35,
                          emission_color=(1.0, 0.75, 0.35), emission_strength=1.6)

    # Base pad (ground slab, origin = ground center)
    box(ASSET + "_pad", (13.0, 0.3, 11.0), (0, 0, 0.15), stone)
    box(ASSET + "_pad_trim", (13.2, 0.12, 11.2), (0, 0, 0.32), iron)

    # Main hall body
    box(ASSET + "_hall", (8.0, 3.6, 6.4), (-1.0, 0, 2.1), brass)
    # Side annex (boiler wing)
    box(ASSET + "_annex", (3.4, 2.6, 4.6), (3.6, 0, 1.55), copper)
    # Roof: rotated cube as simple gable (cheap, RTS-readable)
    roof = box(ASSET + "_roof", (8.6, 0.35, 7.0), (-1.0, 0, 4.05), iron)
    roof.rotation_euler = (0, 0, 0)
    ridge = box(ASSET + "_ridge", (8.8, 1.1, 1.2), (-1.0, 0, 4.6), iron)

    # Clock / gear tower (tall silhouette element)
    box(ASSET + "_tower", (2.6, 2.6, 7.5), (-4.2, 0, 3.9), stone)
    box(ASSET + "_tower_cap", (3.0, 3.0, 0.5), (-4.2, 0, 7.85), iron)
    box(ASSET + "_tower_top", (1.6, 1.6, 1.6), (-4.2, 0, 8.9), brass)
    # Tower glow dial (faction color, emissive)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.8, depth=0.15, location=(-4.2, -1.35, 6.4), vertices=16)
    dial = bpy.context.active_object
    dial.name = ASSET + "_dial"
    dial.rotation_euler = (math.radians(90), 0, 0)
    bpy.context.view_layer.objects.active = dial
    bpy.ops.object.transform_apply(rotation=True)
    dial.data.materials.append(glow_blue)

    # Chimney on annex (steam source anchor; actual smoke is Godot particles)
    cylinder(ASSET + "_stack", radius=0.45, depth=3.4, loc=(3.6, 0, 4.6), mat=iron, vertices=12)
    cylinder(ASSET + "_stack_lip", radius=0.55, depth=0.3, loc=(3.6, 0, 6.4), mat=glow_blue, vertices=12)

    # Horizontal boiler tank on annex side
    tank = cylinder(ASSET + "_tank", radius=0.9, depth=2.8, loc=(3.6, 2.6, 1.4), mat=copper, vertices=14)
    tank.rotation_euler = (math.radians(90), 0, 0)
    bpy.context.view_layer.objects.active = tank
    bpy.ops.object.transform_apply(rotation=True)

    # Windows: warm emissive slits on front (-Z face)
    for wx in (-3.2, -1.6, 0.0, 1.4):
        box(ASSET + "_window_%d" % int((wx + 10) * 10), (0.9, 0.1, 0.7), (wx, -3.22, 2.2), glass_warm)

    # Faction banner poles + glow banners
    for px in (-6.0, 6.0):
        cylinder(ASSET + "_pole_%d" % int(px * 10), radius=0.08, depth=5.0,
                 loc=(px, 0, -4.2), mat=iron, vertices=8)
        box(ASSET + "_banner_%d" % int(px * 10), (1.0, 0.08, 1.5), (px, 0, 6.2), glow_blue)

    # Pipes along hall side
    pipe = cylinder(ASSET + "_pipe", radius=0.14, depth=7.0, loc=(-1.0, 3.35, 1.0), mat=copper, vertices=8)
    pipe.rotation_euler = (0, math.radians(90), 0)
    bpy.context.view_layer.objects.active = pipe
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
