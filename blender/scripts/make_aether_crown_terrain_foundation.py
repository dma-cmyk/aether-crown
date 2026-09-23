"""Generate the Aether Crown RTS Production Terrain Foundation 01.

Creates:
- blender/source/aether_crown_terrain_foundation.blend
- blender/exports/map/aether_crown_terrain_foundation.glb
- game/assets/models/map/aether_crown_terrain_foundation.glb
- blender/exports/map/aether_crown_terrain_heightmap.png

Key Features:
- Designed specifically for Aether Crown RTS gameplay and visual reference.
- Clear 3-tier elevation hierarchy (Lowland Ravine -> Central Battlefield -> High Plateaus).
- Distinct Three Strategic Routes (North mountain ridge, Central major clash, South industrial lowland).
- Deep industrial ravine with dedicated Heavy Military Bridge slot (8.0m gap & pier foundation).
- Natural Fortress Approach narrowing towards Fortress Gate plateau.
- Broad plateau for Player Base & Enemy HQ with ample staging area.
- Integrated City Pads (West Foundry, North Relay, Central Nexus, South Works, East Bastion).
- Lightweight & performant for Intel Iris Xe (< 45,000 tris).
"""

import math
import os
import sys

import bpy
from mathutils import Vector

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

SCRIPT_DIR = os.path.abspath(os.path.dirname(__file__))
if SCRIPT_DIR not in sys.path:
    sys.path.insert(0, SCRIPT_DIR)

from material_lib import make_pbr  # noqa: E402

ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
SOURCE_BLEND = os.path.join(ROOT, "blender", "source", "aether_crown_terrain_foundation.blend")
EXPORT_GLB_INTERMEDIATE = os.path.join(ROOT, "blender", "exports", "map", "aether_crown_terrain_foundation.glb")
EXPORT_GLB_GAME = os.path.join(ROOT, "game", "assets", "models", "map", "aether_crown_terrain_foundation.glb")
HEIGHTMAP_PNG = os.path.join(ROOT, "blender", "exports", "map", "aether_crown_terrain_heightmap.png")

# ==============================================================================
# PARAMETERS
# ==============================================================================
MAP_WIDTH = 140.0       # Total map width (Godot X: -70 to +70)
MAP_DEPTH = 140.0       # Total map depth (Godot Z: -70 to +70)
GRID_STEP = 1.0         # 1m grid spacing -> 141 x 141 = 19,881 vertices, 39,200 tris

# Elevation Tiers (Strictly matching Gearforge Map Kit 8.0m modular heights)
RAVINE_FLOOR_H = 0.0          # Deep canyon floor (sludge / water / pier base)
SOUTH_ROUTE_H = 4.5           # South lowland route & South Works
CENTRAL_BATTLEFIELD_H = 8.0   # Main battlefield & Bridge Deck alignment
EAST_BASTION_H = 9.0          # Bridgehead defense terrace
WEST_FOUNDRY_H = 9.8          # West industrial terrace
FORTRESS_GATE_H = 11.8        # Fortress Gate defensive plateau
PLAYER_PLATEAU_H = 12.0       # Player HQ high ground
NORTH_ROUTE_H = 13.5          # North mountain ridge route & North Relay
ENEMY_PLATEAU_H = 15.5        # Enemy HQ supreme fortress high ground
PERIMETER_CLIFF_H = 22.0      # Out-of-bounds mountain rim

# Key Godot Locations (X, Z)
PLAYER_HQ_POS = (-32.0, -32.0)
ENEMY_HQ_POS = (34.0, 36.0)
WEST_FOUNDRY_POS = (-22.0, 4.0)
NORTH_RELAY_POS = (2.0, -18.0)
CENTRAL_NEXUS_POS = (-12.0, 0.0)
SOUTH_WORKS_POS = (-2.0, 18.0)
EAST_BASTION_POS = (26.0, -8.0)
FORTRESS_GATE_POS = (38.0, 20.0)
BRIDGE_CENTER_POS = (18.0, 0.0)  # Gap is X: 10 to 26, Bridge Span = 32m (X: 2 to 34), Deck H = 8.0m

