"""Render showcase screenshots for the Gearforge Ironbastion medium quad-walker.

Outputs 6 high-quality screenshots to docs/screenshots/gemini_quad_walker/
  1. 01_isometric_rts.png       (Classic RTS tactical elevation view)
  2. 02_front_view.png          (Frontal glacis, sensor visor, twin cannon menace)
  3. 03_side_profile.png        (Locomotion stance, hydraulics, balance of mass)
  4. 04_rear_quarter.png        (Boiler, twin stacks, Aether regulator, ammo bustle)
  5. 05_top_down.png            (Footprint, traverse ring, armament layout)
  6. 06_detail_turret_closeup.  (Twin recoil buffers, muzzle brakes, commander cupola)
"""

import math
import os
import sys

import bpy
from mathutils import Vector

SCRIPT_DIR = os.path.abspath(os.path.dirname(__file__))
ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
BLEND_PATH = os.path.join(ROOT, "blender", "source", "gearforge_medium_quad_walker.blend")
OUTPUT_DIR = os.path.join(ROOT, "docs", "screenshots", "gemini_quad_walker")


def setup_studio_lighting():
    """Create a 3-point industrial lighting setup with rim lights."""
    # Key Light (Warm sunlight from high front-right)
    bpy.ops.object.light_add(type="SUN", location=(8.0, -10.0, 12.0))
    key = bpy.context.active_object
    key.name = "Key_Sun"
    key.data.energy = 4.5
    key.data.color = (1.0, 0.96, 0.90)
    key.rotation_euler = (math.radians(45.0), math.radians(15.0), math.radians(-35.0))

    # Rim / Back Light (Cool crisp highlight from high rear-left)
    bpy.ops.object.light_add(type="SUN", location=(-10.0, 10.0, 10.0))
    rim = bpy.context.active_object
    rim.name = "Rim_Sun"
    rim.data.energy = 3.5
    rim.data.color = (0.75, 0.88, 1.0)
    rim.rotation_euler = (math.radians(-50.0), math.radians(-25.0), math.radians(130.0))

    # Fill Light (Subtle warm fill from front-left)
    bpy.ops.object.light_add(type="SUN", location=(-8.0, -6.0, 6.0))
    fill = bpy.context.active_object
    fill.name = "Fill_Sun"
    fill.data.energy = 2.0
    fill.data.color = (0.85, 0.85, 0.85)
    fill.rotation_euler = (math.radians(35.0), math.radians(-20.0), math.radians(40.0))

    # Ground plane shadow receiver
    bpy.ops.mesh.primitive_plane_add(size=40.0, location=(0.0, 0.0, 0.0))
    ground = bpy.context.active_object
    ground.name = "Ground_Plane"
    mat_ground = bpy.data.materials.new(name="studio_ground")
    mat_ground.use_nodes = True
    bsdf = mat_ground.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (0.12, 0.13, 0.15, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.85
        bsdf.inputs["Metallic"].default_value = 0.1
    ground.data.materials.append(mat_ground)


def point_camera_at(cam_obj, target_loc):
    direction = Vector(target_loc) - cam_obj.location
    rot_quat = direction.to_track_quat("-Z", "Y")
    cam_obj.rotation_euler = rot_quat.to_euler()


def render_shots():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 1920
    scene.render.resolution_y = 1080
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"

    # Color management for punchy industrial contrast
    scene.view_settings.view_transform = "Filmic" if "Filmic" in [c.name for c in scene.view_settings.bl_rna.properties["view_transform"].enum_items] else "Standard"
    try:
        scene.view_settings.look = "Medium High Contrast"
    except Exception:
        pass

    # Create camera
    cam_data = bpy.data.cameras.new("ShowcaseCamera")
    cam_data.clip_start = 0.1
    cam_data.clip_end = 200.0
    cam_obj = bpy.data.objects.new("ShowcaseCamera", cam_data)
    scene.collection.objects.link(cam_obj)
    scene.camera = cam_obj

    setup_studio_lighting()

    # Ambient world lighting
    if scene.world and scene.world.node_tree:
        bg = scene.world.node_tree.nodes.get("Background")
        if bg:
            bg.inputs["Color"].default_value = (0.10, 0.11, 0.14, 1.0)
            bg.inputs["Strength"].default_value = 1.0

    shots = [
        {
            "filename": "01_isometric_rts.png",
            "pos": (10.0, -11.5, 9.0),
            "target": (0.0, -0.8, 2.7),
            "lens": 50,
            "desc": "Isometric RTS perspective view",
        },
        {
            "filename": "02_front_view.png",
            "pos": (0.0, -13.5, 3.8),
            "target": (0.0, -1.0, 2.7),
            "lens": 48,
            "desc": "Front view showing dual cannons, sensor slit and stance",
        },
        {
            "filename": "03_side_profile.png",
            "pos": (-14.5, -0.8, 3.4),
            "target": (0.0, -0.8, 2.7),
            "lens": 48,
            "desc": "Side profile showing articulation, boiler, and recoil cannons",
        },
        {
            "filename": "04_rear_quarter.png",
            "pos": (9.0, 10.5, 7.2),
            "target": (0.0, 0.0, 2.9),
            "lens": 50,
            "desc": "Rear quarter showing twin exhaust stacks, boiler and Aether core",
        },
        {
            "filename": "05_top_down.png",
            "pos": (0.0, -1.6, 24.0),
            "target": (0.0, -1.2, 2.5),
            "lens": 42,
            "desc": "Top-down layout showing 4-point stance and turret traverse",
        },
        {
            "filename": "06_detail_turret_closeup.png",
            "pos": (4.2, -5.8, 4.8),
            "target": (0.2, -1.8, 4.1),
            "lens": 65,
            "desc": "Closeup of twin recoil cannons, brass muzzle brakes and cupola",
        },
    ]

    for idx, shot in enumerate(shots):
        cam_obj.location = shot["pos"]
        cam_data.lens = shot["lens"]
        point_camera_at(cam_obj, shot["target"])
        bpy.context.view_layer.update()

        out_path = os.path.join(OUTPUT_DIR, shot["filename"])
        scene.render.filepath = out_path
        print(f"[{idx+1}/6] Rendering {shot['filename']} ({shot['desc']})...")
        bpy.ops.render.render(write_still=True)
        print(f"      Saved: {out_path} ({os.path.getsize(out_path)} bytes)")

    print("ALL_SCREENSHOTS_RENDERED_OK")


if __name__ == "__main__":
    render_shots()
