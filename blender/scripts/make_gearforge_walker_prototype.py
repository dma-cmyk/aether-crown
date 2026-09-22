"""Gearforge Walker prototype (prototype quality, NOT production).

Purpose: scale/atmosphere check for the prototype battlefield scene.
Bipedal gun platform ~4.3m tall: wide ram feet, layered piston legs, hip block,
armored shoulder deck, recoil-mounted top cannon, sensor slit, and paired
exhausts. Kit parts reused where handy.

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
        kit.T.box(f"{ASSET}_foot_{side}", (0.82, 1.28, 0.25), (x, 0.0, 0.13), H, bevel=0.035)
        kit.T.box(f"{ASSET}_toe_{side}", (0.72, 0.38, 0.28), (x, -0.54, 0.32), S, bevel=0.025)
        kit.T.box(f"{ASSET}_heel_{side}", (0.68, 0.30, 0.32), (x, 0.55, 0.31), B, bevel=0.025)
        kit.T.box(f"{ASSET}_shin_{side}", (0.50, 0.56, 1.05), (x, 0.02, 0.75), H, bevel=0.035)
        kit.T.box(f"{ASSET}_shin_plate_{side}", (0.58, 0.16, 0.78), (x, -0.34, 0.78), S, bevel=0.02)
        kit.T.cylinder(f"{ASSET}_knee_{side}", 0.24, 0.6, (x, 0.0, 1.32), B,
                       vertices=8, rot=(0.0, math.radians(90.0), 0.0), bevel=0.0)
        kit.T.box(f"{ASSET}_knee_guard_{side}", (0.54, 0.20, 0.42), (x, -0.37, 1.33), S, bevel=0.02)
        kit.T.box(f"{ASSET}_thigh_{side}", (0.56, 0.62, 0.85), (x, 0.05, 1.75), H, bevel=0.03)
        kit.T.box(f"{ASSET}_thigh_plate_{side}", (0.64, 0.18, 0.54), (x, -0.38, 1.78), S, bevel=0.02)
        kit.T.cylinder_between(f"{ASSET}_piston_{side}", (x, 0.28, 0.5),
                               (x, 0.28, 1.5), 0.07, C, vertices=6, bevel=0.0)
        kit.T.cylinder_between(f"{ASSET}_ankle_ram_{side}", (x - sx * 0.20, -0.22, 0.32),
                               (x - sx * 0.24, -0.18, 1.18), 0.055, C,
                               vertices=6, bevel=0.0)

    kit.T.box(f"{ASSET}_hip", (1.82, 1.0, 0.5), (0.0, 0.03, 2.35), S, bevel=0.04)
    kit.T.box(f"{ASSET}_torso", (1.62, 1.15, 1.1), (0.0, 0.0, 3.1), H, bevel=0.055)
    kit.T.box(f"{ASSET}_shoulder_deck", (2.14, 1.25, 0.24), (0.0, 0.0, 3.57), S, bevel=0.035)
    for sx in (-1.0, 1.0):
        side = "l" if sx < 0 else "r"
        kit.T.box(f"{ASSET}_shoulder_armor_{side}", (0.38, 1.02, 0.72),
                  (sx * 0.92, 0.02, 3.18), S, bevel=0.04)
    kit.T.trapezoid(f"{ASSET}_chest_glacis", (1.34, 0.22), (1.05, 0.16), 0.82,
                    (0.0, -0.65, 3.10), S, bevel=0.025)
    kit.T.box(f"{ASSET}_sensor_brow", (0.92, 0.12, 0.24), (0.0, -0.76, 3.43), B, bevel=0.015)
    kit.T.box(f"{ASSET}_sensor", (0.68, 0.10, 0.15), (0.0, -0.83, 3.41), A, bevel=0.0)
    kit.T.box(f"{ASSET}_belt", (1.6, 1.2, 0.2), (0.0, 0.0, 2.62), B, bevel=0.0)

    # Top-mounted recoil cannon. Broad cradle and counterweight make the gun
    # read as a primary weapon, while its short barrel stays below Titan scale.
    kit.T.cylinder(f"{ASSET}_gun_base", 0.38, 0.46, (0.42, 0.08, 3.82), B,
                   vertices=8, bevel=0.0)
    kit.T.box(f"{ASSET}_gun_shield", (0.94, 0.72, 0.46), (0.42, -0.10, 3.85), H, bevel=0.035)
    kit.T.box(f"{ASSET}_gun_counterweight", (0.70, 0.46, 0.40), (0.42, 0.52, 3.82), S, bevel=0.03)
    kit.T.cylinder(f"{ASSET}_gun", 0.17, 1.70, (0.42, -1.04, 3.88), H,
                   vertices=8, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
    kit.T.cylinder(f"{ASSET}_gun_tip", 0.26, 0.32, (0.42, -1.90, 3.88), B,
                   vertices=8, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
    for gx in (0.18, 0.66):
        kit.T.box(f"{ASSET}_recoil_rail_{int(gx * 100)}", (0.10, 1.20, 0.10),
                  (gx, -0.70, 3.66), C, bevel=0.0)
    kit.T.box(f"{ASSET}_recoil_crossbar", (0.74, 0.12, 0.12), (0.42, -0.92, 3.66), B, bevel=0.0)

    # Paired exhausts and pressure tanks form a compact rear silhouette.
    for sx in (-1.0, 1.0):
        side = "l" if sx < 0 else "r"
        kit.T.cylinder(f"{ASSET}_stack_{side}", 0.13, 0.72, (sx * 0.58, 0.38, 3.91),
                       H, vertices=8, bevel=0.0)
        kit.T.cylinder(f"{ASSET}_stack_lip_{side}", 0.17, 0.12, (sx * 0.58, 0.38, 4.28),
                       B, vertices=8, bevel=0.0)
        kit.T.cylinder(f"{ASSET}_tank_{side}", 0.19, 0.62, (sx * 0.63, 0.18, 3.00),
                       C, vertices=8, bevel=0.0)

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
