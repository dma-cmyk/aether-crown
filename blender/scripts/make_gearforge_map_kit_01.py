"""Build the Gearforge Map Production Kit 01 (Bridge / Cliff / Fortress Modular Set).

Outputs:
  blender/source/gearforge_map_kit_01.blend
  game/assets/models/map/gearforge_bridge_heavy.glb
  game/assets/models/map/gearforge_cliff_straight.glb
  game/assets/models/map/gearforge_cliff_corner_in.glb
  game/assets/models/map/gearforge_cliff_corner_out.glb
  game/assets/models/map/gearforge_cliff_ramp.glb
  game/assets/models/map/gearforge_cliff_large.glb
  game/assets/models/map/gearforge_fortress_gate.glb
  game/assets/models/map/gearforge_wall_straight.glb
  game/assets/models/map/gearforge_wall_corner.glb
  game/assets/models/map/gearforge_wall_tower.glb
  game/assets/models/map/gearforge_defensive_bastion.glb
  game/assets/models/map/gearforge_road_straight.glb
  game/assets/models/map/gearforge_road_barrier.glb
  game/assets/models/map/gearforge_industrial_pipe_straight.glb

Conventions:
  Metric 1 unit = 1 meter.
  Blender coordinates: X right, Y depth (front = -Y), Z up.
  glTF exports Y-up (Blender -Y -> Godot +Z).
  PBR materials via shared material_lib palette (Principled BSDF only, 0 textures).
  Modular 4m / 8m / 16m grid alignment.
"""

import math
import os
import sys

import bpy
from mathutils import Vector, Matrix

SCRIPT_DIR = os.path.abspath(os.path.dirname(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

from material_lib import palette  # noqa: E402

ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
SOURCE_BLEND = os.path.join(ROOT, "blender", "source", "gearforge_map_kit_01.blend")
MAP_MODELS_DIR = os.path.join(ROOT, "game", "assets", "models", "map")
INTERMEDIATE_DIR = os.path.join(ROOT, "blender", "exports", "map")


# ------------------------------------------------------------ Geometry Helpers

def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for col in (bpy.data.meshes, bpy.data.curves, bpy.data.actions):
        for item in list(col):
            try:
                col.remove(item)
            except Exception:
                pass


def get_materials():
    full = palette("gearforge")
    return {
        "dark_iron": full["dark_iron"],
        "steel": full["steel"],
        "brass": full["brass"],
        "copper": full["copper"],
        "stone": full["stone"],
        "aether_glow": full["aether_glow"],
        "furnace_glow": full["furnace_glow"],
    }


def apply_transform(obj, location=False, rotation=True, scale=True):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=location, rotation=rotation, scale=scale)
    obj.select_set(False)


def add_bevel(obj, width=0.04):
    if width <= 0.0:
        return
    bevel = obj.modifiers.new(name="bevel", type="BEVEL")
    bevel.width = width
    bevel.segments = 1
    bevel.limit_method = "ANGLE"
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    obj.select_set(False)


def box(name, size, loc, mat, rot=(0.0, 0.0, 0.0), bevel=0.03):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc, rotation=rot)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = size
    apply_transform(obj)
    if bevel > 0.0:
        add_bevel(obj, min(bevel, min(size) * 0.2))
    obj.data.materials.append(mat)
    return obj


def cylinder(name, radius, depth, loc, mat, vertices=12, rot=(0.0, 0.0, 0.0), bevel=0.0):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        location=loc,
        rotation=rot,
    )
    obj = bpy.context.active_object
    obj.name = name
    apply_transform(obj)
    if bevel > 0.0:
        add_bevel(obj, min(bevel, radius * 0.2))
    obj.data.materials.append(mat)
    return obj


def torus(name, major_r, minor_r, loc, mat, rot=(0.0, 0.0, 0.0), major_seg=14, minor_seg=6):
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major_r,
        minor_radius=minor_r,
        location=loc,
        rotation=rot,
        major_segments=major_seg,
        minor_segments=minor_seg,
    )
    obj = bpy.context.active_object
    obj.name = name
    apply_transform(obj)
    obj.data.materials.append(mat)
    return obj


def cylinder_between(name, p1, p2, radius, mat, vertices=10, bevel=0.0):
    a, b = Vector(p1), Vector(p2)
    delta = b - a
    length = delta.length
    if length < 1e-6:
        return None
    mid = (a + b) * 0.5
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=length, location=mid)
    obj = bpy.context.active_object
    obj.name = name
    up = Vector((0.0, 0.0, 1.0))
    rot_diff = up.rotation_difference(delta.normalized())
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = rot_diff
    apply_transform(obj)
    if bevel > 0.0:
        add_bevel(obj, min(bevel, radius * 0.2))
    obj.data.materials.append(mat)
    return obj


def box_between(name, p1, p2, width, depth, mat, bevel=0.03):
    a, b = Vector(p1), Vector(p2)
    delta = b - a
    length = delta.length
    if length < 1e-6:
        return None
    mid = (a + b) * 0.5
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=mid)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = (width, depth, length)
    apply_transform(obj)
    up = Vector((0.0, 0.0, 1.0))
    rot_diff = up.rotation_difference(delta.normalized())
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = rot_diff
    apply_transform(obj)
    if bevel > 0.0:
        add_bevel(obj, min(bevel, min(width, depth) * 0.2))
    obj.data.materials.append(mat)
    return obj


