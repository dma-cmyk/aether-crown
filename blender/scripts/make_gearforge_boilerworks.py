"""Gearforge Boiler Works (Phase 2.6A).

Industrial economy: twin horizontal boilers, vertical tanks, three stacks,
pipe network and furnace mouths. Chimney-led silhouette, distinct from the
single-stack factory.

Footprint ~10x9m, tall stack top ~11m. Origin ground centre, front -Y.

NOTE: separate asset from the Phase 2.5A `gearforge_boiler_house`
(showcase/visual_slice dressing), which is left untouched.
"""
import os
import sys

SCRIPT_DIR = os.path.abspath(os.path.dirname(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

import bpy  # noqa: E402
from building_kit import kit  # noqa: E402
from material_lib import palette  # noqa: E402

ASSET = "gearforge_boiler_works"
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

    kit.base_pad(ASSET, 10.0, 9.0, H)
    kit.hall(ASSET, 7.5, 6.5, 4.2, H, y0=0.3, bevel=0.05)
    kit.gable_roof(ASSET, 7.9, 6.9, 0.9, 4.5, S)

    # Twin horizontal boilers flanking the hall + vertical tanks behind.
    kit.boiler_horizontal(f"{ASSET}_boiler_w", 0.85, 3.4, (-4.6, -0.5, 1.3), mats, vertices=10)
    kit.boiler_horizontal(f"{ASSET}_boiler_e", 0.85, 3.4, (4.6, -0.5, 1.3), mats, vertices=10)
    kit.tank_vertical(f"{ASSET}_tank_w", 0.8, 3.2, (-2.6, 3.6, 0.3), mats, vertices=10)
    kit.tank_vertical(f"{ASSET}_tank_e", 0.8, 3.2, (2.6, 3.6, 0.3), mats, vertices=10)

    # Three-stack rhythm: one tall glowing + two short.
    kit.chimney(f"{ASSET}_tall", 0.7, 10.5, (0.0, 1.8, 0.3), mats, glow=F, vertices=12)
    kit.chimney(f"{ASSET}_short_w", 0.5, 6.0, (-2.8, -2.2, 4.5), mats, glow=None, vertices=10)
    kit.chimney(f"{ASSET}_short_e", 0.5, 6.0, (2.8, -2.2, 4.5), mats, glow=None, vertices=10)

    # Pipe network tying boilers -> hall -> tanks.
    kit.pipe_run((-4.6, -0.5, 2.2), (-3.75, -0.5, 2.2), 0.13, C, f"{ASSET}_feed_w")
    kit.pipe_run((3.75, -0.5, 2.2), (4.6, -0.5, 2.2), 0.13, C, f"{ASSET}_feed_e")
    kit.pipe_run((-2.6, 3.6, 3.0), (2.6, 3.6, 3.0), 0.12, C, f"{ASSET}_tank_link")
    kit.pipe_elbow(f"{ASSET}_link", (2.6, 3.6, 3.0), 0.12, C)

    # Coal shed annex + furnace mouths + rust vents.
    kit.upper_block(ASSET, "shed", 3.0, 2.4, 2.0, (0.0, -4.2, 0.3 + 1.0), H, bevel=0.03)
    kit.furnace_mouth(f"{ASSET}_f1", 1.0, 0.8, (-2.2, -3.28, 0.3), mats)
    kit.furnace_mouth(f"{ASSET}_f2", 1.0, 0.8, (2.2, -3.28, 0.3), mats)
    kit.vent_stack(f"{ASSET}_rust_a", 0.7, 0.8, (-1.5, -1.5, 4.5), R, glow=None)
    kit.vent_stack(f"{ASSET}_rust_b", 0.7, 0.8, (1.5, -1.5, 4.5), R, glow=None)
    kit.door_large(f"{ASSET}_service", 1.6, 2.2, (0.0, -3.28, 0.3), mats)

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
