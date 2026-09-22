"""Gearforge HQ Command Core (Phase 2.6A).

Faction landmark: broad command mass, twin side towers, tall central Aether
spire with containment rings. Largest of the set, readable as HQ from far.

Footprint ~14x12m, spire top ~13.5m. Origin ground centre, front -Y.
"""
import os
import sys

SCRIPT_DIR = os.path.abspath(os.path.dirname(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

import bpy  # noqa: E402
from building_kit import kit  # noqa: E402
from material_lib import palette  # noqa: E402

ASSET = "gearforge_hq_command"
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
        "dark_iron", "steel", "brass", "copper", "stone",
        "aether_glow", "furnace_glow")}
    H, S, B, C, ST, A, F = (mats["dark_iron"], mats["steel"], mats["brass"],
                            mats["copper"], mats["stone"],
                            mats["aether_glow"], mats["furnace_glow"])

    kit.base_pad(ASSET, 14.0, 12.0, H)
    kit.T.box(f"{ASSET}_step_outer", (15.2, 13.2, 0.16), (0.0, 0.0, 0.08), H, bevel=0.0)
    kit.hall(ASSET, 9.5, 7.5, 4.5, H, y0=0.3, bevel=0.06)
    kit.upper_block(ASSET, "command", 7.0, 5.5, 2.6, (0.0, 0.3, 4.8 + 1.3), S, bevel=0.05)
    kit.gable_roof(ASSET, 7.4, 5.9, 1.1, 7.4, S)

    # Side annex wings with shed roofs (command staff blocks).
    for sx in (-1.0, 1.0):
        side = "l" if sx < 0 else "r"
        kit.upper_block(ASSET, f"annex_{side}", 2.6, 5.0, 2.6, (sx * 6.0, 0.5, 0.3 + 1.3), H, bevel=0.03)
        kit.gable_roof(f"{ASSET}_annex_{side}", 3.0, 5.4, 0.6, 2.9, S)
        kit.T.box(f"{ASSET}_annex_slit_{side}", (0.25, 0.14, 1.0), (sx * 6.0, -2.05, 1.8), A, bevel=0.0)

    # Twin side towers with caps + cyan slit windows (HQ symmetry anchor).
    for sx in (-1.0, 1.0):
        side = "l" if sx < 0 else "r"
        x = sx * 5.6
        kit.T.box(f"{ASSET}_tower_{side}", (2.4, 2.4, 8.0), (x, 0.5, 0.3 + 4.0), H, bevel=0.05)
        kit.T.box(f"{ASSET}_tower_cap_{side}", (2.8, 2.8, 0.5), (x, 0.5, 8.55), B, bevel=0.0)
        kit.T.box(f"{ASSET}_tower_slit_{side}", (0.3, 0.15, 1.6), (x, -0.75, 6.2), A, bevel=0.0)

    # Central Aether spire: housing -> core -> twin rings -> crown lens.
    kit.T.cylinder(f"{ASSET}_spire_base", 1.5, 1.2, (0.0, 0.3, 8.0), B, vertices=12, bevel=0.0)
    kit.T.cylinder(f"{ASSET}_spire_core", 0.72, 4.2, (0.0, 0.3, 10.4), A, vertices=12, bevel=0.0)
    for z, rr in ((9.0, 1.5), (10.2, 1.35), (11.4, 1.15)):
        kit.T.torus(f"{ASSET}_spire_ring_{int(z * 10)}", rr, 0.13, (0.0, 0.3, z), B,
                    major=16, minor=6)
    kit.T.cylinder(f"{ASSET}_spire_lens", 0.4, 0.5, (0.0, 0.3, 12.7), A, vertices=10, bevel=0.0)
    kit.T.cylinder(f"{ASSET}_spire_crown", 0.62, 0.35, (0.0, 0.3, 12.35), B, vertices=10, bevel=0.0)

    # Energy feeds from spire base to both towers.
    for sx in (-1.0, 1.0):
        kit.aether_conduit((sx * 1.2, 0.3, 8.2), (sx * 4.6, 0.5, 6.6), A,
                           f"{ASSET}_spire_feed_{int(sx)}", r=0.11)

    # Command gate + flanking copper services + guarded hearth.
    kit.door_large(ASSET, 2.6, 3.2, (0.0, -3.78, 0.3), mats)
    kit.pipe_run((-4.2, -3.4, 0.8), (4.2, -3.4, 0.8), 0.13, C, f"{ASSET}_base_pipe")
    kit.furnace_mouth(f"{ASSET}_hearth", 0.9, 0.7, (3.4, -3.55, 0.3), mats)
    kit.vent_stack(f"{ASSET}_vent", 0.7, 1.1, (-3.6, 2.8, 4.8), S, glow=None)

    # Rear service boiler + short stack (HQ runs its own plant).
    kit.boiler_horizontal(f"{ASSET}_plant", 0.8, 3.0, (0.0, 4.6, 1.4), mats, vertices=10)
    kit.chimney(f"{ASSET}_plant", 0.45, 5.0, (2.6, 4.4, 0.3), mats, glow=F, vertices=10)
    kit.pipe_elbow(f"{ASSET}_plant", (1.6, 4.6, 1.4), 0.13, C)

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
