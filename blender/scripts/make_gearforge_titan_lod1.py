"""Build the Gearforge Crownpiercer LOD1 (far/strategic) Titan.

Outputs:
  blender/source/gearforge_titan_lod1.blend
  blender/exports/gearforge_titan_lod1.glb

LOD1 keeps the LOD0 silhouette (long left Crownspike, short right brace,
wide torso, split legs, twin stacks, chest Aether core, asymmetry) while
cutting strategic-invisible detail: rivets, vent slits, deck valves/wheels,
cannon bore inset, one cooling fin, reduced bands, lower segment counts,
no bevels. Anchors (muzzle / reactor_anchor / exhaust_l / exhaust_r) keep
LOD0 positions and meaning. LOD0 is untouched; this is a separate asset.

Geometry helpers are reused from make_gearforge_titan.py (no duplication).

Target: 4-6 meshes / ~4,500-6,000 triangles / 5 materials / 0 textures.

Run:
  ./tools/export_blender_to_godot.sh --script blender/scripts/make_gearforge_titan_lod1.py
"""

import math
import os
import sys

SCRIPT_DIR = os.path.abspath(os.path.dirname(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

import bpy  # noqa: E402
import make_gearforge_titan as T  # noqa: E402
from material_lib import palette  # noqa: E402


ASSET = "gearforge_titan"
LOD = "lod1"
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SOURCE_BLEND = os.path.join(ROOT, "blender", "source", ASSET + "_" + LOD + ".blend")
EXPORT_GLB = os.path.join(ROOT, "blender", "exports", ASSET + "_" + LOD + ".glb")


def build_foot_lod1(sx, H, Tt, C):
    side = "l" if sx < 0 else "r"
    x = 1.58 * sx
    T.box(f"{ASSET}_sole_{side}", (1.74, 2.55, 0.30), (x, 0.05, 0.18), H, bevel=0.04)
    T.box(f"{ASSET}_foot_deck_{side}", (1.56, 2.16, 0.18), (x, 0.02, 0.40), H, bevel=0.0)
    T.trapezoid(f"{ASSET}_toe_{side}", (1.70, 1.45), (1.34, 1.15), 0.48,
                (x, -0.70, 0.55), H, bevel=0.0)
    T.box(f"{ASSET}_heel_{side}", (1.42, 0.72, 0.62), (x, 0.92, 0.53), H, bevel=0.04)
    T.cylinder(f"{ASSET}_ankle_{side}", 0.56, 0.72, (x, 0.10, 0.92), Tt, vertices=14, bevel=0.0)
    T.cylinder(f"{ASSET}_ankle_axle_{side}", 0.34, 1.48, (x, 0.02, 1.02), H,
               vertices=14, rot=(0.0, math.radians(90.0), 0.0), bevel=0.0)
    for ox in (-0.54, 0.54):
        T.cylinder_between(
            f"{ASSET}_ankle_fork_{side}_{int((ox + 0.6) * 10)}",
            (x + ox, 0.38, 0.55), (x + ox, 0.20, 1.34),
            0.11, H, vertices=6, bevel=0.0)
    T.cylinder_between(f"{ASSET}_ankle_ram_{side}", (x, -0.52, 0.62),
                       (x, -0.42, 1.46), 0.14, C, vertices=6, bevel=0.0)
    T.box(f"{ASSET}_shin_{side}", (1.10, 1.08, 2.05), (x, 0.20, 2.02), H,
          rot=(math.radians(-5.0), 0.0, 0.0), bevel=0.0)
    T.trapezoid(f"{ASSET}_shin_armor_{side}", (1.44, 0.54), (1.15, 0.42), 1.75,
                (x, -0.57, 2.13), H, bevel=0.0)
    T.cylinder(f"{ASSET}_knee_{side}", 0.58, 1.42, (x, -0.16, 3.08), Tt,
               vertices=14, rot=(0.0, math.radians(90.0), 0.0), bevel=0.0)
    T.trapezoid(f"{ASSET}_knee_guard_{side}", (1.18, 0.36), (0.88, 0.26), 0.76,
                (x, -0.73, 3.10), H, bevel=0.0)
    T.box(f"{ASSET}_thigh_{side}", (1.26, 1.26, 1.58), (x, 0.26, 3.88), H,
          rot=(math.radians(7.0), 0.0, 0.0), bevel=0.0)
    T.box(f"{ASSET}_thigh_plate_{side}", (1.40, 0.36, 1.18), (x, -0.53, 3.92), H, bevel=0.0)
    T.box(f"{ASSET}_thigh_crown_{side}", (1.48, 1.12, 0.24), (x, 0.18, 4.58), Tt, bevel=0.0)
    # Keep one piston pair per segment: leg machinery read at mid distance.
    for offset in (-0.38, 0.38):
        T.cylinder_between(
            f"{ASSET}_shin_piston_{side}_{int((offset + 0.5) * 10)}",
            (x + offset, 0.72, 1.15), (x + offset, 0.68, 2.88),
            0.105, C, vertices=8, bevel=0.0)
        T.cylinder_between(
            f"{ASSET}_thigh_piston_{side}_{int((offset + 0.5) * 10)}",
            (x + offset, 0.66, 3.02), (x + offset, 0.78, 4.58),
            0.095, Tt, vertices=8, bevel=0.0)
    T.cylinder_between(f"{ASSET}_front_leg_ram_{side}", (x - sx * 0.38, -0.50, 1.18),
                       (x - sx * 0.48, -0.52, 2.78), 0.095, C, vertices=6, bevel=0.0)


def build_body_lod1(H, Tt, C, A):
    T.cylinder(f"{ASSET}_hip_turntable", 2.14, 0.72, (0.0, 0.08, 4.72), H, vertices=14, bevel=0.0)
    T.box(f"{ASSET}_hip_beam", (4.45, 2.55, 0.70), (0.0, 0.08, 4.86), H, bevel=0.05)
    T.trapezoid(f"{ASSET}_torso", (4.60, 3.38), (3.88, 2.86), 2.52,
                (0.0, 0.12, 6.35), H, bevel=0.06)
    T.box(f"{ASSET}_torso_front_plate", (3.58, 0.34, 1.82), (0.0, -1.62, 6.48), H, bevel=0.04)
    for sx in (-1.0, 1.0):
        side = "l" if sx < 0 else "r"
        T.box(f"{ASSET}_glacis_{side}", (1.06, 0.20, 0.72),
              (sx * 1.35, -1.86, 7.02), H,
              rot=(0.0, 0.0, math.radians(-sx * 7.0)), bevel=0.0)
        T.box(f"{ASSET}_torso_side_rib_{side}", (0.24, 2.18, 1.62),
              (sx * 2.22, 0.02, 6.44), H, bevel=0.0)
    T.trapezoid(f"{ASSET}_governor_keel", (1.32, 0.24), (0.92, 0.18), 0.88,
                (0.0, -1.93, 5.76), H, bevel=0.0)
    T.box(f"{ASSET}_torso_belt", (4.42, 3.12, 0.27), (0.0, 0.04, 5.53), Tt, bevel=0.0)
    T.box(f"{ASSET}_top_deck", (3.85, 2.82, 0.30), (0.0, 0.18, 7.67), Tt, bevel=0.0)
    T.cylinder(f"{ASSET}_chest_core_housing", 0.78, 0.42, (0.0, -1.87, 6.62), Tt,
               vertices=14, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
    T.cylinder(f"{ASSET}_chest_core", 0.52, 0.48, (0.0, -2.02, 6.62), A,
               vertices=14, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
    T.torus(f"{ASSET}_chest_core_ring", 0.70, 0.10, (0.0, -2.13, 6.62), Tt,
            rot=(math.radians(90.0), 0.0, 0.0), major=12, minor=6)
    for sx in (-1.0, 1.0):
        T.cylinder_between(f"{ASSET}_governor_lock_{'l' if sx < 0 else 'r'}",
                           (sx * 0.78, -2.00, 6.12), (sx * 0.78, -2.00, 7.10),
                           0.085, C, vertices=6, bevel=0.0)
    for x in (-1.46, 1.46):
        T.box(f"{ASSET}_chest_vent_{int(x * 10)}", (0.72, 0.16, 0.95), (x, -1.86, 6.42), H, bevel=0.0)
    T.cylinder(f"{ASSET}_neck", 0.46, 0.48, (0.0, -0.42, 7.98), Tt, vertices=14, bevel=0.0)
    T.trapezoid(f"{ASSET}_sensor_head", (1.40, 1.24), (1.05, 0.92), 0.88,
                (0.0, -0.74, 8.52), H, bevel=0.0)
    T.box(f"{ASSET}_sensor_brow", (1.18, 0.22, 0.20), (0.0, -1.32, 8.62), Tt, bevel=0.0)
    T.box(f"{ASSET}_sensor_visor", (0.86, 0.12, 0.22), (0.0, -1.45, 8.48), A, bevel=0.0)
    T.cylinder(f"{ASSET}_rangefinder", 0.20, 0.52, (0.70, -0.72, 8.66), Tt,
               vertices=14, rot=(0.0, math.radians(90.0), 0.0), bevel=0.0)


def build_cannon_lod1(H, Tt, C, A):
    x = -2.72
    T.cylinder(f"{ASSET}_cannon_shoulder_axle", 0.74, 1.28, (-2.22, 0.0, 7.30), Tt,
               vertices=14, rot=(0.0, math.radians(90.0), 0.0), bevel=0.0)
    T.box(f"{ASSET}_cannon_shoulder", (1.66, 2.12, 1.58), (x, -0.02, 7.30), H, bevel=0.06)
    T.box(f"{ASSET}_cannon_breech", (1.72, 2.20, 1.36), (x, -1.48, 7.26), H, bevel=0.06)
    T.box(f"{ASSET}_cannon_top_armor", (1.92, 1.58, 0.30), (x, -1.42, 8.02), Tt, bevel=0.0)
    T.box(f"{ASSET}_cannon_counterweight", (1.44, 0.70, 1.12), (x, 0.86, 7.22), H, bevel=0.0)
    T.torus(f"{ASSET}_cannon_outer_trunnion", 0.71, 0.105, (-3.60, 0.0, 7.30),
            Tt, rot=(0.0, math.radians(90.0), 0.0), major=10, minor=4)
    for rx in (-0.56, 0.56):
        T.box(f"{ASSET}_recoil_cradle_{int((rx + 0.6) * 10)}", (0.18, 3.52, 0.22),
              (x + rx, -2.48, 6.68), H, bevel=0.0)
        T.cylinder_between(f"{ASSET}_recoil_ram_{int((rx + 0.6) * 10)}",
                           (x + rx, -0.72, 6.86), (x + rx, -3.92, 6.86),
                           0.105, C, vertices=6, bevel=0.0)
    T.box(f"{ASSET}_cradle_crossbar_242", (1.42, 0.16, 0.18), (x, -2.42, 6.68), Tt, bevel=0.0)
    T.cylinder_between(f"{ASSET}_cannon_mount_strut_front", (-1.82, -0.72, 6.18),
                       (-2.40, -0.22, 6.72), 0.14, Tt, vertices=6, bevel=0.0)
    T.cylinder_between(f"{ASSET}_cannon_mount_strut_rear", (-1.82, 0.72, 6.18),
                       (-2.40, 0.36, 6.72), 0.14, H, vertices=6, bevel=0.0)
    T.cylinder(f"{ASSET}_cannon_shroud", 0.66, 2.55, (x, -3.34, 7.26), H,
               vertices=14, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
    for y in (-2.45, -3.56, -4.42):
        T.torus(f"{ASSET}_cannon_band_{int(abs(y) * 100)}", 0.70, 0.11, (x, y, 7.26), Tt,
                rot=(math.radians(90.0), 0.0, 0.0), major=12, minor=6)
    T.cylinder(f"{ASSET}_cannon_barrel", 0.38, 2.72, (x, -5.05, 7.26), H,
               vertices=14, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
    T.cylinder(f"{ASSET}_cannon_muzzle", 0.78, 0.78, (x, -6.34, 7.26), Tt,
               vertices=14, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
    T.cylinder(f"{ASSET}_cannon_aether_lens", 0.25, 0.13, (x, -6.84, 7.26), A,
               vertices=8, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
    for rail_x in (-0.73, 0.73):
        T.box(f"{ASSET}_cannon_rail_{int(rail_x * 100)}", (0.16, 3.10, 0.20),
              (x + rail_x, -3.82, 7.62), C, bevel=0.0)
    T.box(f"{ASSET}_cannon_fin_345", (1.76, 0.12, 1.02), (x, -3.45, 7.28), H, bevel=0.0)
    T.cylinder_between(f"{ASSET}_weapon_feed_a", (-0.42, -1.82, 6.72), (-1.38, -1.76, 7.30),
                       0.12, A, vertices=8, bevel=0.0)
    T.cylinder_between(f"{ASSET}_weapon_feed_b", (-1.38, -1.76, 7.30), (x + 0.65, -1.72, 7.30),
                       0.12, A, vertices=8, bevel=0.0)
    T.anchor("muzzle", (x, -6.92, 7.26))


def build_brace_lod1(H, Tt, C):
    x = 2.75
    T.cylinder(f"{ASSET}_brace_shoulder_axle", 0.76, 1.28, (2.20, 0.02, 7.28), Tt,
               vertices=14, rot=(0.0, math.radians(90.0), 0.0), bevel=0.0)
    T.box(f"{ASSET}_brace_shoulder", (1.72, 2.04, 1.68), (x, 0.02, 7.25), H, bevel=0.06)
    T.box(f"{ASSET}_brace_shoulder_crown", (1.54, 1.62, 0.28), (x, -0.02, 8.10), Tt, bevel=0.0)
    T.box(f"{ASSET}_brace_upper", (1.22, 1.34, 1.48), (3.15, 0.14, 6.12), H,
          rot=(0.0, math.radians(-4.0), math.radians(-8.0)), bevel=0.0)
    T.cylinder(f"{ASSET}_brace_elbow", 0.48, 1.35, (3.28, -0.02, 5.31), Tt,
               vertices=14, rot=(0.0, math.radians(90.0), 0.0), bevel=0.0)
    T.trapezoid(f"{ASSET}_brace_gauntlet", (1.46, 1.70), (1.18, 1.40), 1.78,
                (3.36, -0.05, 4.53), H, bevel=0.0)
    T.box(f"{ASSET}_brace_face", (1.24, 0.28, 1.26), (3.36, -0.90, 4.52), H, bevel=0.0)
    for dx in (-0.40, 0.0, 0.40):
        T.box(f"{ASSET}_brace_tooth_{int((dx + 0.5) * 100)}", (0.28, 0.72, 0.35),
              (3.36 + dx, -0.50, 3.53), Tt, bevel=0.0)
    T.cylinder_between(f"{ASSET}_brace_piston_outer", (3.56, 0.72, 6.88), (3.70, 0.68, 5.12),
                       0.13, C, vertices=8, bevel=0.0)
    T.cylinder_between(f"{ASSET}_brace_piston_inner", (2.78, 0.70, 6.75), (2.92, 0.66, 5.22),
                       0.11, Tt, vertices=8, bevel=0.0)
    T.cylinder_between(f"{ASSET}_brace_shock", (3.52, -0.56, 6.72), (3.58, -0.48, 5.26),
                       0.14, C, vertices=6, bevel=0.0)
    T.box(f"{ASSET}_brace_rear_block", (1.14, 0.52, 0.82), (3.28, 0.78, 5.62), H, bevel=0.0)


def build_reactor_lod1(H, Tt, C, A, F):
    for sx in (-1.18, 1.18):
        side = "l" if sx < 0 else "r"
        T.cylinder(f"{ASSET}_rear_boiler_{side}", 0.66, 2.45, (sx, 1.38, 7.54), C, vertices=14, bevel=0.0)
        for z in (6.55, 8.54):
            T.torus(f"{ASSET}_boiler_band_{side}_{int(z * 100)}", 0.68, 0.085, (sx, 1.38, z),
                    Tt, major=12, minor=6)
        T.cylinder(f"{ASSET}_stack_{side}", 0.37, 2.28, (sx, 1.40, 10.02), H, vertices=14, bevel=0.0)
        T.cylinder(f"{ASSET}_stack_collar_{side}", 0.47, 0.25, (sx, 1.40, 9.18), Tt,
                   vertices=14, bevel=0.0)
        T.cylinder(f"{ASSET}_stack_lip_{side}", 0.53, 0.30, (sx, 1.40, 11.20), Tt,
                   vertices=14, bevel=0.0)
        T.cylinder(f"{ASSET}_stack_heat_{side}", 0.34, 0.08, (sx, 1.40, 11.38), F,
                   vertices=14, bevel=0.0)
        T.anchor(f"exhaust_{side}", (sx, 1.40, 11.45))
        T.cylinder_between(f"{ASSET}_stack_stay_{side}", (sx, 1.38, 9.18),
                           (sx * 1.72, 0.78, 8.20), 0.09, Tt, vertices=6, bevel=0.0)
    T.cylinder(f"{ASSET}_reactor_housing", 1.05, 0.74, (0.0, 2.03, 7.12), H,
               vertices=14, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
    T.cylinder(f"{ASSET}_reactor_core", 0.69, 0.80, (0.0, 2.34, 7.12), A,
               vertices=14, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
    T.torus(f"{ASSET}_reactor_ring", 0.94, 0.13, (0.0, 2.47, 7.12), Tt,
            rot=(math.radians(90.0), 0.0, 0.0), major=14, minor=6)
    T.anchor("reactor_anchor", (0.0, 2.52, 7.12))
    for sx in (-1.0, 1.0):
        side = "l" if sx < 0 else "r"
        T.box(f"{ASSET}_reactor_cage_vertical_{side}", (0.18, 0.18, 1.86),
              (sx * 1.16, 2.30, 7.12), H, bevel=0.0)
        T.cylinder_between(f"{ASSET}_lower_pressure_pipe_{side}",
                           (sx * 1.18, 1.78, 6.42), (sx * 1.70, 1.04, 5.32),
                           0.12, C, vertices=6, bevel=0.0)
    T.box(f"{ASSET}_reactor_cage_cross_808", (2.42, 0.18, 0.18), (0.0, 2.30, 8.08), Tt, bevel=0.0)
    T.box(f"{ASSET}_rear_manifold", (2.18, 0.42, 0.46), (0.0, 1.73, 5.48), H, bevel=0.0)
    for sx in (-1.0, 1.0):
        side = "l" if sx < 0 else "r"
        T.cylinder_between(f"{ASSET}_reactor_pipe_a_{side}", (sx * 0.60, 2.12, 7.18),
                           (sx * 1.18, 1.90, 8.04), 0.115, C, vertices=8, bevel=0.0)
        T.cylinder_between(f"{ASSET}_reactor_pipe_b_{side}", (sx * 1.18, 1.90, 8.04),
                           (sx * 1.18, 1.62, 8.78), 0.115, C, vertices=8, bevel=0.0)
        T.box(f"{ASSET}_back_chevron_{side}", (0.20, 0.14, 1.22),
              (sx * 0.72, 2.31, 5.95), A,
              rot=(0.0, 0.0, math.radians(-sx * 30.0)), bevel=0.0)


def join_by_material_lod1(mats):
    for key, mat in mats.items():
        objects = [
            obj for obj in bpy.context.scene.objects
            if obj.type == "MESH" and len(obj.data.materials) > 0 and obj.data.materials[0] == mat
        ]
        if not objects:
            continue
        bpy.ops.object.select_all(action="DESELECT")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.object.join()
        joined = bpy.context.active_object
        joined.name = f"{ASSET}_{key}_{LOD}"
        joined.data.name = f"{ASSET}_{key}_{LOD}_mesh"
        joined.select_set(False)


def main():
    T.clear_scene()
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene["asset_name"] = ASSET
    scene["design_variant"] = "B_aether_siege_engine"
    scene["production_name"] = "Crownpiercer"
    scene["lod"] = LOD
    scene["forward_axis"] = "-Y"
    scene["up_axis"] = "+Z"
    scene["texture_count"] = 0

    full = palette("gearforge")
    # LOD1 merges distance-invisible metal splits: steel/rust -> hull,
    # bronze -> trim. Copper, Aether glow, furnace glow stay (color story).
    mats = {
        "dark_iron": full["dark_iron"],
        "brass": full["brass"],
        "copper": full["copper"],
        "aether_glow": full["aether_glow"],
        "furnace_glow": full["furnace_glow"],
    }
    H, Tt, C, A, F = (mats["dark_iron"], mats["brass"], mats["copper"],
                      mats["aether_glow"], mats["furnace_glow"])
    build_foot_lod1(-1.0, H, Tt, C)
    build_foot_lod1(1.0, H, Tt, C)
    build_body_lod1(H, Tt, C, A)
    build_cannon_lod1(H, Tt, C, A)
    build_brace_lod1(H, Tt, C)
    build_reactor_lod1(H, Tt, C, A, F)
    join_by_material_lod1(mats)
    stats = T.mesh_stats()
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
