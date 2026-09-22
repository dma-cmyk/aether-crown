"""Build the Gearforge Ironstride LOD1 (RTS-distance) Walker.

Outputs:
  blender/source/gearforge_walker_lod1.blend
  blender/exports/gearforge_walker_lod1.glb

LOD1 keeps the LOD0 structure (4 functional groups + 4 pivots) and
silhouette (A-frame digitigrade legs, low wide hull, recoil cannon,
rear exhausts, faction plate) while cutting RTS-invisible detail:
foot claws/spurs/cleats/bolts, shin ribs, secondary rams, hull strakes,
smoke halved, hatches/steps skipped, segments 14/12/10/8 -> 10/8/6.
Anchors and pivots keep LOD0 names/positions/meaning. LOD0 untouched.

Stations and helpers are reused from make_gearforge_walker.py
(no duplication).

Target: 4 meshes / ~1,800-2,200 triangles / 5 materials / 0 textures.

Run:
  ./tools/export_blender_to_godot.sh --script blender/scripts/make_gearforge_walker_lod1.py
"""

import math
import os
import sys

SCRIPT_DIR = os.path.abspath(os.path.dirname(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

import bpy  # noqa: E402
import make_gearforge_walker as W  # noqa: E402
from material_lib import palette  # noqa: E402


ASSET = "gearforge_walker"
LOD = "lod1"
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SOURCE_BLEND = os.path.join(ROOT, "blender", "source", ASSET + "_" + LOD + ".blend")
EXPORT_GLB = os.path.join(ROOT, "blender", "exports", ASSET + "_" + LOD + ".glb")

T = W.T


def build_leg_lod1(sx, mats):
    tag = "legl" if sx < 0 else "legr"
    H, S, B, C = mats["dark_iron"], mats["steel"], mats["brass"], mats["copper"]
    fx, fy = sx * W.FOOT_X, W.FOOT_Y
    ankle = W.mirror(W.ANKLE, sx)
    knee = W.mirror(W.KNEE, sx)
    hip = W.mirror(W.HIP, sx)

    T.box(f"{ASSET}_{tag}_pad", (1.00, 1.64, 0.22), (fx, fy, 0.11), H, bevel=0.0)
    T.box(f"{ASSET}_{tag}_deck", (0.92, 1.26, 0.18), (fx, fy - 0.04, 0.30), S, bevel=0.0)
    T.trapezoid(f"{ASSET}_{tag}_toe", (0.90, 0.50), (0.66, 0.36), 0.32,
                (fx, fy - 0.84, 0.26), S, bevel=0.0)
    T.box(f"{ASSET}_{tag}_heel", (0.78, 0.40, 0.42), (fx, fy + 0.76, 0.32), H, bevel=0.0)
    T.box(f"{ASSET}_{tag}_ankle_block", (0.52, 0.64, 0.46), (fx, fy + 0.06, 0.52), H, bevel=0.0)
    T.cylinder(f"{ASSET}_{tag}_ankle_axle", 0.23, 0.90, ankle, B,
               vertices=8, rot=(0.0, math.radians(90.0), 0.0), bevel=0.0)
    W.box_between(f"{ASSET}_{tag}_shin", knee, ankle, 0.56, 0.62, H, bevel=0.0, extend=0.18)
    W.box_between(f"{ASSET}_{tag}_shin_plate",
                  W.along(knee, ankle, 0.18, -0.03, sx), W.along(knee, ankle, 0.92, -0.03, sx),
                  0.64, 0.20, S, bevel=0.0)
    T.cylinder_between(f"{ASSET}_{tag}_shin_ram",
                       W.along(knee, ankle, 0.08, -0.34, sx), W.along(knee, ankle, 0.94, -0.30, sx),
                       0.08, C, vertices=6, bevel=0.0)
    T.cylinder(f"{ASSET}_{tag}_knee", 0.33, 0.78, knee, B,
               vertices=10, rot=(0.0, math.radians(90.0), 0.0), bevel=0.0)
    T.cylinder(f"{ASSET}_{tag}_knee_cap", 0.21, 0.92, knee, H,
               vertices=8, rot=(0.0, math.radians(90.0), 0.0), bevel=0.0)
    T.box(f"{ASSET}_{tag}_knee_guard", (0.56, 0.30, 0.54), W.mirror(W.KNEE, sx, 0.0, -0.34, 0.04),
          S, bevel=0.0)
    W.box_between(f"{ASSET}_{tag}_thigh", hip, knee, 0.62, 0.74, H, bevel=0.0, extend=0.16)
    W.box_between(f"{ASSET}_{tag}_thigh_plate",
                  W.along(hip, knee, 0.14, -0.03, sx), W.along(hip, knee, 0.90, -0.03, sx),
                  0.70, 0.22, S, bevel=0.0)
    T.cylinder_between(f"{ASSET}_{tag}_thigh_ram",
                       W.along(hip, knee, 0.10, 0.30, sx), W.along(hip, knee, 0.92, 0.26, sx),
                       0.075, C, vertices=6, bevel=0.0)
    T.box(f"{ASSET}_{tag}_hip_housing", (0.66, 0.80, 0.52), W.mirror(W.HIP, sx, 0.0, 0.02, -0.04),
          H, bevel=0.0)
    T.cylinder(f"{ASSET}_{tag}_hip_axle", 0.28, 0.76, hip, B,
               vertices=10, rot=(0.0, math.radians(90.0), 0.0), bevel=0.0)


def build_hull_lod1(mats):
    H, S, B, C, A = (mats["dark_iron"], mats["steel"], mats["brass"],
                     mats["copper"], mats["aether_glow"])
    HIP = W.HIP
    HULL_Z = W.HULL_Z

    T.box(f"{ASSET}_hull_yoke", (2.24, 1.02, 0.50), (0.0, 0.20, HIP[2] + 0.10), S, bevel=0.0)
    T.cylinder(f"{ASSET}_hull_collar", 0.66, 0.30, (0.0, 0.10, HIP[2] + 0.40), B,
               vertices=10, bevel=0.0)
    T.trapezoid(f"{ASSET}_hull_body", (2.10, 2.16), (1.86, 1.88), 0.88,
                (0.0, 0.06, HULL_Z), H, bevel=0.03)
    T.box(f"{ASSET}_hull_belt", (2.16, 2.20, 0.18), (0.0, 0.06, HULL_Z - 0.40), B, bevel=0.0)
    T.box(f"{ASSET}_hull_roof", (1.90, 1.94, 0.16), (0.0, 0.06, W.ROOF_Z), S, bevel=0.0)
    T.trapezoid(f"{ASSET}_hull_glacis", (1.78, 0.30), (1.50, 0.22), 0.84,
                (0.0, -1.02, HULL_Z + 0.02), H, bevel=0.0)
    T.box(f"{ASSET}_hull_brow", (1.58, 0.26, 0.18), (0.0, -1.06, HULL_Z + 0.42), B, bevel=0.0)
    T.box(f"{ASSET}_hull_sensor", (1.16, 0.12, 0.13), (0.0, -1.12, HULL_Z + 0.20), A, bevel=0.0)
    T.box(f"{ASSET}_hull_glacis_rib", (0.26, 0.20, 0.72), (0.0, -1.08, HULL_Z - 0.06), S, bevel=0.0)
    T.cylinder(f"{ASSET}_hull_regulator_ring", 0.25, 0.20, (0.0, -1.02, HULL_Z - 0.30), B,
               vertices=10, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
    T.cylinder(f"{ASSET}_hull_regulator", 0.15, 0.14, (0.0, -1.10, HULL_Z - 0.30), A,
               vertices=8, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)

    for sx in (-1.0, 1.0):
        side = "l" if sx < 0 else "r"
        T.box(f"{ASSET}_hull_shoulder_{side}", (0.40, 1.60, 0.86), (sx * 1.06, 0.02, HULL_Z + 0.16),
              H, rot=(0.0, math.radians(sx * 12.0), 0.0), bevel=0.0)
        T.box(f"{ASSET}_hull_shoulder_cap_{side}", (0.48, 1.64, 0.14), (sx * 1.08, 0.02, HULL_Z + 0.64),
              B, bevel=0.0)
        T.box(f"{ASSET}_hull_faction_plate_{side}", (0.10, 0.72, 0.46),
              (sx * 1.28, -0.24, HULL_Z + 0.16), S, bevel=0.0)
        T.cylinder(f"{ASSET}_hull_smoke_{side}", 0.075, 0.26,
                   (sx * 1.02, 0.62, HULL_Z + 0.80), B, vertices=6,
                   rot=(math.radians(-24.0), 0.0, 0.0), bevel=0.0)
        T.cylinder(f"{ASSET}_hull_tank_{side}", 0.19, 0.66, (sx * 0.86, 0.86, HULL_Z - 0.34), C,
                   vertices=8, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)

    T.box(f"{ASSET}_hull_rear_plate", (1.84, 0.24, 0.92), (0.0, 1.14, HULL_Z - 0.04), S, bevel=0.0)
    for rx in (-0.62, 0.62):
        T.box(f"{ASSET}_hull_rear_rib_{int((rx + 1) * 100)}", (0.16, 0.20, 0.86),
              (rx, 1.24, HULL_Z - 0.04), H, bevel=0.0)
    T.cylinder(f"{ASSET}_hull_boiler", 0.40, 1.44, (0.0, 1.06, HULL_Z + 0.02), C,
               vertices=10, rot=(0.0, math.radians(90.0), 0.0), bevel=0.0)
    T.torus(f"{ASSET}_hull_boiler_band_100", 0.44, 0.06, (0.0, 1.06, HULL_Z + 0.02), B,
            rot=(0.0, math.radians(90.0), 0.0), major=10, minor=4)
    T.box(f"{ASSET}_hull_ammo_housing", (1.34, 0.56, 0.60), (0.0, 1.06, HULL_Z + 0.56), H, bevel=0.0)
    T.cylinder(f"{ASSET}_hull_capacitor", 0.21, 0.34, (0.0, 0.70, HULL_Z + 0.72), B,
               vertices=10, bevel=0.0)
    T.cylinder(f"{ASSET}_hull_capacitor_core", 0.13, 0.16, (0.0, 0.70, HULL_Z + 0.90), A,
               vertices=8, bevel=0.0)
    for sx in (-1.0, 1.0):
        side = "l" if sx < 0 else "r"
        T.cylinder(f"{ASSET}_hull_exhaust_{side}", 0.135, 0.94, (sx * 0.66, 1.18, HULL_Z + 0.96),
                   H, vertices=8, rot=(math.radians(-18.0), 0.0, 0.0), bevel=0.0)
        T.cylinder(f"{ASSET}_hull_exhaust_lip_{side}", 0.175, 0.13, (sx * 0.66, 1.32, HULL_Z + 1.40),
                   B, vertices=8, rot=(math.radians(-18.0), 0.0, 0.0), bevel=0.0)
        T.cylinder_between(f"{ASSET}_hull_feed_{side}", (sx * 0.46, 1.06, HULL_Z + 0.02),
                           (sx * 0.66, 1.14, HULL_Z + 0.62), 0.075, C, vertices=6, bevel=0.0)


def build_turret_lod1(mats):
    H, S, B, C = mats["dark_iron"], mats["steel"], mats["brass"], mats["copper"]
    GUN_Z = W.GUN_Z

    T.cylinder(f"{ASSET}_turret_ring", 0.66, 0.20, (0.0, -0.04, W.ROOF_Z + 0.10), B,
               vertices=10, bevel=0.0)
    T.trapezoid(f"{ASSET}_turret_body", (1.30, 1.28), (1.10, 1.08), 0.54,
                (0.0, -0.08, GUN_Z), H, bevel=0.0)
    T.box(f"{ASSET}_turret_trim", (1.34, 1.32, 0.10), (0.0, -0.08, GUN_Z - 0.24), B, bevel=0.0)
    T.box(f"{ASSET}_turret_mantlet", (1.10, 0.50, 0.68), (0.0, -0.76, GUN_Z), H, bevel=0.0)
    T.box(f"{ASSET}_turret_mantlet_face", (0.86, 0.16, 0.54), (0.0, -1.00, GUN_Z), S, bevel=0.0)
    for sx in (-1.0, 1.0):
        side = "l" if sx < 0 else "r"
        T.cylinder(f"{ASSET}_turret_trunnion_{side}", 0.18, 0.28, (sx * 0.60, -0.70, GUN_Z), B,
                   vertices=8, rot=(0.0, math.radians(90.0), 0.0), bevel=0.0)
        T.box(f"{ASSET}_turret_rail_{side}", (0.12, 1.26, 0.12), (sx * 0.44, -0.62, GUN_Z + 0.38),
              C, bevel=0.0)
        T.cylinder(f"{ASSET}_turret_recoil_{side}", 0.12, 1.06, (sx * 0.42, -0.84, GUN_Z - 0.32),
                   C, vertices=6, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
    T.box(f"{ASSET}_turret_rail_cross", (1.06, 0.15, 0.15), (0.0, -1.22, GUN_Z + 0.38), B, bevel=0.0)
    T.cylinder(f"{ASSET}_turret_sleeve", 0.235, 0.68, (0.0, -1.30, GUN_Z), S,
               vertices=10, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
    T.cylinder(f"{ASSET}_turret_barrel", 0.15, 1.12, (0.0, -1.98, GUN_Z), H,
               vertices=8, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
    T.cylinder(f"{ASSET}_turret_brake", 0.245, 0.36, (0.0, -2.46, GUN_Z), B,
               vertices=10, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
    T.box(f"{ASSET}_turret_breech", (0.86, 0.56, 0.62), (0.0, 0.40, GUN_Z), H, bevel=0.0)
    T.cylinder(f"{ASSET}_turret_breech_ring", 0.28, 0.22, (0.0, 0.68, GUN_Z), B,
               vertices=10, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
    T.box(f"{ASSET}_turret_counterweight", (0.96, 0.28, 0.46), (0.0, 0.76, GUN_Z - 0.14), S, bevel=0.0)
    T.box(f"{ASSET}_turret_coax_box", (0.32, 0.48, 0.30), (0.64, -0.82, GUN_Z - 0.32), H, bevel=0.0)
    T.cylinder(f"{ASSET}_turret_coax", 0.07, 0.74, (0.64, -1.34, GUN_Z - 0.32), S,
               vertices=6, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)


def join_groups_lod1():
    members = {group: [] for group in W.GROUPS}
    for obj in bpy.context.scene.objects:
        if obj.type == "MESH":
            members[W.group_of(obj.name)].append(obj)
    result = {}
    for group in W.GROUPS:
        objects = members[group]
        if not objects:
            continue
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.object.join()
        joined = bpy.context.active_object
        joined.name = f"{ASSET}_{group}_{LOD}"
        joined.data.name = f"{ASSET}_{group}_{LOD}_mesh"
        joined.select_set(False)
        pivot = T.anchor(f"{group}_pivot", {
            "leg_l": W.mirror(W.HIP, -1.0),
            "leg_r": W.mirror(W.HIP, 1.0),
            "turret": (0.0, -0.04, W.ROOF_Z + 0.10),
            "hull": (0.0, 0.10, W.HIP[2] + 0.40),
        }[group])
        joined.parent = pivot
        joined.matrix_parent_inverse = pivot.matrix_world.inverted()
        result[group] = joined
    return result


def main():
    W.T.clear_scene()
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene["asset_name"] = ASSET
    scene["production_name"] = "Ironstride"
    scene["lod"] = LOD
    scene["forward_axis"] = "-Y"
    scene["up_axis"] = "+Z"
    scene["texture_count"] = 0

    full = palette("gearforge")
    mats = {k: full[k] for k in ("dark_iron", "steel", "brass", "copper", "aether_glow")}
    build_leg_lod1(-1.0, mats)
    build_leg_lod1(1.0, mats)
    build_hull_lod1(mats)
    build_turret_lod1(mats)
    join_groups_lod1()
    T.anchor("muzzle", (0.0, -2.68, W.GUN_Z))
    T.anchor("center_anchor", (0.0, 0.06, W.HULL_Z))
    T.anchor("reactor_anchor", (0.0, -1.10, W.HULL_Z - 0.30))
    T.anchor("exhaust_l", (-0.66, 1.46, W.HULL_Z + 1.46))
    T.anchor("exhaust_r", (0.66, 1.46, W.HULL_Z + 1.46))
    T.anchor("weapon_secondary", (0.64, -1.72, W.GUN_Z - 0.32))
    T.anchor("piston_l", (-W.FOOT_X, W.FOOT_Y - 0.40, W.ANKLE[2]))
    T.anchor("piston_r", (W.FOOT_X, W.FOOT_Y - 0.40, W.ANKLE[2]))
    stats = W.report_stats()
    scene["mesh_count"] = stats[0]
    scene["vertex_count"] = stats[1]
    scene["polygon_count"] = stats[2]
    scene["triangle_count"] = stats[3]
    scene["material_count"] = stats[4]

    bpy.ops.object.select_all(action="SELECT")
    os.makedirs(os.path.dirname(SOURCE_BLEND), exist_ok=True)
    os.makedirs(os.path.dirname(EXPORT_GLB), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)
    print("SAVE_BLEND_OK", SOURCE_BLEND)
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
    print("EXPORT_GLB_OK", EXPORT_GLB, os.path.getsize(EXPORT_GLB), "bytes")


if __name__ == "__main__":
    main()