# ==============================================================================
# MATHEMATICAL HELPERS
# ==============================================================================
def smoothstep(edge0, edge1, x):
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3.0 - 2.0 * t)


def dist_point_to_segment(px, pz, ax, az, bx, bz):
    abx = bx - ax
    abz = bz - az
    length_sq = abx * abx + abz * abz
    if length_sq < 1e-6:
        return math.hypot(px - ax, pz - az), 0.0
    t = max(0.0, min(1.0, ((px - ax) * abx + (pz - az) * abz) / length_sq))
    proj_x = ax + t * abx
    proj_z = az + t * abz
    return math.hypot(px - proj_x, pz - proj_z), t


def noise_2d(x, z):
    # Multi-frequency organic fractal terrain noise
    n = 0.55 * math.sin(x * 0.14 + z * 0.11)
    n += 0.32 * math.cos(x * 0.28 - z * 0.22)
    n += 0.18 * math.sin(x * 0.58 + z * 0.52)
    n += 0.08 * math.cos(x * 1.25 - z * 1.15)
    return n


# ==============================================================================
# TERRAIN ELEVATION EVALUATION (Godot coordinates: X, Z)
# ==============================================================================
def get_terrain_elevation(gx, gz):
    """Calculates height (Godot Y / Blender Z) at Godot coordinate (gx, gz)."""
    # Base height is Central Battlefield (8.0m)
    h = CENTRAL_BATTLEFIELD_H

    # --------------------------------------------------------------------------
    # 1. Player High Ground Plateau (around -32, -32)
    # --------------------------------------------------------------------------
    dp = math.hypot(gx - PLAYER_HQ_POS[0], gz - PLAYER_HQ_POS[1])
    if dp < 34.0:
        factor_p = 1.0 - smoothstep(16.0, 32.0, dp)
        h = h * (1.0 - factor_p) + PLAYER_PLATEAU_H * factor_p

    # --------------------------------------------------------------------------
    # 2. Enemy Fortress Plateau (around 32, 32)
    # --------------------------------------------------------------------------
    de = math.hypot(gx - ENEMY_HQ_POS[0], gz - ENEMY_HQ_POS[1])
    if de < 30.0:
        factor_e = 1.0 - smoothstep(14.0, 28.0, de)
        h = max(h, h * (1.0 - factor_e) + ENEMY_PLATEAU_H * factor_e)

    # --------------------------------------------------------------------------
    # 3. North Mountain Ridge (High Ground Route: Player Base -> North Relay -> Fortress Flank)
    # --------------------------------------------------------------------------
    north_segs = [
        (-32.0, -32.0, -14.0, -26.0),
        (-14.0, -26.0, 2.0, -18.0),
        (2.0, -18.0, 18.0, -16.0),
        (18.0, -16.0, 30.0, -8.0),
    ]
    for ax, az, bx, bz in north_segs:
        d_line, _ = dist_point_to_segment(gx, gz, ax, az, bx, bz)
        if d_line < 18.0:
            factor_n = 1.0 - smoothstep(7.0, 16.0, d_line)
            h = max(h, h * (1.0 - factor_n) + NORTH_ROUTE_H * factor_n)

    # --------------------------------------------------------------------------
    # 4. West Foundry Intermediate Terrace & Base Ramps
    # --------------------------------------------------------------------------
    dw = math.hypot(gx - WEST_FOUNDRY_POS[0], gz - WEST_FOUNDRY_POS[1])
    if dw < 20.0:
        factor_w = 1.0 - smoothstep(10.0, 18.0, dw)
        h = h * (1.0 - factor_w) + WEST_FOUNDRY_H * factor_w

    # Ramp: Player Base (-32, -32) to West Foundry (-22, 4)
    d_rpw, t_rpw = dist_point_to_segment(gx, gz, -30.0, -24.0, -22.0, 2.0)
    if d_rpw < 15.0:
        f_rpw = 1.0 - smoothstep(8.0, 14.0, d_rpw)
        ramp_h = PLAYER_PLATEAU_H * (1.0 - t_rpw) + WEST_FOUNDRY_H * t_rpw
        h = h * (1.0 - f_rpw) + ramp_h * f_rpw

    # Ramp: West Foundry (-22, 4) to Central Battlefield (0, 0)
    d_rwc, t_rwc = dist_point_to_segment(gx, gz, -20.0, 4.0, -2.0, 0.0)
    if d_rwc < 16.0:
        f_rwc = 1.0 - smoothstep(9.0, 15.0, d_rwc)
        ramp_h = WEST_FOUNDRY_H * (1.0 - t_rwc) + CENTRAL_BATTLEFIELD_H * t_rwc
        h = h * (1.0 - f_rwc) + ramp_h * f_rwc

    # --------------------------------------------------------------------------
    # 5. Central Nexus Battlefield Flat Arena (around -8, 0)
    # --------------------------------------------------------------------------
    dc = math.hypot(gx - (-8.0), gz - 0.0)
    if dc < 26.0:
        factor_c = 1.0 - smoothstep(16.0, 24.0, dc)
        h = h * (1.0 - factor_c) + CENTRAL_BATTLEFIELD_H * factor_c

    # --------------------------------------------------------------------------
    # 6. South Lowland Route (West Foundry -> South Works -> Enemy Base Approach)
    # --------------------------------------------------------------------------
    south_segs = [
        (-20.0, 6.0, -2.0, 18.0),
        (-2.0, 18.0, 16.0, 24.0),
        (16.0, 24.0, 28.0, 28.0),
    ]
    for ax, az, bx, bz in south_segs:
        d_line, _ = dist_point_to_segment(gx, gz, ax, az, bx, bz)
        if d_line < 18.0:
            factor_s = 1.0 - smoothstep(8.0, 16.0, d_line)
            h = h * (1.0 - factor_s) + SOUTH_ROUTE_H * factor_s

    # Flatten South Works city pad
    ds = math.hypot(gx - SOUTH_WORKS_POS[0], gz - SOUTH_WORKS_POS[1])
    if ds < 15.0:
        factor_sw = 1.0 - smoothstep(8.0, 14.0, ds)
        h = h * (1.0 - factor_sw) + SOUTH_ROUTE_H * factor_sw

    # --------------------------------------------------------------------------
    # 7. East Bastion (Bridgehead Defense Pad, 26, -8)
    # --------------------------------------------------------------------------
    deb = math.hypot(gx - EAST_BASTION_POS[0], gz - EAST_BASTION_POS[1])
    if deb < 16.0:
        factor_eb = 1.0 - smoothstep(9.0, 15.0, deb)
        h = max(h, h * (1.0 - factor_eb) + EAST_BASTION_H * factor_eb)

    # --------------------------------------------------------------------------
    # 8. Fortress Approach & Fortress Gate Plateau
    # --------------------------------------------------------------------------
    # Rising approach from Bridge exit (26.0, 0.0) towards Fortress Gate (38.0, 20.0)
    d_gate_app, t_app = dist_point_to_segment(gx, gz, 26.0, 0.0, FORTRESS_GATE_POS[0], FORTRESS_GATE_POS[1])
    if d_gate_app < 18.0:
        f_app = 1.0 - smoothstep(9.0, 17.0, d_gate_app)
        ramp_h = 8.2 * (1.0 - t_app) + FORTRESS_GATE_H * t_app
        h = max(h, h * (1.0 - f_app) + ramp_h * f_app)

    # Fortress Gate Plateau flattening (38, 20) - ample 36m wide flat pad for gate & walls
    dfg = math.hypot(gx - FORTRESS_GATE_POS[0], gz - FORTRESS_GATE_POS[1])
    if dfg < 22.0:
        factor_fg = 1.0 - smoothstep(14.0, 21.0, dfg)
        h = max(h, h * (1.0 - factor_fg) + FORTRESS_GATE_H * factor_fg)

    # Ramp: Fortress Gate (38, 20) to Enemy HQ (34, 36)
    d_gate_hq, t_ghq = dist_point_to_segment(gx, gz, FORTRESS_GATE_POS[0], FORTRESS_GATE_POS[1], ENEMY_HQ_POS[0], ENEMY_HQ_POS[1])
    if d_gate_hq < 18.0:
        f_ghq = 1.0 - smoothstep(9.0, 16.5, d_gate_hq)
        ramp_h = FORTRESS_GATE_H * (1.0 - t_ghq) + ENEMY_PLATEAU_H * t_ghq
        h = max(h, h * (1.0 - f_ghq) + ramp_h * f_ghq)

    # --------------------------------------------------------------------------
    # 9. INDUSTRIAL RAVINE & HEAVY MILITARY BRIDGE SLOT
    # --------------------------------------------------------------------------
    # The Ravine runs roughly North-South along X ~ 18m
    # Meandering gorge centerline
    ravine_cx = 18.0 + 3.0 * math.sin(gz * 0.08)
    d_ravine_x = abs(gx - ravine_cx)

    # Bridge Slot: centered at gx = 18.0, gz = 0.0
    # Heavy Military Bridge has span = 32m (X: 2.0 to 34.0), clear gorge width = 16m (X: 10.0 to 26.0).
    is_in_bridge_corridor = abs(gz) <= 12.0
    bridge_blend = 1.0 - smoothstep(6.5, 12.0, abs(gz))

    # Base gorge half width: 9.0m nominal (18m total width)
    gorge_half_w = 9.0 + 2.0 * math.cos(gz * 0.1)
    if is_in_bridge_corridor:
        # Near bridge, strictly 8.0m half width centered at X=18.0 -> Gap X is exactly 10.0 to 26.0 (16m clear gorge)
        gorge_half_w = gorge_half_w * (1.0 - bridge_blend) + 8.0 * bridge_blend
        ravine_cx = ravine_cx * (1.0 - bridge_blend) + 18.0 * bridge_blend
        d_ravine_x = abs(gx - ravine_cx)

    # Ravine carving applies if north of South route (gz < 22.0)
    if d_ravine_x < gorge_half_w + 4.0 and gz < 24.0:
        # Sharp cliff profile
        cliff_t = smoothstep(gorge_half_w - 2.5, gorge_half_w + 1.2, d_ravine_x)
        floor_h = RAVINE_FLOOR_H
        if gz > 14.0:
            # South end of ravine transitions smoothly into South Lowland route
            t_s = smoothstep(14.0, 24.0, gz)
            floor_h = floor_h * (1.0 - t_s) + SOUTH_ROUTE_H * t_s
        h = floor_h * (1.0 - cliff_t) + h * cliff_t

    # Bridge Abutment Landing Terraces (Ensures bridge sits on rock solid 8.0m deck ground)
    # West abutment: X in [2.0, 10.0], Z in [-8.5, 8.5]
    if 1.0 <= gx <= 10.2 and abs(gz) <= 8.5:
        f_ab_w = 1.0 - smoothstep(6.0, 8.5, abs(gz))
        h = h * (1.0 - f_ab_w) + CENTRAL_BATTLEFIELD_H * f_ab_w

    # East abutment: X in [25.8, 34.0], Z in [-8.5, 8.5]
    if 25.8 <= gx <= 35.0 and abs(gz) <= 8.5:
        f_ab_e = 1.0 - smoothstep(6.0, 8.5, abs(gz))
        h = h * (1.0 - f_ab_e) + CENTRAL_BATTLEFIELD_H * f_ab_e

    # --------------------------------------------------------------------------
    # 10. Perimeter Mountains & Rim Cliffs (Out-of-bounds walls)
    # --------------------------------------------------------------------------
    edge_dist = max(abs(gx), abs(gz))
    if edge_dist > 48.0:
        f_edge = smoothstep(48.0, 68.0, edge_dist)
        mountain_h = PERIMETER_CLIFF_H + 3.5 * math.sin(gx * 0.12 + gz * 0.10)
        h = h * (1.0 - f_edge) + mountain_h * f_edge

    # --------------------------------------------------------------------------
    # 11. Organic Rock Micro-Noise
    # --------------------------------------------------------------------------
    # Keep combat pads and bridge approaches clean, apply rugged noise on cliffs and perimeter
    noise_weight = 0.28
    if dc < 18.0 or dp < 16.0 or de < 16.0 or dw < 12.0 or ds < 12.0 or deb < 12.0 or dfg < 14.0:
        noise_weight = 0.06
    if is_in_bridge_corridor and 2.0 <= gx <= 26.0:
        noise_weight = 0.02

    h += noise_2d(gx, gz) * noise_weight
    return max(0.0, h)


