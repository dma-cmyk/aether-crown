"""Render 9 comprehensive showcase screenshots for Gearforge Map Production Kit 01.

Builds a fully assembled tactical battlefield diorama combining:
  - Canyon / Cliffs (height 8m elevation)
  - Heavy Aether Bridge (32m span crossing canyon)
  - Fortress Gate, Walls, Towers, Bastion
  - Road slabs, barriers, overland steam pipes
  - Scale proxy units: Titan (11.4m), Quad-Walker (5.2m), Walker (4.5m), Infantry (1.8m)

Screenshots:
  1. 01_map_kit_overview.png       (Panoramic battlefield diorama overview)
  2. 02_bridge_isometric.png       (Heavy bridge tactical elevation view)
  3. 03_bridge_side.png            (Canyon crossing side profile & piers)
  4. 04_bridge_titan_scale.png     (Titan & units traversing bridge)
  5. 05_cliff_modules.png          (Modular cliffs, ramp, rock & iron language)
  6. 06_fortress_gate.png          (Grand fortress gate opening & Titan clearance)
  7. 07_fortress_wall_set.png      (Defensive curtain wall, towers, bastion)
  8. 08_rts_distance.png           (Real RTS tactical gameplay camera distance)
  9. 09_road_and_props_detail.png  (Road slabs, barriers, overland pipelines)
"""

import math
import os
import sys

import bpy
from mathutils import Vector

SCRIPT_DIR = os.path.abspath(os.path.dirname(__file__))
ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
MAP_MODELS_DIR = os.path.join(ROOT, "game", "assets", "models", "map")
UNIT_MODELS_DIR = os.path.join(ROOT, "game", "assets", "models")
OUTPUT_DIR = os.path.join(ROOT, "docs", "screenshots", "map_kit_01")


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for col in (bpy.data.meshes, bpy.data.curves, bpy.data.actions, bpy.data.lights, bpy.data.cameras):
        for item in list(col):
            try:
                col.remove(item)
            except Exception:
                pass


def import_glb(rel_path, loc=(0.0, 0.0, 0.0), rot=(0.0, 0.0, 0.0), scale=(1.0, 1.0, 1.0)):
    full_path = os.path.join(ROOT, rel_path)
    if not os.path.exists(full_path):
        print(f"WARNING: File not found {full_path}")
        return None
    bpy.ops.object.select_all(action="DESELECT")
    bpy.ops.import_scene.gltf(filepath=full_path)
    imported = [o for o in bpy.context.selected_objects]
    if not imported:
        return None

    # Create a parent empty to anchor all imported objects together
    name = os.path.splitext(os.path.basename(rel_path))[0]
    bpy.ops.object.empty_add(type="PLAIN_AXES", location=loc)
    parent_empty = bpy.context.active_object
    parent_empty.name = f"{name}_anchor"
    parent_empty.rotation_euler = rot
    parent_empty.scale = scale

    top_level = [o for o in imported if o.parent is None]
    for o in top_level:
        o.parent = parent_empty
    bpy.context.view_layer.update()
    return parent_empty


