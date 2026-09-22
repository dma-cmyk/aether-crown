"""Gearforge Factory (Phase 2.6A).

Walker / machinery production: heavy mass with a large front gate,
gantry crane, tall chimney, boiler annex and furnace mouths. Reads as
"machines come out of here" from strategic zoom.

Footprint ~14x11m, chimney top ~12m. Origin ground centre, front -Y.
"""
import os
import sys

SCRIPT_DIR = os.path.abspath(os.path.dirname(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

import bpy  # noqa: E402
from building_kit import kit  # noqa: E402
from material_lib import palette  # noqa: E402

ASSET = "gearforge_factory"
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
    full = palette("gearforge")
    mats = {k: full[k] for k in (
        "dark_iron", "steel", "brass", "copper", "rust", "furnace_glow")}
    H, S, B, C, R, F = (mats["dark_iron"], mats["steel"], mats["brass"],
                        mats["copper"], mats["rust"], mats["furnace_glow"])

    kit.base_pad(ASSET, 14.0, 11.0, H)
    kit.hall(ASSET, 11.0, 8.0, 6.0, H, y0=0.3, bevel=0.06)
    # Clerestory monitor block along the roof ridge.
    kit.upper_block(ASSET, "monitor", 8.0, 2.2, 1.4, (0.0, 0.0, 6.3 + 0.7), S, bevel=0.03)
    kit.gable_roof(ASSET, 11.4, 8.4, 1.0, 6.3, S)

    # Large front gate + exit rails on the ground.
    kit.gate_arch(ASSET, 5.0, 4.5, (0.0, -4.05, 0.3), mats)
    for dx in (-1.1, 1.1):
        kit.T.box(f"{ASSET}_exit_rail_{int(dx * 10)}", (0.25, 4.5, 0.12),
                  (dx, -6.5, 0.06), S, bevel=0.0)

    # Workshop wing + coal bunker + second short stack on the east side.
    kit.upper_block(ASSET, "wing", 3.2, 6.0, 3.4, (5.2, 0.5, 0.3 + 1.7), H, bevel=0.04)
    kit.gable_roof(f"{ASSET}_wing", 3.6, 6.4, 0.7, 3.7, S)
    kit.T.box(f"{ASSET}_bunker", (2.4, 2.0, 1.6), (-5.8, 3.6, 0.3 + 0.8), H, bevel=0.03)
    kit.chimney(f"{ASSET}_short", 0.5, 6.5, (5.2, -2.0, 3.7), mats, glow=None, vertices=10)
    kit.pipe_run((4.6, 0.5, 1.2), (5.2, 0.5, 2.0), 0.13, C, f"{ASSET}_wing_feed")

    # Loading gantry over the exit tracks (flanks the gate rails).
    kit.crane_bridge(ASSET, 5.0, (0.0, -6.5, 0.0), mats, rail_len=5.0)

    # Tall chimney + boiler annex + vertical tank on the west side.
    kit.chimney(f"{ASSET}_main", 0.8, 11.5, (-4.2, 2.5, 0.3), mats, glow=F, vertices=12)
    kit.boiler_horizontal(f"{ASSET}_annex", 0.9, 3.6, (-4.3, -1.5, 1.5), mats, vertices=10)
    kit.tank_vertical(f"{ASSET}_feed", 0.9, 3.4, (-1.8, 4.6, 0.3), mats, vertices=10)
    kit.pipe_run((-4.3, -1.5, 2.4), (-4.2, 2.5, 3.2), 0.14, C, f"{ASSET}_riser")
    kit.pipe_elbow(f"{ASSET}_riser", (-4.2, 2.5, 3.2), 0.14, C)

    # Furnace mouths + rust vents + roof machines.
    kit.furnace_mouth(f"{ASSET}_f1", 1.1, 0.9, (-3.3, -4.02, 0.3), mats)
    kit.furnace_mouth(f"{ASSET}_f2", 1.1, 0.9, (3.3, -4.02, 0.3), mats)
    kit.vent_stack(f"{ASSET}_rustvent", 0.7, 0.8, (2.0, 2.5, 6.3), R, glow=None)
    kit.roof_machine(f"{ASSET}_roof_a", 1.8, 1.4, 0.9, (-2.5, 1.0, 6.3), mats)
    kit.roof_machine(f"{ASSET}_roof_b", 1.4, 1.2, 0.7, (1.0, -2.0, 6.3), mats)

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