# ==============================================================================
# MESH & MATERIAL GENERATION
# ==============================================================================
def create_materials():
    """Create the 6 stylized-realistic PBR materials for the terrain foundation."""
    mats = {}
    # 1. Dark grass for general plateaus
    mats["grass"] = make_pbr("terrain_grass_dark", (0.16, 0.22, 0.12), metallic=0.02, roughness=0.88)
    # 2. Worn earth / packed dirt for major routes & ramps
    mats["dirt"] = make_pbr("terrain_dirt_worn", (0.32, 0.26, 0.18), metallic=0.05, roughness=0.82)
    # 3. Stone for steep cliffs, rock bluffs, and ravine walls
    mats["stone"] = make_pbr("terrain_stone_cliff", (0.24, 0.23, 0.23), metallic=0.08, roughness=0.92)
    # 4. Industrial ground for base staging areas, HQ pads, fortress grounds
    mats["industrial"] = make_pbr("terrain_industrial_ground", (0.18, 0.18, 0.20), metallic=0.20, roughness=0.75)
    # 5. Ravine water / industrial runoff
    mats["water"] = make_pbr("terrain_water_ravine", (0.08, 0.14, 0.18), metallic=0.15, roughness=0.20)
    # 6. Aether rock vein accent
    mats["aether"] = make_pbr("terrain_aether_rock", (0.12, 0.25, 0.32), metallic=0.10, roughness=0.50,
                              emission_color=(0.20, 0.65, 0.85), emission_strength=1.8)
    return mats


