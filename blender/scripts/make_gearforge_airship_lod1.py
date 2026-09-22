"""Build the Gearforge Crownhammer LOD1 (RTS-distance) Airship.

Outputs:
  blender/source/gearforge_airship_lod1.blend
  blender/exports/gearforge_airship_lod1.glb

LOD1 keeps the LOD0 silhouette (twin lift cells, ram prow, keel hull,
gondola, belly mortar, sponsons, ducted propellers, H-tail, dorsal
reactor) while cutting RTS-invisible detail: ring stations 6->3,
injectors 6->3/side, stringers 4->2, ribs/saddles reduced, sponson
twin barrels -> single, segments 20/18/16/14 -> 12/10, small bevels
dropped. Anchors keep LOD0 names/positions/meaning. LOD0 untouched.

Geometry helpers AND key dimensions are reused from
make_gearforge_airship.py (no duplication).

Target: 6 meshes / ~6,000-7,000 triangles / 6 materials / 0 textures.

Run:
  ./tools/export_blender_to_godot.sh --script blender/scripts/make_gearforge_airship_lod1.py
"""

import math
import os
import sys

SCRIPT_DIR = os.path.abspath(os.path.dirname(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

import bpy  # noqa: E402
import make_gearforge_airship as A  # noqa: E402
from material_lib import palette  # noqa: E402


ASSET = "gearforge_airship"
LOD = "lod1"
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SOURCE_BLEND = os.path.join(ROOT, "blender", "source", ASSET + "_" + LOD + ".blend")
EXPORT_GLB = os.path.join(ROOT, "blender", "exports", ASSET + "_" + LOD + ".glb")


def build_cells_lod1(H, S, B, C, Am, F):
    for side in (-1.0, 1.0):
        tag = "l" if side < 0 else "r"
        x = side * A.CELL_X
        length = A.CELL_Y1 - A.CELL_Y0
        mid_y = (A.CELL_Y0 + A.CELL_Y1) * 0.5
        A.cylinder(f"{ASSET}_cell_{tag}", A.CELL_R, length, (x, mid_y, A.CELL_Z),
                   H, vertices=12, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
        A.cone(f"{ASSET}_cell_nose_{tag}", A.CELL_R, 0.62, 4.70, (x, A.CELL_Y0 - 2.35, A.CELL_Z),
               H, vertices=12, rot=(math.radians(-90.0), 0.0, 0.0))
        A.cone(f"{ASSET}_cell_tail_{tag}", A.CELL_R, 0.90, 3.60, (x, A.CELL_Y1 + 1.80, A.CELL_Z),
               H, vertices=12, rot=(math.radians(90.0), 0.0, 0.0))
        for index, y in enumerate((-8.10, -1.30, 5.50)):
            A.cylinder(f"{ASSET}_cell_ring_{tag}_{index}", A.CELL_R + 0.17, 0.26, (x, y, A.CELL_Z),
                       B, vertices=12, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
        A.cylinder(f"{ASSET}_cell_nose_ring_{tag}", A.CELL_R + 0.10, 0.34,
                   (x, A.CELL_Y0 - 0.10, A.CELL_Z),
                   B, vertices=12, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
        A.cylinder(f"{ASSET}_cell_tail_ring_{tag}", A.CELL_R + 0.10, 0.30,
                   (x, A.CELL_Y1 + 0.08, A.CELL_Z),
                   B, vertices=12, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
        A.cylinder(f"{ASSET}_cell_tail_cap_{tag}", 0.98, 0.44, (x, A.CELL_Y1 + 3.70, A.CELL_Z),
                   B, vertices=10, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
        A.cylinder(f"{ASSET}_cell_vent_{tag}", 0.62, 0.20, (x, A.CELL_Y1 + 3.94, A.CELL_Z),
                   F, vertices=10, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
        A.cylinder(f"{ASSET}_cell_nose_cap_{tag}", 0.72, 0.52, (x, A.CELL_Y0 - 4.62, A.CELL_Z),
                   B, vertices=10, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
        for angle in (0.0, 72.0):
            sx, sz = A.cell_surface(side, angle, A.CELL_R - 0.05)
            A.box(f"{ASSET}_cell_stringer_{tag}_{int(angle)}", (0.34, length + 1.9, 0.20),
                  (sx, mid_y - 0.35, sz), S,
                  rot=(0.0, math.radians(side * angle), 0.0), bevel=0.0)
        top_x, top_z = A.cell_surface(side, 0.0, A.CELL_R - 0.04)
        A.box(f"{ASSET}_cell_deck_{tag}", (2.30, length - 1.2, 0.22), (top_x, mid_y, top_z - 0.04),
              S, bevel=0.0)
        for index, y in enumerate((-7.4, -0.6, 6.2)):
            A.box(f"{ASSET}_cell_injector_{tag}_{index}", (0.80, 1.90, 0.22),
                  (x + side * 0.55, y, A.CELL_Z - A.CELL_R + 0.16), Am, bevel=0.0)
            A.box(f"{ASSET}_cell_injector_shroud_{tag}_{index}", (1.24, 2.16, 0.30),
                  (x + side * 0.55, y, A.CELL_Z - A.CELL_R + 0.02), B, bevel=0.0)


def build_keel_lod1(H, S, B, C):
    A.prism(f"{ASSET}_keel_hull", (2 * A.KEEL_HALF_W, A.KEEL_TOP - A.KEEL_BOTTOM), (3.40, 2.80),
            A.KEEL_REAR, A.KEEL_FRONT, (0.0, 0.0, 0.0), H, bevel=0.06)
    A.box(f"{ASSET}_keel_belt", (2 * A.KEEL_HALF_W + 0.22, 20.40, 0.34), (0.0, -0.70, 0.30),
          B, bevel=0.0)
    A.box(f"{ASSET}_keel_shoulder", (4.90, 19.20, 0.42), (0.0, -0.70, A.KEEL_TOP - 0.10),
          S, bevel=0.0)
    for side in (-1.0, 1.0):
        tag = "l" if side < 0 else "r"
        for index, y in enumerate((-7.4, 7.4)):
            A.box(f"{ASSET}_saddle_{tag}_{index}", (2.60, 0.90, 1.30),
                  (side * 2.55, y, 1.05), S, rot=(0.0, math.radians(side * 22.0), 0.0),
                  bevel=0.0)
            A.cylinder_between(
                f"{ASSET}_brace_{tag}_{index}",
                (side * 1.70, y, A.KEEL_TOP - 0.2), (side * 3.55, y, A.CELL_Z - A.CELL_R + 0.5),
                0.16, B, vertices=6,
            )
    A.box(f"{ASSET}_spine_deck", (2.60, 21.00, 0.46), (0.0, -0.40, A.KEEL_TOP + 0.44),
          B, bevel=0.0)
    for side in (-1.0, 1.0):
        tag = "l" if side < 0 else "r"
        for index, y in enumerate((-5.0, 3.0)):
            A.box(f"{ASSET}_keel_rib_{tag}_{index}", (0.44, 0.76, 2.80),
                  (side * (A.KEEL_HALF_W + 0.05), y, -0.05), S, bevel=0.0)
    A.box(f"{ASSET}_girder", (2.55, 21.20, 0.62), (0.0, -0.80, A.GIRDER_Z), H, bevel=0.0)
    A.box(f"{ASSET}_girder_rail", (3.30, 20.40, 0.26), (0.0, -0.80, A.GIRDER_Z - 0.42),
          B, bevel=0.0)
    for index, y in enumerate((-10.0, -3.2, 3.6)):
        A.box(f"{ASSET}_girder_rib_{index}", (3.55, 0.40, 0.90), (0.0, y, A.GIRDER_Z + 0.10),
              S, bevel=0.0)
    for side in (-1.0, 1.0):
        tag = "l" if side < 0 else "r"
        A.cylinder_between(
            f"{ASSET}_girder_truss_fwd_{tag}", (side * 1.30, -11.00, A.GIRDER_Z),
            (side * 1.90, -5.40, A.KEEL_BOTTOM), 0.15, H, vertices=6,
        )
        A.cylinder_between(
            f"{ASSET}_girder_truss_aft_{tag}", (side * 1.30, 9.60, A.GIRDER_Z),
            (side * 1.90, 4.20, A.KEEL_BOTTOM), 0.15, H, vertices=6,
        )


def build_prow_lod1(H, S, B, C, Am):
    A.prism(f"{ASSET}_prow", (3.40, 3.20), (1.30, 1.70), A.KEEL_FRONT, A.PROW_TIP,
            (0.0, 0.0, 0.25), H, bevel=0.06)
    A.prism(f"{ASSET}_prow_ram", (1.70, 2.00), (0.42, 0.70), A.PROW_TIP + 0.3, A.PROW_TIP - 1.55,
            (0.0, 0.0, 0.10), B, bevel=0.0)
    A.box(f"{ASSET}_prow_collar", (3.60, 0.62, 3.40), (0.0, A.KEEL_FRONT - 0.30, 0.25),
          B, bevel=0.0)
    A.box(f"{ASSET}_prow_band", (2.70, 0.46, 2.50), (0.0, A.PROW_TIP + 1.60, 0.20),
          B, bevel=0.0)
    for side in (-1.0, 1.0):
        tag = "l" if side < 0 else "r"
        A.box(f"{ASSET}_prow_cheek_{tag}", (0.42, 4.20, 1.70),
              (side * 1.32, A.KEEL_FRONT - 2.00, 0.45),
              S, rot=(0.0, math.radians(side * 12.0), 0.0), bevel=0.0)
    A.cylinder(f"{ASSET}_prow_lens", 0.52, 0.26, (0.0, A.PROW_TIP + 0.95, 0.85),
               Am, vertices=10, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
    A.torus(f"{ASSET}_prow_lens_ring", 0.66, 0.13, (0.0, A.PROW_TIP + 0.90, 0.85), B,
            rot=(math.radians(90.0), 0.0, 0.0), major=10, minor=4)


def build_belly_lod1(H, S, B, C, Am, F):
    A.prism(f"{ASSET}_gondola", (3.90, 1.95), (3.10, 1.60), -4.30, -10.60, (0.0, 0.0, -2.62),
            S, bevel=0.05)
    A.box(f"{ASSET}_gondola_roof", (4.20, 6.40, 0.34), (0.0, -7.45, -1.72), H, bevel=0.0)
    A.box(f"{ASSET}_gondola_keelplate", (3.20, 5.90, 0.30), (0.0, -7.45, -3.58), B, bevel=0.0)
    A.box(f"{ASSET}_bridge_slit", (3.16, 0.34, 0.52), (0.0, -10.48, -2.30), Am, bevel=0.0)
    for side in (-1.0, 1.0):
        tag = "l" if side < 0 else "r"
        A.box(f"{ASSET}_bridge_slit_{tag}", (0.30, 3.20, 0.46), (side * 1.86, -8.70, -2.34),
              Am, bevel=0.0)
        A.box(f"{ASSET}_gondola_rib_{tag}", (0.26, 0.60, 1.90), (side * 1.96, -5.20, -2.62),
              B, bevel=0.0)
        A.cylinder_between(
            f"{ASSET}_gondola_strut_{tag}", (side * 1.55, -4.10, A.KEEL_BOTTOM + 0.1),
            (side * 1.70, -5.60, -2.30), 0.15, H, vertices=6,
        )
    tilt = math.radians(-152.0)
    A.box(f"{ASSET}_mortar_cradle", (3.30, 3.90, 1.05), (0.0, -1.40, -2.05), H, bevel=0.05)
    A.cylinder(f"{ASSET}_mortar_breech", 1.02, 1.30, (0.0, -1.10, -2.42), S,
               vertices=10, rot=(tilt, 0.0, 0.0), bevel=0.0)
    A.cylinder(f"{ASSET}_mortar_core", 0.58, 0.46, (0.0, -0.62, -2.05), Am,
               vertices=10, rot=(tilt, 0.0, 0.0), bevel=0.0)
    A.torus(f"{ASSET}_mortar_core_ring", 0.72, 0.13, (0.0, -0.58, -2.02), B,
            rot=(tilt, 0.0, 0.0), major=10, minor=4)
    A.cylinder(f"{ASSET}_mortar_barrel", 0.95, 2.80, (0.0, -2.26, -3.46), B,
               vertices=10, rot=(tilt, 0.0, 0.0), bevel=0.0)
    for index, (by, bz) in enumerate(((-1.72, -2.92), (-3.08, -4.28))):
        A.torus(f"{ASSET}_mortar_band_{index}", 1.08, 0.16, (0.0, by, bz), B,
                rot=(tilt, 0.0, 0.0), major=10, minor=4)
    A.cylinder(f"{ASSET}_mortar_muzzle", 1.04, 0.40, (0.0, -3.28, -4.48), H,
               vertices=10, rot=(tilt, 0.0, 0.0), bevel=0.0)
    A.cylinder(f"{ASSET}_mortar_lens", 0.70, 0.18, (0.0, -3.38, -4.58), Am,
               vertices=10, rot=(tilt, 0.0, 0.0), bevel=0.0)
    for side in (-1.0, 1.0):
        tag = "l" if side < 0 else "r"
        A.cylinder_between(
            f"{ASSET}_mortar_recoil_{tag}", (side * 1.15, -0.10, -1.95),
            (side * 0.92, -1.95, -3.05), 0.17, C, vertices=6,
        )
    for side in (-1.0, 1.0):
        tag = "l" if side < 0 else "r"
        for index, y in enumerate((-6.80, 2.10)):
            x = side * (A.KEEL_HALF_W + 0.52)
            A.box(f"{ASSET}_sponson_{tag}_{index}", (1.60, 3.30, 1.55), (x, y, -0.55),
                  H, rot=(0.0, math.radians(side * -14.0), 0.0), bevel=0.0)
            A.box(f"{ASSET}_sponson_plate_{tag}_{index}", (0.36, 3.00, 1.30),
                  (side * (A.KEEL_HALF_W + 1.26), y, -0.48), S, bevel=0.0)
            A.cylinder(f"{ASSET}_sponson_ring_{tag}_{index}", 0.86, 0.30,
                       (side * (A.KEEL_HALF_W + 1.30), y, -0.48), B,
                       vertices=10, rot=(0.0, math.radians(90.0), 0.0), bevel=0.0)
            A.cylinder(
                f"{ASSET}_sponson_barrel_{tag}_{index}",
                0.21, 2.30, (side * (A.KEEL_HALF_W + 2.30), y, -0.48),
                B, vertices=8, rot=(0.0, math.radians(90.0), 0.0), bevel=0.0,
            )
            A.cylinder(f"{ASSET}_sponson_feed_{tag}_{index}", 0.22, 1.40,
                       (side * (A.KEEL_HALF_W + 0.30), y + 1.30, -1.20), C,
                       vertices=6, bevel=0.0)


def build_aft_lod1(H, S, B, C, Am, F):
    A.prism(f"{ASSET}_pod", (3.20, 1.70), (3.60, 1.85), 9.40, 2.90, (0.0, 0.0, -2.45),
            H, bevel=0.05)
    A.box(f"{ASSET}_pod_deck", (3.90, 6.30, 0.32), (0.0, 6.15, -1.68), S, bevel=0.0)
    for side in (-1.0, 1.0):
        tag = "l" if side < 0 else "r"
        A.cylinder(f"{ASSET}_pod_drum_{tag}", 0.74, 4.60, (side * 1.10, 6.20, -2.70),
                   C, vertices=10, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
        A.torus(f"{ASSET}_pod_band_{tag}_0", 0.82, 0.10, (side * 1.10, 6.20, -2.70),
                B, rot=(math.radians(90.0), 0.0, 0.0), major=10, minor=4)
        A.box(f"{ASSET}_pod_furnace_{tag}", (0.70, 0.30, 0.62), (side * 1.10, 3.30, -2.70),
              F, bevel=0.0)
        A.box(f"{ASSET}_pod_rust_{tag}", (0.24, 1.10, 0.90), (side * 1.82, 3.90, -2.35),
              H, bevel=0.0)
        A.cylinder_between(
            f"{ASSET}_pod_steam_{tag}", (side * 1.10, 8.60, -2.70),
            (side * 3.90, 7.60, -0.62), 0.20, C, vertices=6,
        )
    for side in (-1.0, 1.0):
        tag = "l" if side < 0 else "r"
        x = side * 5.20
        A.cylinder(f"{ASSET}_nacelle_{tag}", 1.12, 3.60, (x, 6.90, -0.62), H,
                   vertices=10, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
        A.cylinder(f"{ASSET}_nacelle_drum_{tag}", 0.96, 1.60, (x, 5.40, -0.62), C,
                   vertices=10, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
        A.torus(f"{ASSET}_nacelle_band_{tag}", 1.18, 0.12, (x, 7.60, -0.62), B,
                rot=(math.radians(90.0), 0.0, 0.0), major=10, minor=4)
        A.box(f"{ASSET}_nacelle_furnace_{tag}", (0.56, 0.26, 0.50), (x, 4.58, -0.62),
              F, bevel=0.0)
        A.box(f"{ASSET}_nacelle_pylon_{tag}", (0.46, 2.10, 1.60), (x, 6.60, 0.42),
              S, bevel=0.0)
    for side in (-1.0, 1.0):
        tag = "l" if side < 0 else "r"
        x = side * 5.20
        A.cylinder(f"{ASSET}_prop_hub_{tag}", 0.30, 0.60, (x, 8.85, -0.62), B,
                   vertices=8, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
        for b in range(3):
            ang = math.radians(b * 120.0)
            A.box(f"{ASSET}_prop_blade_{tag}_{b}", (0.28, 0.10, 2.30),
                  (x + math.sin(ang) * 1.15, 8.85, -0.62 + math.cos(ang) * 1.15),
                  S, rot=(ang, 0.0, 0.0), bevel=0.0)
    for side in (-1.0, 1.0):
        tag = "l" if side < 0 else "r"
        A.box(f"{ASSET}_fin_{tag}", (0.30, 3.40, 2.60), (side * 5.0, 13.5, 3.4), H, bevel=0.0)
    A.box(f"{ASSET}_tailplane", (2 * A.CELL_X + 1.60, 3.60, 0.40), (0.0, 14.60, 5.85),
          H, bevel=0.0)
    A.box(f"{ASSET}_tailplane_spar", (2 * A.CELL_X + 1.20, 0.54, 0.56), (0.0, 12.90, 5.85),
          B, bevel=0.0)
    for side in (-1.0, 1.0):
        tag = "l" if side < 0 else "r"
        A.cylinder(f"{ASSET}_thruster_{tag}", 0.86, 2.20, (side * 1.20, 14.90, 0.20),
                   S, vertices=10, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)
        A.torus(f"{ASSET}_thruster_ring_{tag}", 0.96, 0.18, (side * 1.20, A.TAIL_TIP - 0.25, 0.20),
                B, rot=(math.radians(90.0), 0.0, 0.0), major=10, minor=4)
        A.cylinder(f"{ASSET}_thruster_core_{tag}", 0.70, 0.26,
                   (side * 1.20, A.TAIL_TIP - 0.34, 0.20),
                   Am, vertices=10, rot=(math.radians(90.0), 0.0, 0.0), bevel=0.0)


def build_reactor_lod1(H, S, B, C, Am, F):
    A.box(f"{ASSET}_reactor_base", (2.50, 4.20, 0.70), (0.0, 4.20, A.KEEL_TOP + 0.95),
          H, bevel=0.0)
    A.cylinder(f"{ASSET}_reactor_housing", 1.32, 2.80, (0.0, 4.20, A.KEEL_TOP + 2.60),
               S, vertices=12, bevel=0.0)
    A.cylinder(f"{ASSET}_reactor_core", 0.94, 1.70, (0.0, 4.20, A.KEEL_TOP + 2.60),
               Am, vertices=12, bevel=0.0)
    for z in (A.KEEL_TOP + 1.55, A.KEEL_TOP + 3.65):
        A.torus(f"{ASSET}_reactor_ring_{int(z * 100)}", 1.42, 0.18, (0.0, 4.20, z), B,
                major=10, minor=4)
    A.cylinder(f"{ASSET}_reactor_cap", 1.36, 0.50, (0.0, 4.20, A.KEEL_TOP + 4.30), B,
               vertices=12, bevel=0.0)
    for side in (-1.0, 1.0):
        tag = "l" if side < 0 else "r"
        A.cylinder(f"{ASSET}_reactor_stack_{tag}", 0.44, 2.40,
                   (side * 0.92, 1.70, A.KEEL_TOP + 1.70),
                   C, vertices=10, bevel=0.0)
        A.torus(f"{ASSET}_reactor_stack_ring_{tag}", 0.52, 0.10,
                (side * 0.92, 1.70, A.KEEL_TOP + 2.70),
                B, major=10, minor=4)
        A.cylinder_between(
            f"{ASSET}_injector_trunk_{tag}", (side * 0.95, 4.20, A.KEEL_TOP + 2.20),
            (side * 2.90, 4.20, A.CELL_Z - A.CELL_R + 0.30), 0.26, C, vertices=8,
        )
        A.cylinder_between(
            f"{ASSET}_conduit_fwd_{tag}", (side * 0.72, 3.00, A.KEEL_TOP + 0.85),
            (side * 0.72, -0.60, -1.55), 0.20, C, vertices=6,
        )
        A.cylinder_between(
            f"{ASSET}_conduit_aft_{tag}", (side * 0.82, 5.60, A.KEEL_TOP + 0.85),
            (side * 1.15, 14.90, 0.35), 0.20, C, vertices=6,
        )


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
    A.clear_scene()
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene["asset_name"] = ASSET
    scene["design_variant"] = "C_twin_cell_aether_dreadnought"
    scene["production_name"] = "Crownhammer"
    scene["lod"] = LOD
    scene["forward_axis"] = "-Y"
    scene["up_axis"] = "+Z"
    scene["texture_count"] = 0

    full = palette("gearforge")
    # LOD1 merges distance-invisible splits: bronze -> trim, rust -> hull.
    mats = {
        "dark_iron": full["dark_iron"],
        "steel": full["steel"],
        "brass": full["brass"],
        "copper": full["copper"],
        "aether_glow": full["aether_glow"],
        "furnace_glow": full["furnace_glow"],
    }
    H, S, B, C, Am, F = (mats["dark_iron"], mats["steel"], mats["brass"],
                         mats["copper"], mats["aether_glow"], mats["furnace_glow"])
    build_cells_lod1(H, S, B, C, Am, F)
    build_keel_lod1(H, S, B, C)
    build_prow_lod1(H, S, B, C, Am)
    build_belly_lod1(H, S, B, C, Am, F)
    build_aft_lod1(H, S, B, C, Am, F)
    build_reactor_lod1(H, S, B, C, Am, F)
    join_by_material_lod1(mats)
    A.anchor("muzzle", (0.0, -3.46, -4.66))
    A.anchor("weapon_l", (-4.50, -6.80, -0.48))
    A.anchor("weapon_r", (4.50, -6.80, -0.48))
    A.anchor("reactor_anchor", (0.0, 4.20, A.KEEL_TOP + 2.60))
    A.anchor("engine_l", (-5.20, 8.95, -0.62))
    A.anchor("engine_r", (5.20, 8.95, -0.62))
    A.anchor("exhaust_l", (-5.20, 4.45, -0.62))
    A.anchor("exhaust_r", (5.20, 4.45, -0.62))
    A.anchor("thruster_l", (-1.20, A.TAIL_TIP - 0.45, 0.20))
    A.anchor("thruster_r", (1.20, A.TAIL_TIP - 0.45, 0.20))
    A.anchor("bow_lens", (0.0, A.PROW_TIP + 0.80, 0.85))
    A.anchor("bridge_anchor", (0.0, -10.55, -2.30))
    stats = A.mesh_stats()
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
