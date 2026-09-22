"""Gearforge Walker prototype (prototype quality, NOT production).

Purpose: scale/atmosphere check for the prototype battlefield scene.
Bipedal gun platform ~4.2m tall: wide feet, piston legs, hip block,
armored torso, top cannon, sensor slit. Kit parts reused where handy.

Footprint ~2.6x2.2m, height ~4.2m. Origin ground centre, front -Y.
"""
import math
import os
import sys

SCRIPT_DIR = os.path.abspath(os.path.dirname(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

import bpy  # noqa: E402
from building_kit import kit  # noqa: E402
from material_lib import palette  # noqa: E402

ASSET = "gearforge_walker_prototype"
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SOURCE_BLEND = os.path.join(ROOT, "blender", "source", ASSET + ".blend")
EXPORT_GLB = os.path.join(ROOT, "blender", "exports", ASSET + ".glb")


def main():
    kit.T.clear_scene()
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene["asset_name"] = ASSET
    scene["forward_axis"] = "-Y"
    scene["texture_count"] = 0
    scene["prototype"] = True
    full = palette("gearforge")
    mats = {k: full[k] for k in (
        "dark_iron", "steel", "brass", "copper", "aether_glow")}
    H, S, B, C, A = (mats["dark_iron"], mats["steel"], mats["brass"],
                     mats["copper"], mats["aether_glow"])

    for sx in (-1.0, 1.0):
        side = "l" if sx < 0 else "r"
        x = sx * 0.62
        kit.T.box(f"{ASSET}_foot_{side}", (0.72, 1.15, 0.25), (x, 0.0, 0.13), H, bevel=0.02)
        kit.T.box(f"{ASSET}_shin_{side}", (0.42, 0.5, 1.05), (x, 0.02, 0.75), H, bevel=0.02)
        kit.T.cylinder(f"{ASSET}_knee_{side}", 0.24, 0.6, (x, 0.0, 1.32), B,
                       vertices=8, rot=(0.0, math.radians(90.0), 0.0), bevel=0.0)
        kit.T.box(f"{ASSET}_thigh_{side}", (0.5, 0.55, 0.85), (x, 0.05, 1.75), H, bevel=0.02)
        kit.T.cylinder_between(f"{ASSET}_piston_{side}", (x, 0.28, 0.5),
                               (x, 0.28, 1.5), 0.07, C, vertices=6, bevel=0.0)

    kit.T.box(f"{ASSET}_hip", (1.7, 0.9, 0.5), (0.0, 0.03, 2.35), S, bevel=0.03)
    kit.T.box(f"{ASSET}_torso", (1.5, 1.1, 1.1), (0.0, 0.0, 3.1), H, bevel=0.04)
    kit.T.box(f"{ASSET}_chest_plate", (1.2, 0.18, 0.8), (0.0, -0.6, 3.1), S, bevel=0.02)
    kit.T.box(f"{ASSET}_sensor", (0.6, 0.1, 0.16), (0.0, -0.62, 3.45), A, bevel=0.0)
    kit.T.box(f"{ASSET}_belt", (1.6, 1.2, 0.2), (0.0, 0.0, 2.62), B, bevel=0.0)

    # Top-mounted short cannon pointing forward (-Y).
    kit.T.cylinder(f"{ASSET}_gun_base", 0.3, 0.4, (0.45, 0.1, 3.75), B,
                   vertices=8, bevel=0.0)
    kit.T.cylinder(f"{ASSET}_gun", 0.14, 1.5, (0.45, -0.75, 3.85), H,
                   vertices=8, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
    kit.T.cylinder(f"{ASSET}_gun_tip", 0.2, 0.25, (0.45, -1.5, 3.85), B,
                   vertices=8, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)

    # Rear exhaust stack + side tanks.
    kit.T.cylinder(f"{ASSET}_stack", 0.14, 0.9, (-0.5, 0.35, 3.9), H, vertices=8, bevel=0.0)
    kit.T.cylinder(f"{ASSET}_tank", 0.22, 0.7, (-0.55, 0.1, 3.0), C, vertices=8, bevel=0.0)

    kit.join_by_material(mats, ASSET)
    stats = kit.T.mesh_stats()
    for key, val in zip(("mesh_count", "vertex_count", "polygon_count",
                         "triangle_count", "material_count"), stats):
        scene[key] = val
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)
    print("SAVE_BLEND_OK", SOURCE_BLEND)
    bpy.ops.export_scene.gltf(
        filepath=EXPORT_GLB, export_format="GLB", use_selection=False,
        export_apply=True, export_yup=True, export_normals=True,
        export_materials="EXPORT", export_animations=False)
    print("EXPORT_GLB_OK", EXPORT_GLB, os.path.getsize(EXPORT_GLB), "bytes")


if __name__ == "__main__":
    main()