def build_terrain_mesh(materials):
    """Builds the subdivided parametric terrain grid and assigns materials."""
    nx = int(MAP_WIDTH / GRID_STEP) + 1
    nz = int(MAP_DEPTH / GRID_STEP) + 1
    x_min = -MAP_WIDTH * 0.5
    z_min = -MAP_DEPTH * 0.5

    verts = []
    # Blender coordinates: X = gx, Y = -gz, Z = height
    # Store height grid for normal calculation and heightmap
    height_grid = []
    for iz in range(nz):
        gz = z_min + iz * GRID_STEP
        row = []
        for ix in range(nx):
            gx = x_min + ix * GRID_STEP
            elev = get_terrain_elevation(gx, gz)
            row.append(elev)
            # Blender: X = gx, Y = -gz, Z = elev
            verts.append((gx, -gz, elev))
        height_grid.append(row)

    faces = []
    for iz in range(nz - 1):
        for ix in range(nx - 1):
            i0 = iz * nx + ix
            i1 = iz * nx + (ix + 1)
            i2 = (iz + 1) * nx + (ix + 1)
            i3 = (iz + 1) * nx + ix
            # Quad face with counter-clockwise winding (upward normal +Z)
            faces.append((i3, i2, i1, i0))

    mesh = bpy.data.meshes.new(name="AetherCrown_Terrain_Foundation_Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update(calc_edges=True)

    obj = bpy.data.objects.new(name="AetherCrown_Terrain_Foundation", object_data=mesh)
    bpy.context.collection.objects.link(obj)

    # Assign material slots in exact order:
    # 0: grass, 1: dirt, 2: stone, 3: industrial, 4: water, 5: aether
    mat_list = [
        materials["grass"],       # 0
        materials["dirt"],        # 1
        materials["stone"],       # 2
        materials["industrial"],  # 3
        materials["water"],       # 4
        materials["aether"],      # 5
    ]
    for m in mat_list:
        obj.data.materials.append(m)

    # Classify each polygon face
    mesh.update()
    for poly in mesh.polygons:
        # Calculate face center in Godot coordinates
        # Blender center: (bx, by, bz) -> Godot (gx=bx, gz=-by, gy=bz)
        gx = poly.center.x
        gz = -poly.center.y
        elev = poly.center.z
        norm_z = poly.normal.z  # In Blender, +Z is up (elevation normal)

        # 1. Very steep slope (Cliff / Stone Wall)
        # Normal Z < 0.76 is approximately > 40 degrees incline
        if norm_z < 0.76:
            # Check if near an Aether rock feature (accent)
            d_aether1 = math.hypot(gx - (-18.0), gz - (-12.0))
            d_aether2 = math.hypot(gx - (18.0), gz - (-14.0))
            if (d_aether1 < 6.0 or d_aether2 < 6.0) and 3.0 < elev < 14.0:
                poly.material_index = 5  # aether rock
            else:
                poly.material_index = 2  # stone cliff
            continue

        # 2. Canyon / Ravine Floor Water / Sludge
        if elev < 1.2:
            poly.material_index = 4  # water
            continue
        elif elev < 2.8 and abs(gx - 14.0) < 12.0:
            poly.material_index = 2  # wet stone at canyon floor
            continue

        # 3. Industrial Staging Grounds / HQ Bases / Fortress Plateau
        dp = math.hypot(gx - PLAYER_HQ_POS[0], gz - PLAYER_HQ_POS[1])
        de = math.hypot(gx - ENEMY_HQ_POS[0], gz - ENEMY_HQ_POS[1])
        dfg = math.hypot(gx - FORTRESS_GATE_POS[0], gz - FORTRESS_GATE_POS[1])
        dw = math.hypot(gx - WEST_FOUNDRY_POS[0], gz - WEST_FOUNDRY_POS[1])
        deb = math.hypot(gx - EAST_BASTION_POS[0], gz - EAST_BASTION_POS[1])

        if dp < 15.0 or de < 16.0 or dfg < 14.0 or dw < 10.0 or deb < 11.0:
            poly.material_index = 3  # industrial ground
            continue

        # 4. Roads / Worn Dirt Routes
        # Check proximity to strategic route axes
        is_route = False
        # North route: (-32,-32)->(2,-18)->(28,-10)
        d_nr1, _ = dist_point_to_segment(gx, gz, -32.0, -32.0, 2.0, -18.0)
        d_nr2, _ = dist_point_to_segment(gx, gz, 2.0, -18.0, 26.0, -10.0)
        # Central main highway: (-22,4)->(0,0)->(14,0)->(25,14)
        d_cr1, _ = dist_point_to_segment(gx, gz, -22.0, 4.0, 0.0, 0.0)
        d_cr2, _ = dist_point_to_segment(gx, gz, 0.0, 0.0, 14.0, 0.0)
        d_cr3, _ = dist_point_to_segment(gx, gz, 22.0, 0.0, 25.0, 14.0)
        # South route: (-22,4)->(-2,18)->(26,28)
        d_sr1, _ = dist_point_to_segment(gx, gz, -22.0, 4.0, -2.0, 18.0)
        d_sr2, _ = dist_point_to_segment(gx, gz, -2.0, 18.0, 26.0, 28.0)

        min_route_dist = min(d_nr1, d_nr2, d_cr1, d_cr2, d_cr3, d_sr1, d_sr2)
        if min_route_dist < 4.5:
            poly.material_index = 1  # dirt route
            continue

        # 5. Central Battlefield Area (Mix of worn dirt and tough grass)
        dc = math.hypot(gx - CENTRAL_NEXUS_POS[0], gz - CENTRAL_NEXUS_POS[1])
        if dc < 14.0:
            # Central clash arena: mostly worn dirt with industrial fringes
            poly.material_index = 1 if (gx + gz) % 2.5 > 0.8 else 3
            continue

        # 6. Default Plateau Ground: Dark Grass
        # If moderate slope (norm_z < 0.88), use rock/stone edge
        if norm_z < 0.86:
            poly.material_index = 2  # stone edge
        else:
            poly.material_index = 0  # dark grass

    # Smooth shading for organic terrain look
    mesh.polygons.foreach_set("use_smooth", [True] * len(mesh.polygons))
    mesh.update()

    mat_counts = {}
    for poly in mesh.polygons:
        idx = poly.material_index
        mat_counts[idx] = mat_counts.get(idx, 0) + 1
    for idx, count in sorted(mat_counts.items()):
        mat_name = obj.data.materials[idx].name
        print(f"  Material slot {idx} ({mat_name}): {count} faces")

    return obj, height_grid, nx, nz


def export_heightmap(height_grid, nx, nz, filepath):
    """Exports a 16-bit grayscale PNG heightmap normalized to 0..65535."""
    if not HAS_PIL:
        print("PIL not available, skipping heightmap generation.")
        return False

    min_h = 0.0
    max_h = PERIMETER_CLIFF_H + 4.0

    raw_data = bytearray()
    # Image rows from top (Z min in Blender Y) to bottom (Z max in Blender Y)
    # To match standard heightmap orientation (Top = -Z / North, Bottom = +Z / South)
    for iz in range(nz):
        for ix in range(nx):
            h = height_grid[iz][ix]
            val = int(clamp((h - min_h) / (max_h - min_h), 0.0, 1.0) * 65535)
            # 16-bit little-endian
            raw_data.append(val & 0xFF)
            raw_data.append((val >> 8) & 0xFF)

    img = Image.frombytes("I;16", (nx, nz), bytes(raw_data))
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    img.save(filepath)
    print(f"Exported 16-bit heightmap to {filepath} ({nx}x{nz})")
    return True


def clamp(val, min_val, max_val):
    return max(min_val, min(max_val, val))


# ==============================================================================
# MAIN GENERATION PIPELINE
# ==============================================================================
def main():
    print("=== AETHER CROWN TERRAIN FOUNDATION GENERATOR ===")
    # 1. Clear existing scene
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for col in (bpy.data.meshes, bpy.data.materials, bpy.data.textures, bpy.data.images):
        for item in list(col):
            try:
                col.remove(item)
            except Exception:
                pass

    # 2. Create materials
    mats = create_materials()

    # 3. Build terrain mesh
    obj, height_grid, nx, nz = build_terrain_mesh(mats)

    # Stats
    poly_count = len(obj.data.polygons)
    vert_count = len(obj.data.vertices)
    tri_count = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    print(f"Terrain Mesh Generated:")
    print(f"  Dimensions: {MAP_WIDTH}m x {MAP_DEPTH}m (Step: {GRID_STEP}m)")
    print(f"  Vertices: {vert_count}")
    print(f"  Faces: {poly_count}")
    print(f"  Triangles: {tri_count}")

    # 4. Save .blend source
    os.makedirs(os.path.dirname(SOURCE_BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)
    print(f"Saved .blend source: {SOURCE_BLEND}")

    # 5. Export GLB
    # Make sure terrain object is selected and active
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj

    for glb_path in [EXPORT_GLB_INTERMEDIATE, EXPORT_GLB_GAME]:
        os.makedirs(os.path.dirname(glb_path), exist_ok=True)
        bpy.ops.export_scene.gltf(
            filepath=glb_path,
            export_format="GLB",
            use_selection=True,
            export_apply=True,
            export_yup=True,
            export_normals=True,
            export_materials="EXPORT",
            export_animations=False,
        )
        print(f"Exported GLB: {glb_path} ({os.path.getsize(glb_path)} bytes)")

    # 6. Export Heightmap
    export_heightmap(height_grid, nx, nz, HEIGHTMAP_PNG)
    print("=== TERRAIN GENERATION COMPLETE ===")


if __name__ == "__main__":
    main()
