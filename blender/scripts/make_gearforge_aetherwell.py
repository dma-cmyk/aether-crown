"""Gearforge Aether Well (Phase 2.6A).

Aether resource / energy: vertical tower with a tall cyan core, triple
containment rings, ground conduit nodes and a copper pipe plant. The
bluest silhouette of the set.

Footprint ~9x9m, core top ~12m. Origin ground centre, front -Y.

NOTE: separate asset from the Phase 2.5A `gearforge_aether_works`
showcase dressing, which is left untouched.
"""
import os
import sys

SCRIPT_DIR = os.path.abspath(os.path.dirname(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

import bpy  # noqa: E402
from building_kit import kit  # noqa: E402
from material_lib import palette  # noqa: E402

ASSET = "gearforge_aether_well"
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
        "dark_iron", "steel", "brass", "copper", "stone", "aether_glow")}
    H, S, B, C, ST, A = (mats["dark_iron"], mats["steel"], mats["brass"],
                         mats["copper"], mats["stone"], mats["aether_glow"])

    kit.base_pad(ASSET, 9.0, 9.0, H)
    # Stepped stone base -> iron tower shaft.
    kit.T.box(f"{ASSET}_step", (7.0, 7.0, 0.5), (0.0, 0.0, 0.55), ST, bevel=0.0)
    kit.T.box(f"{ASSET}_tower", (4.2, 4.2, 5.5), (0.0, 0.0, 0.8 + 2.75), H, bevel=0.05)
    kit.T.box(f"{ASSET}_tower_trim", (4.5, 4.5, 0.35), (0.0, 0.0, 6.2), B, bevel=0.0)
    kit.T.box(f"{ASSET}_crown", (3.0, 3.0, 0.8), (0.0, 0.0, 6.3 + 0.4), S, bevel=0.04)

    # Tall core rising through the crown + triple containment rings.
    kit.T.cylinder(f"{ASSET}_core", 0.65, 5.2, (0.0, 0.0, 8.6), A, vertices=12, bevel=0.0)
    kit.T.cylinder(f"{ASSET}_core_tip", 0.3, 0.6, (0.0, 0.0, 11.4), A, vertices=10, bevel=0.0)
    for z, rr in ((7.6, 1.7), (9.3, 1.45), (10.8, 1.2)):
        kit.T.torus(f"{ASSET}_ring_{int(z * 10)}", rr, 0.12, (0.0, 0.0, z), B,
                    major=16, minor=6)
    kit.T.cylinder(f"{ASSET}_crown_housing", 1.0, 0.7, (0.0, 0.0, 7.0), B,
                   vertices=12, bevel=0.0)

    # Four ground conduit nodes feeding the tower + ground ring.
    for sx in (-1.0, 1.0):
        for sy in (-1.0, 1.0):
            nx, ny = sx * 3.4, sy * 3.4
            kit.T.cylinder(f"{ASSET}_node_base_{int(sx)}_{int(sy)}", 0.5, 0.4,
                           (nx, ny, 0.5), B, vertices=8, bevel=0.0)
            kit.T.cylinder(f"{ASSET}_node_glow_{int(sx)}_{int(sy)}", 0.28, 0.5,
                           (nx, ny, 0.85), A, vertices=8, bevel=0.0)
            kit.aether_conduit((nx, ny, 0.6), (sx * 1.6, sy * 1.6, 1.2), A,
                               f"{ASSET}_feed_{int(sx)}_{int(sy)}", r=0.09)
    kit.T.torus(f"{ASSET}_ground_ring", 3.1, 0.09, (0.0, 0.0, 0.35), A,
                major=24, minor=6)

    # Tower slit windows + side plant shed + copper services.
    for sx in (-1.0, 1.0):
        kit.T.box(f"{ASSET}_slit_{int(sx)}", (0.25, 0.14, 1.8), (sx * 1.2, -2.12, 4.2), A, bevel=0.0)
    kit.upper_block(ASSET, "shed", 2.6, 2.2, 1.8, (3.2, 2.8, 0.3 + 0.9), H, bevel=0.03)
    kit.roof_machine(f"{ASSET}_pump", 1.2, 1.0, 0.7, (-3.0, 2.6, 0.3), mats)
    kit.pipe_run((-3.0, 2.6, 1.0), (-1.8, 1.2, 1.0), 0.11, C, f"{ASSET}_service_pipe")
    kit.door_large(f"{ASSET}_entry", 1.6, 2.2, (0.0, -2.13, 0.3), mats)

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