def trapezoid(name, bottom_w, bottom_d, top_w, top_d, height, loc, mat, rot=(0.0, 0.0, 0.0), bevel=0.03):
    """Create a tapered trapezoidal prism for heavy foundations and ramparts."""
    bw, bd = bottom_w * 0.5, bottom_d * 0.5
    tw, td = top_w * 0.5, top_d * 0.5
    hz = height * 0.5
    verts = [
        (-bw, -bd, -hz), (bw, -bd, -hz), (bw, bd, -hz), (-bw, bd, -hz),
        (-tw, -td,  hz), (tw, -td,  hz), (tw, td,  hz), (-tw, td,  hz)
    ]
    faces = [
        (0, 1, 2, 3), (4, 7, 6, 5), (0, 4, 5, 1),
        (1, 5, 6, 2), (2, 6, 7, 3), (3, 7, 4, 0)
    ]
    mesh = bpy.data.meshes.new(name + "_mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = loc
    obj.rotation_euler = rot
    apply_transform(obj)
    if bevel > 0.0:
        add_bevel(obj, bevel)
    obj.data.materials.append(mat)
    return obj


def anchor(name, loc):
    bpy.ops.object.empty_add(type="PLAIN_AXES", location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.empty_display_size = 0.5
    return obj


def join_all_into_asset(asset_name):
    """Join all mesh objects currently in scene into a single clean LOD0 mesh with origin at (0,0,0)."""
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        return None
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.join()
    joined = bpy.context.active_object
    joined.name = f"{asset_name}_lod0"
    joined.data.name = f"{asset_name}_lod0_mesh"

    # Set origin to world (0,0,0) without moving vertices
    bpy.context.scene.cursor.location = (0.0, 0.0, 0.0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    return joined


def export_single_glb(out_path):
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=out_path,
        export_format="GLB",
        use_selection=False,
        export_apply=True,
        export_yup=True,
        export_normals=True,
        export_materials="EXPORT",
        export_animations=False,
    )
    print(f"EXPORTED_GLB {out_path} ({os.path.getsize(out_path)} bytes)")


def measure_asset_stats(obj):
    obj.data.calc_loop_triangles()
    tris = len(obj.data.loop_triangles)
    polys = len(obj.data.polygons)
    verts = len(obj.data.vertices)
    mats = len([s for s in obj.material_slots if s.material])
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for corner in obj.bound_box:
        world = obj.matrix_world @ Vector(corner)
        for i in range(3):
            lo[i] = min(lo[i], world[i])
            hi[i] = max(hi[i], world[i])
    dims = hi - lo
    print(f"ASSET_STATS name={obj.name} tris={tris} polys={polys} verts={verts} mats={mats} "
          f"size=({dims.x:.2f} x {dims.y:.2f} x {dims.z:.2f}) bounds_z=[{lo.z:.2f}, {hi.z:.2f}]")
    return {
        "name": obj.name,
        "tris": tris,
        "polys": polys,
        "verts": verts,
        "mats": mats,
        "size": (dims.x, dims.y, dims.z),
        "bounds": ((lo.x, hi.x), (lo.y, hi.y), (lo.z, hi.z))
    }


# ==============================================================================
# ASSET BUILDERS
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Gearforge Heavy Aether Bridge (Titan-capable military bridge)
# ------------------------------------------------------------------------------
def build_bridge_heavy(mats):
    """Heavy military bridge module: 32m span, 18m overall width (14m clear roadway), deck at Z=8.0m."""
    clear_scene()
    H = mats["dark_iron"]
    S = mats["steel"]
    B = mats["brass"]
    C = mats["copper"]
    ST = mats["stone"]
    G_AETHER = mats["aether_glow"]

    SPAN = 32.0   # Length Y: -16.0 to +16.0
    DECK_Z = 8.0  # Roadway height
    ROAD_W = 14.0 # Clear width between curbs
    TOTAL_W = 18.0

    # 1. Pier Foundations (Two massive tapered masonry & iron pillars at Y = -9.0 and Y = +9.0)
    for py in (-9.0, 9.0):
        # Stone footing in canyon floor
        trapezoid(f"bridge_pier_stone_{int(py)}", 16.0, 6.0, 14.0, 4.8, 4.0,
                  (0.0, py, 2.0), ST, bevel=0.08)
        # Dark iron structural pier rising to deck
        box(f"bridge_pier_iron_{int(py)}", (13.5, 4.2, 3.8), (0.0, py, 5.9), H, bevel=0.06)
        # Brass expansion bearing plate
        box(f"bridge_pier_bearing_{int(py)}", (14.0, 4.6, 0.3), (0.0, py, 7.85), B, bevel=0.02)
        # Heavy reinforcement braces on piers
        for bx in (-5.5, 5.5):
            cylinder(f"bridge_pier_brace_{int(py)}_{int(bx)}", 0.35, 4.2, (bx, py, 5.8), S, vertices=8)

    # 2. Main Longitudinal Steel Box Girders & Cross Beams
    for gx in (-7.2, 7.2):
        # Heavy outer longitudinal box girder under deck
        box(f"bridge_main_girder_{int(gx)}", (1.2, SPAN, 1.4), (gx, 0.0, DECK_Z - 0.7), H, bevel=0.04)
        # Secondary inner girder
        box(f"bridge_sub_girder_{int(gx)}", (0.8, SPAN, 1.0), (gx * 0.45, 0.0, DECK_Z - 0.5), H, bevel=0.03)

    # Transverse cross beams every 4m along the span
    for y_step in range(-14, 15, 4):
        box(f"bridge_crossbeam_{y_step}", (TOTAL_W - 0.8, 0.7, 0.9), (0.0, float(y_step), DECK_Z - 0.45), S, bevel=0.03)
        # Copper hydraulic vibration dampers under deck
        cylinder(f"bridge_damper_{y_step}", 0.18, 1.8, (0.0, float(y_step), DECK_Z - 1.2), C,
                 vertices=8, rot=(0.0, math.radians(90.0), 0.0))

    # 3. Titan-Reinforced Roadway Deck (Z = 8.0m)
    # Heavy steel armor roadway deck slab
    box("bridge_deck_slab", (ROAD_W, SPAN, 0.40), (0.0, 0.0, DECK_Z), S, bevel=0.03)
    # Central Titan trackway plate (textured heavy iron lane)
    box("bridge_titan_lane", (7.0, SPAN, 0.06), (0.0, 0.0, DECK_Z + 0.23), H, bevel=0.01)
    # Lateral antiskid ridges every 2m
    for y_ridge in range(-15, 16, 2):
        box(f"bridge_deck_rib_{y_ridge}", (ROAD_W - 0.6, 0.25, 0.04),
            (0.0, float(y_ridge), DECK_Z + 0.22), S, bevel=0.01)

    # 4. Heavy Industrial Railings & Side Trusses
    for sx in (-1.0, 1.0):
        side_x = sx * (TOTAL_W * 0.5 - 0.8) # ±8.2m
        curb_x = sx * (ROAD_W * 0.5 + 0.3)  # ±7.3m
        side_tag = "l" if sx < 0 else "r"

        # Continuous wheel curb / crash barrier
        box(f"bridge_curb_{side_tag}", (0.8, SPAN, 0.7), (curb_x, 0.0, DECK_Z + 0.35), H, bevel=0.04)

        # Industrial open truss railing posts (every 4m)
        for y_post in range(-16, 17, 4):
            # Vertical stanchion
            box(f"bridge_post_{side_tag}_{y_post}", (0.5, 0.5, 2.2),
                (side_x, float(y_post), DECK_Z + 1.1), H, bevel=0.03)
            # Brass joint cap
            cylinder(f"bridge_post_cap_{side_tag}_{y_post}", 0.22, 0.15,
                     (side_x, float(y_post), DECK_Z + 2.2), B, vertices=10)
            # Aether warning lantern on alternating posts
            if y_post in (-12, -4, 4, 12):
                box(f"bridge_lantern_{side_tag}_{y_post}", (0.28, 0.28, 0.40),
                    (side_x - sx * 0.35, float(y_post), DECK_Z + 1.8), B, bevel=0.02)
                cylinder(f"bridge_lantern_glow_{side_tag}_{y_post}", 0.08, 0.25,
                         (side_x - sx * 0.35, float(y_post), DECK_Z + 1.8), G_AETHER, vertices=8)

        # Continuous top and mid handrails
        cylinder(f"bridge_rail_top_{side_tag}", 0.10, SPAN,
                 (side_x, 0.0, DECK_Z + 2.1), B, vertices=10, rot=(math.radians(90.0), 0.0, 0.0))
        cylinder(f"bridge_rail_mid_{side_tag}", 0.08, SPAN,
                 (side_x, 0.0, DECK_Z + 1.2), S, vertices=8, rot=(math.radians(90.0), 0.0, 0.0))

        # Diagonal reinforcement cross trusses between stanchions
        for y_truss in range(-14, 15, 4):
            box(f"bridge_diag_truss_{side_tag}_{y_truss}", (0.15, 3.8, 0.25),
                (side_x, float(y_truss), DECK_Z + 1.6), S,
                rot=(math.radians(24.0 * sx), 0.0, 0.0), bevel=0.02)

    # 5. External Exposed High-Pressure Conduit & Aether Power Line
    # Giant copper steam pipe along right side under railing
    cylinder("bridge_steam_pipe", 0.30, SPAN, (8.7, 0.0, DECK_Z - 0.2), C,
             vertices=12, rot=(math.radians(90.0), 0.0, 0.0))
    for yp in range(-12, 13, 8):
        torus(f"bridge_steam_collar_{yp}", 0.33, 0.05, (8.7, float(yp), DECK_Z - 0.2), B,
              rot=(math.radians(90.0), 0.0, 0.0))

    # Glowing Aether Conduit along left side
    cylinder("bridge_aether_pipe", 0.22, SPAN, (-8.7, 0.0, DECK_Z - 0.2), G_AETHER,
             vertices=10, rot=(math.radians(90.0), 0.0, 0.0))
    # Brass containment rings along Aether pipe
    for yp in range(-14, 15, 4):
        torus(f"bridge_aether_ring_{yp}", 0.25, 0.04, (-8.7, float(yp), DECK_Z - 0.2), B,
              rot=(math.radians(90.0), 0.0, 0.0))

    # Connection sockets / alignment anchors at bridge ends
    anchor("connect_north", (0.0, 16.0, DECK_Z))
    anchor("connect_south", (0.0, -16.0, DECK_Z))

    joined = join_all_into_asset("gearforge_bridge_heavy")
    return joined


# ------------------------------------------------------------------------------
# 2. Modular Cliff Set (Height 8.0m standard plateau level)
# ------------------------------------------------------------------------------
def build_cliff_straight(mats):
    """Straight Cliff: Width 16m (X), Depth 8m (Y), Height 8m (Z). Flat top terrace with rock + iron reinforcement."""
    clear_scene()
    H = mats["dark_iron"]
    S = mats["steel"]
    B = mats["brass"]
    C = mats["copper"]
    ST = mats["stone"]

    # 1. Stepped natural stone bluff base
    trapezoid("cliff_stone_base", 16.0, 8.0, 16.0, 6.5, 4.5,
              (0.0, 0.75, 2.25), ST, bevel=0.10)
    trapezoid("cliff_stone_upper", 16.0, 6.5, 16.0, 5.5, 3.5,
              (0.0, 1.25, 6.25), ST, bevel=0.08)

    # 2. Heavy industrial cast-iron retaining wall section on face (-Y face)
    box("cliff_retaining_wall", (10.0, 0.8, 5.0), (0.0, -2.4, 3.5), H,
        rot=(math.radians(-8.0), 0.0, 0.0), bevel=0.05)
    # Steel vertical anchor pillars
    for px in (-4.0, 0.0, 4.0):
        box(f"cliff_anchor_beam_{int(px)}", (0.5, 0.6, 5.6), (px, -2.5, 3.5), S,
            rot=(math.radians(-8.0), 0.0, 0.0), bevel=0.03)
        cylinder(f"cliff_anchor_bolt_{int(px)}", 0.16, 0.20, (px, -2.8, 5.5), B,
                 rot=(math.radians(90.0), 0.0, 0.0))

    # 3. Heavy drainage / steam culvert pipe penetrating the cliff face
    cylinder("cliff_drain_pipe", 0.45, 2.2, (-2.5, -2.0, 1.5), C, vertices=10,
             rot=(math.radians(90.0), 0.0, 0.0))
    torus("cliff_drain_ring", 0.48, 0.06, (-2.5, -2.8, 1.5), B, rot=(math.radians(90.0), 0.0, 0.0))

    # 4. Flat plateau top surface (Z = 8.0m, Y from -1.5 to +4.0)
    box("cliff_top_slab", (16.0, 5.5, 0.2), (0.0, 1.25, 7.9), ST, bevel=0.02)
    # Low iron edge coping on cliff top
    box("cliff_top_coping", (16.0, 0.4, 0.3), (0.0, -1.4, 8.05), H, bevel=0.02)

    joined = join_all_into_asset("gearforge_cliff_straight")
    return joined


def build_cliff_corner_in(mats):
    """Inner Corner (Re-entrant) Cliff: 16m x 16m, Height 8.0m. Creates canyon basins and recessed alcoves."""
    clear_scene()
    H = mats["dark_iron"]
    S = mats["steel"]
    B = mats["brass"]
    ST = mats["stone"]

    # L-shaped stone body
    # Section A (X-aligned)
    trapezoid("cliff_corner_in_stone_a", 16.0, 8.0, 16.0, 6.5, 8.0,
              (0.0, 4.0, 4.0), ST, bevel=0.10)
    # Section B (Y-aligned wing)
    trapezoid("cliff_corner_in_stone_b", 8.0, 16.0, 6.5, 16.0, 8.0,
              (-4.0, 0.0, 4.0), ST, bevel=0.10)

    # Industrial corner bracing & retaining plates at inside intersection
    box("cliff_in_retaining", (4.5, 4.5, 5.2), (-1.2, 1.2, 3.2), H,
        rot=(0.0, 0.0, math.radians(45.0)), bevel=0.06)
    cylinder("cliff_in_corner_pin", 0.35, 6.0, (-0.2, 0.2, 3.5), B, vertices=10)

    # Top plateau surface
    box("cliff_in_top_slab_a", (16.0, 8.0, 0.2), (0.0, 4.0, 7.9), ST, bevel=0.02)
    box("cliff_in_top_slab_b", (8.0, 8.0, 0.2), (-4.0, -4.0, 7.9), ST, bevel=0.02)

    joined = join_all_into_asset("gearforge_cliff_corner_in")
    return joined


def build_cliff_corner_out(mats):
    """Outer Corner (Salient) Cliff: 16m x 16m, Height 8.0m. Forms promontories and high-ground vantage salients."""
    clear_scene()
    H = mats["dark_iron"]
    S = mats["steel"]
    B = mats["brass"]
    ST = mats["stone"]

    # Solid quadrant plateau
    trapezoid("cliff_out_stone_base", 16.0, 16.0, 13.5, 13.5, 8.0,
              (0.0, 0.0, 4.0), ST, bevel=0.12)

    # Heavy iron bastion bracket reinforcing the exposed salient corner
    box("cliff_out_iron_brace", (3.0, 3.0, 6.2), (-5.2, -5.2, 3.5), H,
        rot=(0.0, 0.0, math.radians(45.0)), bevel=0.05)
    # Brass anchor rings & tie-backs
    for bz in (2.0, 4.5):
        torus(f"cliff_out_tie_{int(bz)}", 0.6, 0.08, (-6.2, -6.2, bz), B,
              rot=(math.radians(45.0), math.radians(45.0), 0.0))

    # Top plateau slab
    box("cliff_out_top_slab", (13.5, 13.5, 0.2), (0.0, 0.0, 7.9), ST, bevel=0.02)
    # Iron perimeter barrier on corner
    box("cliff_out_coping_x", (7.0, 0.4, 0.3), (-2.8, -6.6, 8.05), H, bevel=0.02)
    box("cliff_out_coping_y", (0.4, 7.0, 0.3), (-6.6, -2.8, 8.05), H, bevel=0.02)

    joined = join_all_into_asset("gearforge_cliff_corner_out")
    return joined


def build_cliff_ramp(mats):
    """Cliff Ramp: Width 16m, Length 24m (Y: -12 to +12), Rises smoothly from Z=0 to Z=8m."""
    clear_scene()
    H = mats["dark_iron"]
    S = mats["steel"]
    B = mats["brass"]
    ST = mats["stone"]

    RAMP_L = 24.0
    RAMP_W = 16.0
    ROAD_W = 12.0
    H_MAX = 8.0
    SLOPE_RAD = math.atan2(H_MAX, RAMP_L) # ~18.4 degrees

    # 1. Natural stone tapered retaining base
    trapezoid("cliff_ramp_stone_base", RAMP_W, RAMP_L, RAMP_W * 0.95, RAMP_L, H_MAX * 0.5,
              (0.0, 0.0, H_MAX * 0.25), ST, bevel=0.08)

    # 2. Inclined Ramp Roadway Slab
    ramp_length = math.sqrt(RAMP_L * RAMP_L + H_MAX * H_MAX) # ~25.3m
    box("cliff_ramp_road_bed", (ROAD_W, ramp_length, 0.45),
        (0.0, 0.0, H_MAX * 0.5), S,
        rot=(SLOPE_RAD, 0.0, 0.0), bevel=0.03)

    # Transverse traction ridges along ramp (every 2.5m)
    for step_i in range(-4, 5):
        y_loc = step_i * 2.4
        z_loc = (step_i + 5) * (H_MAX / 10.0)
        box(f"cliff_ramp_rib_{step_i}", (ROAD_W - 0.4, 0.3, 0.06),
            (0.0, y_loc, z_loc + 0.25), H, rot=(SLOPE_RAD, 0.0, 0.0), bevel=0.01)

    # 3. Flanking Heavy Stone & Iron Retaining Walls
    for sx in (-1.0, 1.0):
        side_x = sx * (RAMP_W * 0.5 - 0.9)
        side_tag = "l" if sx < 0 else "r"
        # Sloped wall capping
        box(f"cliff_ramp_wall_{side_tag}", (1.0, ramp_length, 1.2),
            (side_x, 0.0, H_MAX * 0.5 + 0.6), H,
            rot=(SLOPE_RAD, 0.0, 0.0), bevel=0.04)
        # Brass lantern posts at top and bottom of ramp
        for py in (-10.0, 10.0):
            pz = 1.0 if py < 0 else 8.5
            cylinder(f"cliff_ramp_post_{side_tag}_{int(py)}", 0.16, 1.2,
                     (side_x, py, pz), B, vertices=8)

    joined = join_all_into_asset("gearforge_cliff_ramp")
    return joined


def build_cliff_large(mats):
    """Large Massive Cliff Bluff: Width 32m, Depth 16m, Height 12m. For grand scale canyon and mountain backdrops."""
    clear_scene()
    H = mats["dark_iron"]
    S = mats["steel"]
    B = mats["brass"]
    C = mats["copper"]
    ST = mats["stone"]

    # Massive 3-tiered stone cliff face
    trapezoid("cliff_lg_tier_1", 32.0, 16.0, 31.0, 14.0, 4.5, (0.0, 1.0, 2.25), ST, bevel=0.15)
    trapezoid("cliff_lg_tier_2", 31.0, 14.0, 30.0, 12.0, 4.5, (0.0, 2.0, 6.75), ST, bevel=0.15)
    trapezoid("cliff_lg_tier_3", 30.0, 12.0, 29.0, 10.0, 3.5, (0.0, 3.0, 10.75), ST, bevel=0.12)

    # Reinforced industrial buttress towers embedded in cliff face
    for bx in (-10.0, 10.0):
        trapezoid(f"cliff_lg_buttress_{int(bx)}", 4.5, 3.5, 3.2, 2.4, 10.0,
                  (bx, -4.5, 5.0), H, rot=(math.radians(-6.0), 0.0, 0.0), bevel=0.08)
        # Heavy tie-back plates with brass anchor pins
        cylinder(f"cliff_lg_pin_{int(bx)}", 0.35, 1.5, (bx, -5.5, 8.5), B, vertices=10,
                 rot=(math.radians(90.0), 0.0, 0.0))

    # Exposed steam vent pipes running vertically down the rock face
    cylinder("cliff_lg_pipe_v", 0.32, 11.0, (0.0, -3.2, 5.8), C, vertices=10)
    for pz in (3.0, 6.5, 9.5):
        torus(f"cliff_lg_pipe_clamp_{int(pz)}", 0.36, 0.06, (0.0, -3.2, pz), B)

    # Top surface (Z = 12.0m)
    box("cliff_lg_top", (29.0, 10.0, 0.2), (0.0, 3.0, 12.0), ST, bevel=0.03)

    joined = join_all_into_asset("gearforge_cliff_large")
    return joined


# ------------------------------------------------------------------------------
# 3. Fortress Gate & Defensive Wall Set
# ------------------------------------------------------------------------------
def build_fortress_gate(mats):
    """Fortress Gate: Width 24m, Depth 8m, Clear opening: 10m W x 12.5m H (Titan passes!), Total Height 16m."""
    clear_scene()
    H = mats["dark_iron"]
    S = mats["steel"]
    B = mats["brass"]
    C = mats["copper"]
    ST = mats["stone"]
    G_AETHER = mats["aether_glow"]

    GATE_CLEAR_W = 10.0
    GATE_CLEAR_H = 12.5
    TOTAL_W = 24.0
    TOTAL_H = 16.0
    DEPTH = 8.0

    # 1. Left & Right Bastion Gate Towers (X: ±5.0m to ±12.0m)
    for sx in (-1.0, 1.0):
        tower_x = sx * (GATE_CLEAR_W * 0.5 + (TOTAL_W - GATE_CLEAR_W) * 0.25) # ±8.5m
        tower_w = (TOTAL_W - GATE_CLEAR_W) * 0.5 # 7.0m
        side_tag = "l" if sx < 0 else "r"

        # Massive masonry lower base
        trapezoid(f"gate_tower_base_{side_tag}", tower_w, DEPTH, tower_w - 0.6, DEPTH - 0.6, 6.0,
                  (tower_x, 0.0, 3.0), ST, bevel=0.08)
        # Heavy cast-iron upper tower
        box(f"gate_tower_upper_{side_tag}", (tower_w - 0.6, DEPTH - 0.6, 8.5),
            (tower_x, 0.0, 10.25), H, bevel=0.06)
        # Crenellated parapet on tower top (Z = 14.5m to 16.0m)
        box(f"gate_tower_parapet_f_{side_tag}", (tower_w - 0.6, 0.6, 1.5),
            (tower_x, -DEPTH * 0.5 + 0.6, 15.25), S, bevel=0.03)
        box(f"gate_tower_parapet_b_{side_tag}", (tower_w - 0.6, 0.6, 1.5),
            (tower_x,  DEPTH * 0.5 - 0.6, 15.25), S, bevel=0.03)
        # Faction plate mounting panel on tower front face
        box(f"gate_faction_panel_{side_tag}", (tower_w - 2.0, 0.15, 2.5),
            (tower_x, -DEPTH * 0.5 - 0.05, 8.5), S, bevel=0.02)

        # Arrow slit / viewing slit with Aether Cyan glow
        cylinder(f"gate_visor_bezel_{side_tag}", 0.35, 0.25, (tower_x, -DEPTH * 0.5 - 0.08, 12.0), B,
                 rot=(math.radians(90.0), 0.0, 0.0))
        cylinder(f"gate_visor_glow_{side_tag}", 0.22, 0.30, (tower_x, -DEPTH * 0.5 - 0.08, 12.0), G_AETHER,
                 vertices=8, rot=(math.radians(90.0), 0.0, 0.0))

    # 2. Gate Archway & Header Structure (Z = 12.5m to 16.0m spanning X = -5.0m to +5.0m)
    # Heavy overhead lintel box
    box("gate_lintel_beam", (GATE_CLEAR_W + 1.2, DEPTH - 0.8, 2.2),
        (0.0, 0.0, GATE_CLEAR_H + 1.1), H, bevel=0.05)
    # Reinforced steel face with Gearforge rivet bands
    box("gate_lintel_fascia", (GATE_CLEAR_W, 0.4, 1.8),
        (0.0, -DEPTH * 0.5 + 0.2, GATE_CLEAR_H + 1.1), S, bevel=0.03)

    # 3. Heavy Portcullis / Armored Sliding Gate (Shown half-retracted for dramatic depth)
    # Retracted upper gate leaf
    box("gate_portcullis_leaf", (GATE_CLEAR_W - 0.4, 0.6, 4.0),
        (0.0, 0.0, GATE_CLEAR_H + 0.5), H, bevel=0.03)
    # Heavy vertical steel tines
    for tx in (-4.0, -2.4, -0.8, 0.8, 2.4, 4.0):
        cylinder(f"gate_tine_{int(tx * 10)}", 0.14, 3.5, (tx, 0.0, GATE_CLEAR_H - 1.2), S, vertices=8)
        cylinder(f"gate_tine_point_{int(tx * 10)}", 0.16, 0.5, (tx, 0.0, GATE_CLEAR_H - 2.8), B, vertices=6)

    # 4. Overhead Steam Winch & Aether Power Mechanism
    # Giant central winch drum
    cylinder("gate_winch_drum", 0.85, 3.6, (0.0, 0.0, GATE_CLEAR_H + 2.3), C,
             vertices=14, rot=(0.0, math.radians(90.0), 0.0))
    # Massive brass spur gears on winch ends
    for sx in (-1.8, 1.8):
        cylinder(f"gate_winch_gear_{int(sx * 10)}", 1.25, 0.25, (sx, 0.0, GATE_CLEAR_H + 2.3), B,
                 vertices=18, rot=(0.0, math.radians(90.0), 0.0))
    # Glowing Aether regulator core atop gate center
    box("gate_aether_housing", (1.6, 1.2, 1.4), (0.0, -DEPTH * 0.5 - 0.2, GATE_CLEAR_H + 1.2), H, bevel=0.03)
    cylinder("gate_aether_core", 0.45, 0.35, (0.0, -DEPTH * 0.5 - 0.3, GATE_CLEAR_H + 1.2), G_AETHER,
             vertices=12, rot=(math.radians(90.0), 0.0, 0.0))
    torus("gate_aether_ring", 0.50, 0.08, (0.0, -DEPTH * 0.5 - 0.3, GATE_CLEAR_H + 1.2), B,
          rot=(math.radians(90.0), 0.0, 0.0))

    joined = join_all_into_asset("gearforge_fortress_gate")
    return joined


def build_wall_straight(mats):
    """Straight Wall Module: Width 16m (X), Thickness 4m (Y), Height 8.0m (walkway) + 1.2m parapet = 9.2m."""
    clear_scene()
    H = mats["dark_iron"]
    S = mats["steel"]
    B = mats["brass"]
    ST = mats["stone"]

    W_LEN = 16.0
    W_THICK = 4.0
    WALK_H = 8.0

    # 1. Sloped Stone Foundation Rampart (Z = 0 to 4.5m)
    trapezoid("wall_stone_base", W_LEN, W_THICK + 1.2, W_LEN, W_THICK, 4.5,
              (0.0, 0.0, 2.25), ST, bevel=0.08)

    # 2. Heavy Cast-Iron Wall Body (Z = 4.5 to 8.0m)
    box("wall_iron_body", (W_LEN, W_THICK, 3.5), (0.0, 0.0, 6.25), H, bevel=0.05)

    # 3. Walkway Deck on Top (Z = 8.0m)
    box("wall_walkway_deck", (W_LEN, W_THICK - 0.6, 0.3), (0.0, 0.0, WALK_H), S, bevel=0.02)

    # 4. Crenellated Parapet on Front Face (-Y)
    # Merlons (solid raised battlements every 3.2m)
    for mi in range(-2, 3):
        mx = mi * 3.2
        box(f"wall_merlon_{mi}", (2.0, 0.5, 1.2), (mx, -W_THICK * 0.5 + 0.25, WALK_H + 0.6), H, bevel=0.03)
        # Brass cap on each merlon
        box(f"wall_merlon_cap_{mi}", (2.1, 0.55, 0.08), (mx, -W_THICK * 0.5 + 0.25, WALK_H + 1.22), B, bevel=0.01)

    # Rear handrail on walkway (+Y face)
    box("wall_rear_curb", (W_LEN, 0.3, 0.4), (0.0, W_THICK * 0.5 - 0.2, WALK_H + 0.2), S, bevel=0.02)
    cylinder("wall_rear_rail", 0.06, W_LEN, (0.0, W_THICK * 0.5 - 0.2, WALK_H + 1.0), B,
             vertices=8, rot=(0.0, math.radians(90.0), 0.0))

    # Access ladder on rear face
    for rz in range(2, 8):
        cylinder(f"wall_ladder_rung_{rz}", 0.03, 0.7, (0.0, W_THICK * 0.5 + 0.12, float(rz)), B,
                 vertices=6, rot=(0.0, math.radians(90.0), 0.0))

    joined = join_all_into_asset("gearforge_wall_straight")
    return joined


def build_wall_corner(mats):
    """Corner Wall Module: 8m x 8m, 90-degree bend, Height 9.2m."""
    clear_scene()
    H = mats["dark_iron"]
    S = mats["steel"]
    B = mats["brass"]
    ST = mats["stone"]

    SIZE = 8.0
    WALK_H = 8.0

    # Stone corner foundation
    trapezoid("wall_corner_stone", SIZE + 1.0, SIZE + 1.0, SIZE, SIZE, 4.5,
              (0.0, 0.0, 2.25), ST, bevel=0.08)
    # Iron upper structure
    box("wall_corner_iron", (SIZE, SIZE, 3.5), (0.0, 0.0, 6.25), H, bevel=0.05)
    # Top deck
    box("wall_corner_deck", (SIZE - 0.6, SIZE - 0.6, 0.3), (0.0, 0.0, WALK_H), S, bevel=0.02)

    # Corner battlements on outer edges (-X and -Y)
    box("wall_corner_merlon_x", (4.0, 0.5, 1.2), (-1.8, -SIZE * 0.5 + 0.25, WALK_H + 0.6), H, bevel=0.03)
    box("wall_corner_merlon_y", (0.5, 4.0, 1.2), (-SIZE * 0.5 + 0.25, -1.8, WALK_H + 0.6), H, bevel=0.03)
    # Heavy corner turret post
    cylinder("wall_corner_pinnacle", 0.45, 1.6, (-SIZE * 0.5 + 0.35, -SIZE * 0.5 + 0.35, WALK_H + 0.8), B, vertices=10)

    joined = join_all_into_asset("gearforge_wall_corner")
    return joined


def build_wall_tower(mats):
    """Fortress Wall Watchtower: 8m x 8m, Height 14.0m with observation deck, searchlight, and Aether scanner."""
    clear_scene()
    H = mats["dark_iron"]
    S = mats["steel"]
    B = mats["brass"]
    ST = mats["stone"]
    G_AETHER = mats["aether_glow"]

    T_SIZE = 8.0
    T_H = 14.0

    # 1. Base stone pier (Z = 0 to 5m)
    trapezoid("tower_stone_base", T_SIZE + 1.2, T_SIZE + 1.2, T_SIZE, T_SIZE, 5.0,
              (0.0, 0.0, 2.5), ST, bevel=0.10)
    # 2. Main iron tower shaft (Z = 5 to 12m)
    box("tower_iron_shaft", (T_SIZE - 0.4, T_SIZE - 0.4, 7.0), (0.0, 0.0, 8.5), H, bevel=0.06)

    # 3. Flared Observation Platform (Z = 12m to 14m)
    box("tower_platform_deck", (T_SIZE + 1.2, T_SIZE + 1.2, 0.4), (0.0, 0.0, 12.0), S, bevel=0.03)
    # Parapet around observation platform
    for side_i, (dx, dy, rot_y) in enumerate((
        (0.0, -(T_SIZE * 0.5 + 0.5), 0.0),
        (0.0,  (T_SIZE * 0.5 + 0.5), 0.0),
        (-(T_SIZE * 0.5 + 0.5), 0.0, math.radians(90.0)),
        ( (T_SIZE * 0.5 + 0.5), 0.0, math.radians(90.0)),
    )):
        box(f"tower_parapet_{side_i}", (T_SIZE + 1.0, 0.3, 1.2), (dx, dy, 12.7), H,
            rot=(0.0, 0.0, rot_y), bevel=0.02)

    # 4. Searchlight & Aether Sensor Cupola on Roof
    cylinder("tower_cupola_base", 1.2, 0.8, (0.0, 0.0, 12.6), H, vertices=12)
    cylinder("tower_searchlight_pod", 0.45, 0.7, (0.0, -1.8, 13.5), B, vertices=10,
             rot=(math.radians(70.0), 0.0, 0.0))
    cylinder("tower_searchlight_lens", 0.35, 0.15, (0.0, -2.1, 13.4), G_AETHER, vertices=10,
             rot=(math.radians(70.0), 0.0, 0.0))

    joined = join_all_into_asset("gearforge_wall_tower")
    return joined


def build_defensive_bastion(mats):
    """Defensive Bastion / Gun Platform: Width 12m, Depth 10m, Height 9.2m. Projecting artillery barbette."""
    clear_scene()
    H = mats["dark_iron"]
    S = mats["steel"]
    B = mats["brass"]
    ST = mats["stone"]

    # Salient polygonal gun platform
    trapezoid("bastion_stone_base", 12.0, 10.0, 10.5, 8.5, 5.0, (0.0, -1.0, 2.5), ST, bevel=0.10)
    box("bastion_iron_deck", (10.5, 8.5, 3.2), (0.0, -1.0, 6.6), H, bevel=0.05)
    # Upper gun deck slab (Z = 8.2m)
    box("bastion_gun_slab", (10.0, 8.0, 0.3), (0.0, -1.0, 8.2), S, bevel=0.02)

    # Heavy frontal barbette embrasure (front curved shield with embrasures)
    box("bastion_embrasure_wall", (9.0, 0.8, 1.6), (0.0, -4.8, 9.0), H, bevel=0.04)
    # Gun embrasure opening
    box("bastion_gun_slot", (2.8, 1.0, 0.8), (0.0, -4.8, 8.9), S, bevel=0.02)
    # Fixed dummy artillery carriage mount ring
    cylinder("bastion_turntable", 1.8, 0.2, (0.0, -2.0, 8.4), B, vertices=16)

    joined = join_all_into_asset("gearforge_defensive_bastion")
    return joined


# ------------------------------------------------------------------------------
# 4. Road & Industrial Props
# ------------------------------------------------------------------------------
def build_road_straight(mats):
    """Heavy Road Slab Module: Width 12m, Length 16m, Thickness 0.3m. Paved cobbles with steel curbs."""
    clear_scene()
    H = mats["dark_iron"]
    S = mats["steel"]
    ST = mats["stone"]

    box("road_slab_base", (12.0, 16.0, 0.25), (0.0, 0.0, 0.12), ST, bevel=0.02)
    # Flanking steel drainage curbs
    for sx in (-1.0, 1.0):
        box(f"road_curb_{int(sx)}", (0.5, 16.0, 0.35), (sx * 5.75, 0.0, 0.18), H, bevel=0.02)
    # Centerline steel tread plate
    box("road_center_tread", (2.0, 16.0, 0.04), (0.0, 0.0, 0.26), S, bevel=0.01)

    joined = join_all_into_asset("gearforge_road_straight")
    return joined


def build_road_barrier(mats):
    """Industrial Road Barrier: Length 8m, Height 1.3m. Steel rail, heavy stanchions, brass warning beacon."""
    clear_scene()
    H = mats["dark_iron"]
    S = mats["steel"]
    B = mats["brass"]
    G_AETHER = mats["aether_glow"]

    # Base skid rail
    box("barrier_base_beam", (0.6, 8.0, 0.25), (0.0, 0.0, 0.12), H, bevel=0.02)
    # Vertical stanchions
    for y_pos in (-3.5, 0.0, 3.5):
        box(f"barrier_post_{int(y_pos * 10)}", (0.35, 0.35, 1.2), (0.0, y_pos, 0.65), S, bevel=0.02)
        # Warning light on posts
        cylinder(f"barrier_beacon_{int(y_pos * 10)}", 0.08, 0.15, (0.0, y_pos, 1.32), G_AETHER, vertices=8)
        cylinder(f"barrier_beacon_cap_{int(y_pos * 10)}", 0.11, 0.05, (0.0, y_pos, 1.41), B, vertices=8)
    # Horizontal crash rail
    box("barrier_crash_rail", (0.2, 8.0, 0.45), (0.0, 0.0, 0.85), S, bevel=0.03)

    joined = join_all_into_asset("gearforge_road_barrier")
    return joined


def build_industrial_pipe_straight(mats):
    """Industrial Overland Pipe Module: Length 16m, Height 1.5m, Dia 0.7m. High pressure copper conduit on gantry."""
    clear_scene()
    H = mats["dark_iron"]
    B = mats["brass"]
    C = mats["copper"]
    G_AETHER = mats["aether_glow"]

    # Main copper pipe
    cylinder("pipe_steam_tube", 0.35, 16.0, (0.0, 0.0, 1.4), C,
             vertices=12, rot=(math.radians(90.0), 0.0, 0.0))
    # Accompanying small Aether conduit
    cylinder("pipe_aether_line", 0.12, 16.0, (0.45, 0.0, 1.7), G_AETHER,
             vertices=8, rot=(math.radians(90.0), 0.0, 0.0))

    # Support gantry trestles every 4m
    for y_pos in (-6.0, -2.0, 2.0, 6.0):
        # A-frame iron stanchion
        box(f"pipe_trestle_{int(y_pos)}", (1.4, 0.4, 1.4), (0.0, y_pos, 0.7), H, bevel=0.03)
        torus(f"pipe_saddle_{int(y_pos)}", 0.38, 0.06, (0.0, y_pos, 1.4), B,
              rot=(math.radians(90.0), 0.0, 0.0))

    joined = join_all_into_asset("gearforge_industrial_pipe_straight")
    return joined


# ==============================================================================
# MAIN BATCH EXECUTION
# ==============================================================================
def main():
    print("=== GEARFORGE MAP PRODUCTION KIT 01 BUILD START ===")
    os.makedirs(MAP_MODELS_DIR, exist_ok=True)
    os.makedirs(INTERMEDIATE_DIR, exist_ok=True)

    mats = get_materials()

    asset_builders = [
        # 1. Heavy Bridge
        ("gearforge_bridge_heavy", build_bridge_heavy),
        # 2. Modular Cliffs
        ("gearforge_cliff_straight", build_cliff_straight),
        ("gearforge_cliff_corner_in", build_cliff_corner_in),
        ("gearforge_cliff_corner_out", build_cliff_corner_out),
        ("gearforge_cliff_ramp", build_cliff_ramp),
        ("gearforge_cliff_large", build_cliff_large),
        # 3. Fortress & Walls
        ("gearforge_fortress_gate", build_fortress_gate),
        ("gearforge_wall_straight", build_wall_straight),
        ("gearforge_wall_corner", build_wall_corner),
        ("gearforge_wall_tower", build_wall_tower),
        ("gearforge_defensive_bastion", build_defensive_bastion),
        # 4. Roads & Props
        ("gearforge_road_straight", build_road_straight),
        ("gearforge_road_barrier", build_road_barrier),
        ("gearforge_industrial_pipe_straight", build_industrial_pipe_straight),
    ]

    all_stats = []
    saved_objects = {}

    # Build and export each asset individually
    for asset_name, builder_func in asset_builders:
        print(f"\n--- Building {asset_name} ---")
        obj = builder_func(mats)
        stats = measure_asset_stats(obj)
        all_stats.append(stats)

        # Export GLB to production directory
        out_glb = os.path.join(MAP_MODELS_DIR, f"{asset_name}.glb")
        export_single_glb(out_glb)

        # Also copy/export to intermediate blender/exports
        inter_glb = os.path.join(INTERMEDIATE_DIR, f"{asset_name}.glb")
        export_single_glb(inter_glb)

    # --------------------------------------------------------------------------
    # Master Blend Scene Assembly
    # Re-build all assets arranged neatly in a showcase grid for the .blend file
    # --------------------------------------------------------------------------
    print("\n--- Building master .blend library layout ---")
    clear_scene()
    grid_layout = [
        ("gearforge_bridge_heavy", build_bridge_heavy, (0.0, 0.0, 0.0)),
        ("gearforge_cliff_straight", build_cliff_straight, (-24.0, 16.0, 0.0)),
        ("gearforge_cliff_corner_in", build_cliff_corner_in, (-42.0, 16.0, 0.0)),
        ("gearforge_cliff_corner_out", build_cliff_corner_out, (-24.0, 34.0, 0.0)),
        ("gearforge_cliff_ramp", build_cliff_ramp, (-44.0, 34.0, 0.0)),
        ("gearforge_cliff_large", build_cliff_large, (-32.0, 60.0, 0.0)),
        ("gearforge_fortress_gate", build_fortress_gate, (28.0, 0.0, 0.0)),
        ("gearforge_wall_straight", build_wall_straight, (28.0, 16.0, 0.0)),
        ("gearforge_wall_corner", build_wall_corner, (44.0, 16.0, 0.0)),
        ("gearforge_wall_tower", build_wall_tower, (44.0, 26.0, 0.0)),
        ("gearforge_defensive_bastion", build_defensive_bastion, (28.0, 28.0, 0.0)),
        ("gearforge_road_straight", build_road_straight, (0.0, -22.0, 0.0)),
        ("gearforge_road_barrier", build_road_barrier, (12.0, -22.0, 0.0)),
        ("gearforge_industrial_pipe_straight", build_industrial_pipe_straight, (-12.0, -22.0, 0.0)),
    ]

    print("\n--- Building master .blend library layout from exported GLBs ---")
    clear_scene()
    for asset_name, _, grid_pos in grid_layout:
        glb_path = os.path.join(MAP_MODELS_DIR, f"{asset_name}.glb")
        if os.path.exists(glb_path):
            bpy.ops.object.select_all(action="DESELECT")
            bpy.ops.import_scene.gltf(filepath=glb_path)
            imported_objs = [o for o in bpy.context.selected_objects]
            for o in imported_objs:
                o.location = Vector(grid_pos)
            bpy.context.view_layer.update()

    os.makedirs(os.path.dirname(SOURCE_BLEND), exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)
    print(f"\nMASTER_BLEND_SAVED {SOURCE_BLEND} ({os.path.getsize(SOURCE_BLEND)} bytes)")

    print("\n=== SUMMARY OF ALL ASSETS CREATED ===")
    for s in all_stats:
        print(f"| {s['name']} | {s['size'][0]:.1f}x{s['size'][1]:.1f}x{s['size'][2]:.1f}m | {s['tris']} tris | {s['polys']} polys | {s['mats']} mats |")

    print("\n=== GEARFORGE MAP PRODUCTION KIT 01 BUILD COMPLETE ===")


if __name__ == "__main__":
    main()
