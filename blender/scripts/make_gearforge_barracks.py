"""Gearforge Barracks (Phase 2.6A).

Infantry production: low, wide, fortified mass. Parapet + corner posts +
buttressed yard walls + twin armory doors read as military at RTS distance.

Footprint ~12x8m, top ~5.5m. Origin ground centre, front -Y.
"""
import os
import sys

SCRIPT_DIR = os.path.abspath(os.path.dirname(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

import bpy  # noqa: E402
from building_kit import kit  # noqa: E402
from material_lib import palette  # noqa: E402

ASSET = "gearforge_barracks"
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
        "dark_iron", "steel", "brass", "copper", "rust", "aether_glow")}
    H, S, B, C, R, A = (mats["dark_iron"], mats["steel"], mats["brass"],
                        mats["copper"], mats["rust"], mats["aether_glow"])

    kit.base_pad(ASSET, 12.0, 8.0, H)
    kit.hall(ASSET, 10.0, 6.0, 3.2, H, y0=0.3, bevel=0.05)
    kit.T.box(f"{ASSET}_trim_band", (10.2, 6.2, 0.3), (0.0, 0.0, 3.35), B, bevel=0.0)
    kit.parapet(ASSET, 10.0, 6.0, 0.8, 3.5, S)

    # Watch / signal tower on the rear corner.
    kit.T.box(f"{ASSET}_watch", (2.0, 2.0, 5.0), (-3.6, 1.6, 0.3 + 2.5), H, bevel=0.04)
    kit.gable_roof(f"{ASSET}_watch", 2.4, 2.4, 0.7, 5.3, B)
    kit.T.box(f"{ASSET}_watch_lamp", (0.3, 0.15, 0.4), (-3.6, 0.55, 4.4), A, bevel=0.0)

    # Twin armory doors on the front + yard walls with buttresses.
    kit.door_large(f"{ASSET}_door_w", 1.8, 2.4, (-2.4, -3.03, 0.3), mats)
    kit.door_large(f"{ASSET}_door_e", 1.8, 2.4, (2.4, -3.03, 0.3), mats)
    kit.wall_segment(f"{ASSET}_yard_w", 3.4, 1.8, (-5.6, -1.0, 0.0), mats)
    kit.wall_segment(f"{ASSET}_yard_e", 3.4, 1.8, (5.6, -1.0, 0.0), mats)

    # Storage annex + gate pylons (mass without height).
    kit.upper_block(ASSET, "stores", 3.0, 2.4, 2.0, (3.2, 1.4, 0.3 + 1.0), H, bevel=0.03)
    kit.gable_roof(f"{ASSET}_stores", 3.4, 2.8, 0.5, 2.3, S)
    for sx in (-1.0, 1.0):
        kit.T.box(f"{ASSET}_gate_pylon_{int(sx)}", (0.5, 0.5, 2.8),
                  (sx * 4.4, -3.2, 0.3 + 1.4), S, bevel=0.0)

    # Roof workshop clutter: vents + machine + stovepipe.
    kit.vent_stack(f"{ASSET}_vent", 0.8, 1.0, (1.5, 1.2, 3.5), S, glow=None)
    kit.roof_machine(f"{ASSET}_shop", 1.6, 1.2, 0.8, (-1.2, -1.0, 3.5), mats)
    kit.chimney(f"{ASSET}_stove", 0.28, 2.6, (3.4, 1.8, 3.5), mats, glow=None, vertices=8)
    kit.pipe_run((-4.6, 2.9, 0.7), (4.6, 2.9, 0.7), 0.11, C, f"{ASSET}_rear_pipe")
    kit.vent_stack(f"{ASSET}_rustvent", 0.6, 0.7, (0.2, -2.2, 3.5), R, glow=None)

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