def setup_lighting_and_ground():
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"

    # World lighting
    if scene.world and scene.world.node_tree:
        bg = scene.world.node_tree.nodes.get("Background")
        if bg:
            bg.inputs["Color"].default_value = (0.12, 0.14, 0.18, 1.0)
            bg.inputs["Strength"].default_value = 1.2

    # Key Sunlight (Warm industrial sunlight)
    bpy.ops.object.light_add(type="SUN", location=(35.0, -45.0, 50.0))
    sun = bpy.context.active_object
    sun.name = "Key_Sun"
    sun.data.energy = 4.5
    sun.data.color = (1.0, 0.96, 0.90)
    sun.rotation_euler = (math.radians(52.0), math.radians(16.0), math.radians(-32.0))

    # Rim / Backlight (Cool atmospheric fill)
    bpy.ops.object.light_add(type="SUN", location=(-45.0, 45.0, 38.0))
    rim = bpy.context.active_object
    rim.name = "Rim_Sun"
    rim.data.energy = 3.2
    rim.data.color = (0.75, 0.88, 1.0)
    rim.rotation_euler = (math.radians(-45.0), math.radians(-20.0), math.radians(140.0))

    # Cool blue fill light
    bpy.ops.object.light_add(type="SUN", location=(-20.0, 20.0, 30.0))
    fill = bpy.context.active_object
    fill.name = "Sky_Fill"
    fill_light = fill.data
    fill_light.energy = 0.45
    fill_light.color = (0.50, 0.72, 1.0)
    fill.rotation_euler = (math.radians(35.0), math.radians(-25.0), math.radians(35.0))

    # Vast terrain floor (Canyon valley floor at Z=0.0)
    bpy.ops.mesh.primitive_plane_add(size=250.0, location=(0.0, 0.0, -0.05))
    ground = bpy.context.active_object
    ground.name = "Canyon_Floor"
    mat_ground = bpy.data.materials.new(name="canyon_ground_mat")
    mat_ground.use_nodes = True
    bsdf = mat_ground.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        # Dark rugged industrial bedrock tone
        bsdf.inputs["Base Color"].default_value = (0.11, 0.12, 0.14, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.92
        bsdf.inputs["Metallic"].default_value = 0.08
    ground.data.materials.append(mat_ground)


def assemble_battlefield_diorama():
    """Build an interconnected modular map scene demonstrating bridge, trench, cliffs, fortress, and units."""
    print("Assembling battlefield diorama with industrial trench, fortress gate, and bridge...")

    # 1. Industrial Trench (Excavated military moat under the bridge along X axis, Y = -6 to +6)
    import_glb("game/assets/models/map/gearforge_trench_industrial.glb", loc=(-8.0, 0.0, 0.0), rot=(0, 0, math.radians(90.0)))
    import_glb("game/assets/models/map/gearforge_trench_industrial.glb", loc=( 8.0, 0.0, 0.0), rot=(0, 0, math.radians(90.0)))

    # 2. Canyon Crossing Bridge
    # Spans from Y = -16.0 (South Cliff Plateau) to Y = +16.0 (North Fortress Plateau) over the trench
    import_glb("game/assets/models/map/gearforge_bridge_heavy.glb", loc=(0.0, 0.0, 0.0))

    # 3. South Plateau & Cliffs (Y <= -16.0, Elevation Z = 8.0m)
    # Cliff face rim along Y = -16.0
    import_glb("game/assets/models/map/gearforge_cliff_straight.glb", loc=(-8.0, -18.0, 0.0), rot=(0, 0, 0))
    import_glb("game/assets/models/map/gearforge_cliff_straight.glb", loc=( 8.0, -18.0, 0.0), rot=(0, 0, 0))
    # West ramp ascending from canyon floor to South plateau
    import_glb("game/assets/models/map/gearforge_cliff_ramp.glb", loc=(-24.0, -20.0, 0.0), rot=(0, 0, 0))
    # East large mountain backdrop
    import_glb("game/assets/models/map/gearforge_cliff_large.glb", loc=(32.0, -22.0, 0.0), rot=(0, 0, 0))
    # South approaching road
    import_glb("game/assets/models/map/gearforge_road_straight.glb", loc=(0.0, -24.0, 8.0))
    import_glb("game/assets/models/map/gearforge_road_barrier.glb", loc=(-7.0, -24.0, 8.0))
    import_glb("game/assets/models/map/gearforge_road_barrier.glb", loc=( 7.0, -24.0, 8.0))

    # 4. North Fortress Perimeter & Cliffs (Y >= 16.0, Elevation Z = 8.0m)
    # North cliff rim supporting the bridge north abutment
    import_glb("game/assets/models/map/gearforge_cliff_straight.glb", loc=(-10.0, 18.0, 0.0), rot=(0, 0, math.radians(180.0)))
    import_glb("game/assets/models/map/gearforge_cliff_straight.glb", loc=( 10.0, 18.0, 0.0), rot=(0, 0, math.radians(180.0)))
    import_glb("game/assets/models/map/gearforge_cliff_corner_out.glb", loc=(-22.0, 18.0, 0.0), rot=(0, 0, math.radians(90.0)))

    # Fortress Defensive Line (Y = 28.0m, Z = 8.0m)
    # Massive Fortress Gate at center (bridge leads directly toward this gate)
    import_glb("game/assets/models/map/gearforge_fortress_gate.glb", loc=(0.0, 28.0, 8.0))
    # Right Curtain Wall + Corner + Tower
    import_glb("game/assets/models/map/gearforge_wall_straight.glb", loc=(18.0, 28.0, 8.0))
    import_glb("game/assets/models/map/gearforge_wall_corner.glb", loc=(30.0, 28.0, 8.0))
    import_glb("game/assets/models/map/gearforge_wall_tower.glb", loc=(30.0, 36.0, 8.0))
    # Left Curtain Wall + Defensive Bastion
    import_glb("game/assets/models/map/gearforge_wall_straight.glb", loc=(-18.0, 28.0, 8.0))
    import_glb("game/assets/models/map/gearforge_defensive_bastion.glb", loc=(-30.0, 26.0, 8.0))

    # Overland steam pipelines running in canyon floor along West cliff base
    import_glb("game/assets/models/map/gearforge_industrial_pipe_straight.glb", loc=(-14.0, 0.0, 0.0))
    import_glb("game/assets/models/map/gearforge_industrial_pipe_straight.glb", loc=(-14.0, 16.0, 0.0))

    # 5. Units for Scale Hierarchy (Titan, Quad-Walker, Biped Walker)
    # Titan Crownpiercer (11.4m) advancing across the bridge northward
    import_glb("game/assets/models/gearforge_titan.glb", loc=(0.0, -4.0, 8.0), rot=(0, 0, 0))

    # Medium Quad-Walker Ironbastion (5.2m) stationed at fortress gate entrance
    import_glb("game/assets/models/gearforge_medium_quad_walker.glb", loc=(0.0, 20.0, 8.0), rot=(0, 0, math.radians(180.0)))

    # Biped Walker Ironstride (4.5m) escorting on south bridge approach
    import_glb("game/assets/models/gearforge_walker.glb", loc=(-4.5, -12.0, 8.0), rot=(0, 0, 0))

    print("Battlefield diorama assembled successfully.")


def point_camera_at(cam_obj, target_loc):
    direction = Vector(target_loc) - cam_obj.location
    rot_quat = direction.to_track_quat("-Z", "Y")
    cam_obj.rotation_euler = rot_quat.to_euler()


def render_all_shots():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    clear_scene()
    setup_lighting_and_ground()
    assemble_battlefield_diorama()

    scene = bpy.context.scene
    cam_data = bpy.data.cameras.new("MapKitCamera")
    cam_data.clip_start = 0.5
    cam_data.clip_end = 500.0
    cam_obj = bpy.data.objects.new("MapKitCamera", cam_data)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj

    shots = [
        # 1. Overview (Panoramic Battlefield Diorama)
        {
            "filename": "01_map_kit_overview.png",
            "pos": (38.0, -48.0, 38.0),
            "target": (0.0, 4.0, 10.0),
            "lens": 42,
            "desc": "Panoramic battlefield diorama overview showing bridge, industrial trench, fortress gate, and Titan",
        },
        # 2. Gate Front (Fortress Gate Superstructure)
        {
            "filename": "02_fortress_gate_front.png",
            "pos": (-12.0, 2.0, 18.0),
            "target": (0.0, 28.0, 18.0),
            "lens": 30,
            "desc": "Front three-quarter view of 21m Fortress Gate showing sloped buttresses, gunports, searchlights, and cupola",
        },
        # 3. Bridge Roadway (Looking down the 14m Deck)
        {
            "filename": "03_bridge_roadway.png",
            "pos": (10.0, -22.0, 16.0),
            "target": (0.0, 4.0, 11.0),
            "lens": 36,
            "desc": "Looking down bridge deck showing glowing Aether power rails, catwalks, and advancing Titan",
        },
        # 4. Bridge Side Profile (Under-bridge Lattice Arch & Pipes)
        {
            "filename": "04_bridge_side.png",
            "pos": (46.0, 0.0, 10.0),
            "target": (0.0, 0.0, 6.5),
            "lens": 52,
            "desc": "Side profile of bridge showing under-bridge arch truss, pier machinery, and conduit lines over trench",
        },
        # 5. Trench & Ravine Chokepoint (Excavated Moat beneath Bridge)
        {
            "filename": "05_trench_ravine.png",
            "pos": (-22.0, -14.0, 14.0),
            "target": (-4.0, 0.0, 4.0),
            "lens": 42,
            "desc": "Close view of industrial trench under bridge showing steel sheet piles, pipelines, and Aether waterway",
        },
        # 6. Scale Hierarchy (Titan, Quad-Walker, Light Walker)
        {
            "filename": "06_scale_hierarchy.png",
            "pos": (16.0, -22.0, 16.0),
            "target": (0.0, -4.0, 12.0),
            "lens": 48,
            "desc": "Scale hierarchy comparison of 11.4m Titan Crownpiercer, 5.2m Quad-Walker, and 4.5m Walker",
        },
        # 7. Fortress Approach (Dramatically approaching the Fortress Gate)
        {
            "filename": "07_fortress_approach.png",
            "pos": (-12.0, -6.0, 11.0),
            "target": (0.0, 24.0, 14.0),
            "lens": 36,
            "desc": "Low tactical angle crossing bridge toward the towering 21m fortress gatehouse",
        },
        # 8. RTS Tactical Distance (Camera Distance 65m+)
        {
            "filename": "08_rts_distance.png",
            "pos": (44.0, -54.0, 54.0),
            "target": (0.0, 6.0, 8.0),
            "lens": 38,
            "desc": "Standard RTS gameplay distance readability check with clear silhouette hierarchy",
        },
        # 9. Industrial Detail (Catwalks, Retaining Walls, Barriers, Pipes)
        {
            "filename": "09_road_and_props_detail.png",
            "pos": (16.0, -28.0, 14.0),
            "target": (-2.0, -20.0, 8.0),
            "lens": 35,
            "desc": "Close detail of bridge crash barriers, Aether beacons, retaining walls, and gantry pipes",
        },
    ]

    filter_names = [arg for arg in sys.argv if arg.endswith(".png")]
    if filter_names:
        shots = [s for s in shots if s["filename"] in filter_names]
        print(f"Filtered to {len(shots)} shots: {[s['filename'] for s in shots]}")

    for idx, shot in enumerate(shots):
        cam_obj.location = shot["pos"]
        cam_data.lens = shot["lens"]
        point_camera_at(cam_obj, shot["target"])
        bpy.context.view_layer.update()

        out_path = os.path.join(OUTPUT_DIR, shot["filename"])
        scene.render.filepath = out_path
        print(f"[{idx+1}/{len(shots)}] Rendering {shot['filename']} ({shot['desc']})...")
        bpy.ops.render.render(write_still=True)
        print(f"      Saved: {out_path} ({os.path.getsize(out_path)} bytes)")

    print("ALL_MAP_KIT_SCREENSHOTS_RENDERED_OK")


if __name__ == "__main__":
    render_all_shots()

