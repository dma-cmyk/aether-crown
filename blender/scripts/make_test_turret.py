"""Pipeline test model: simple steam-style turret (low poly).
Generates:
  blender/source/gearforge_turret_test.blend
  blender/exports/gearforge_turret_test.glb
Conventions: metric, 1 unit=1m, -Z forward +Y up, origin at ground center,
snake_case, Principled BSDF PBR.
Run: blender --background --python blender/scripts/make_test_turret.py
"""
import math
import os

import bpy

ASSET = "gearforge_turret_test"

# Resolve project root from this script location: <root>/blender/scripts/xxx.py
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SOURCE_BLEND = os.path.join(ROOT, "blender", "source", ASSET + ".blend")
EXPORT_GLB = os.path.join(ROOT, "blender", "exports", ASSET + ".glb")


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    # purge orphan data
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


def make_pbr(name, base_color, metallic=0.6, roughness=0.5):
    mat = bpy.data.materials.new(name=name + "_mat")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


def box(name, size, loc, mat):
    bpy.ops.mesh.primitive_cube_add(size=size, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(mat)
    return o


def cylinder(name, radius, depth, loc, mat, vertices=16):
    bpy.ops.mesh.primitive_cylinder_add(
        radius=radius, depth=depth, location=loc, vertices=vertices
    )
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(mat)
    return o


def main():
    clear_scene()
    setup_units()

    brass = make_pbr("gearforge_turret_test_brass", (0.72, 0.53, 0.20), 0.85, 0.35)
    iron = make_pbr("gearforge_turret_test_iron", (0.22, 0.24, 0.28), 0.7, 0.55)

    # Base: low cylinder at ground (origin = ground center)
    base = cylinder(ASSET + "_base", radius=1.0, depth=0.3, loc=(0, 0, 0.15), mat=iron)
    # Body: box turret head
    head = box(ASSET + "_head", size=1.0, loc=(0, 0, 0.9), mat=brass)
    head.scale = (1.2, 1.2, 0.7)
    bpy.context.view_layer.objects.active = head
    bpy.ops.object.transform_apply(scale=True)
    # Barrel: cylinder rotated to point -Z? Godot forward is -Z; keep barrel along +Y then rotate.
    bpy.ops.mesh.primitive_cylinder_add(radius=0.12, depth=1.6, location=(0, 0, 1.0), vertices=12)
    barrel = bpy.context.active_object
    barrel.name = ASSET + "_barrel"
    barrel.data.materials.append(iron)
    barrel.rotation_euler = (math.radians(90), 0, 0)
    barrel.location = (0, -0.9, 1.0)
    bpy.context.view_layer.objects.active = barrel
    bpy.ops.object.transform_apply(rotation=True)
    # Chimney: small stack (steam flavor)
    chimney = cylinder(ASSET + "_stack", radius=0.15, depth=0.7, loc=(0.4, 0.4, 1.4), mat=iron, vertices=10)

    # Parent head parts to base for a trivial "rig" (object-level, no armature needed for test)
    for o in (head, barrel, chimney):
        o.parent = base
        # keep world transform
        o.matrix_parent_inverse = base.matrix_world.inverted()

    # Simple idle animation: rotate base 360deg over 120 frames (proves NLA/animation export path)
    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = 120
    base.rotation_mode = "XYZ"
    base.rotation_euler = (0, 0, 0)
    base.keyframe_insert(data_path="rotation_euler", frame=1)
    base.rotation_euler = (0, 0, math.radians(360))
    base.keyframe_insert(data_path="rotation_euler", frame=120)
    # NOTE: Blender 5.x uses layered Actions; keep default interpolation.
    # Linear tweak is optional and skipped for version compatibility.

    # Ensure selection for export, apply transforms where safe
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
        export_animations=True,
    )
    print(f"EXPORT_GLB_OK {EXPORT_GLB}")


if __name__ == "__main__":
    main()
