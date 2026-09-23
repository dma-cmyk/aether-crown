"""Generate the Aether Crown RTS Production Terrain Foundation 01 (Final Visual/Topology Polish).

Creates:
- blender/source/aether_crown_terrain_foundation.blend
- blender/exports/map/aether_crown_terrain_foundation.glb
- game/assets/models/map/aether_crown_terrain_foundation.glb
- blender/exports/map/aether_crown_terrain_heightmap.png

Key Final Polish Enhancements:
1. THREE ROUTES CONTINUOUS READABILITY:
   - North: Elevated ridge route (13.5m) with sharp southern cliff dropping to central battlefield.
     Continuous brown earth corridor connecting Player Base to Enemy Base via North Relay.
   - Central: Massive open clash platform (8.0m, ~45m x 35m) with organic battle-worn dirt/industrial floor leading directly across Heavy Bridge.
   - South: Lowland industrial corridor (4.5m) winding around the southern ravine with terraced step.
   - Route classification takes precedence on traversal ramps so paths stay unbroken from Base to Base.
2. PERIMETER / CANYON BASIN:
   - Box-distance adaptive perimeter rim that preserves Player Base (-32,-32) and Enemy Base (34,36)
     completely free from mountain clipping while forming an organic, craggy basin edge at map borders.
3. MATERIAL & COLOR PALETTE:
   - Dark muted grass (industrial fantasy olive)
   - Industrial brown earth (iron-rich worn path, distinct contrast)
   - Charcoal rock (stark, dramatic cliffs & crags)
   - Dark gray constructed ground (compacted staging/foundry ground)
   - Very restrained cyan Aether (deep glowing mineral seam)
4. CLIFF STRATA & VISUAL QUALITY:
   - Subtle rock striation on steep slopes for convincing geological silhouette.
   - Smooth bridge abutment transitions without harsh cutoffs.
5. PERFORMANCE:
   - Exact 140m x 140m scale, 1m grid (19,881 vertices, 39,200 triangles) for Intel Iris Xe.
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
PERIMETER_CLIFF_H = 22.0      # Out-of-bounds mountain rim nominal

# Key Godot Locations (X, Z)
PLAYER_HQ_POS = (-32.0, -32.0)
ENEMY_HQ_POS = (34.0, 36.0)
WEST_FOUNDRY_POS = (-22.0, 4.0)
NORTH_RELAY_POS = (0.0, -18.0)
CENTRAL_NEXUS_POS = (-8.0, 0.0)
SOUTH_WORKS_POS = (-2.0, 20.0)
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
    n = 0.52 * math.sin(x * 0.14 + z * 0.11)
    n += 0.30 * math.cos(x * 0.28 - z * 0.22)
    n += 0.16 * math.sin(x * 0.58 + z * 0.52)
    n += 0.07 * math.cos(x * 1.25 - z * 1.15)
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
        factor_p = 1.0 - smoothstep(18.0, 32.0, dp)
        h = h * (1.0 - factor_p) + PLAYER_PLATEAU_H * factor_p

    # --------------------------------------------------------------------------
    # 2. Enemy Fortress Plateau (around 34, 36)
    # --------------------------------------------------------------------------
    de = math.hypot(gx - ENEMY_HQ_POS[0], gz - ENEMY_HQ_POS[1])
    if de < 34.0:
        factor_e = 1.0 - smoothstep(18.0, 32.0, de)
        h = max(h, h * (1.0 - factor_e) + ENEMY_PLATEAU_H * factor_e)

    # --------------------------------------------------------------------------
    # 3. North Mountain Ridge (High Ground Route: Player Base -> North Relay -> Fortress Flank)
    # --------------------------------------------------------------------------
    north_segs = [
        (-32.0, -32.0, -18.0, -26.0),
        (-18.0, -26.0, 0.0, -18.0),
        (0.0, -18.0, 16.0, -16.0),
        (16.0, -16.0, 28.0, -8.0),
        (28.0, -8.0, 34.0, 6.0),
        (34.0, 6.0, 34.0, 24.0),
        (34.0, 24.0, 34.0, 36.0),
    ]
    min_dn = 999.0
    for ax, az, bx, bz in north_segs:
        d_line, _ = dist_point_to_segment(gx, gz, ax, az, bx, bz)
        if d_line < min_dn:
            min_dn = d_line

    if min_dn < 18.0:
        factor_n = 1.0 - smoothstep(7.0, 15.0, min_dn)
        h = max(h, h * (1.0 - factor_n) + NORTH_ROUTE_H * factor_n)

    # Sheer cliff on North Route's south boundary overlooking Central Battlefield
    if -14.0 <= gx <= 18.0 and -16.0 <= gz <= -7.0:
        cliff_dist_s = gz - (-16.0)
        if 0.0 <= cliff_dist_s <= 8.5:
            cliff_f = smoothstep(1.5, 7.0, cliff_dist_s)
            h = min(h, NORTH_ROUTE_H * (1.0 - cliff_f) + CENTRAL_BATTLEFIELD_H * cliff_f)

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

    # Ramp: West Foundry (-22, 4) to Central Battlefield (-8, 0)
    d_rwc, t_rwc = dist_point_to_segment(gx, gz, -20.0, 4.0, -8.0, 0.0)
    if d_rwc < 16.0:
        f_rwc = 1.0 - smoothstep(8.5, 14.5, d_rwc)
        ramp_h = WEST_FOUNDRY_H * (1.0 - t_rwc) + CENTRAL_BATTLEFIELD_H * t_rwc
        h = h * (1.0 - f_rwc) + ramp_h * f_rwc

    # --------------------------------------------------------------------------
    # 5. Central Nexus Battlefield Flat Arena (around -8, 0)
    # --------------------------------------------------------------------------
    dc = math.hypot(gx - CENTRAL_NEXUS_POS[0], gz - CENTRAL_NEXUS_POS[1])
    if dc < 28.0:
        factor_c = 1.0 - smoothstep(18.0, 26.0, dc)
        h = h * (1.0 - factor_c) + CENTRAL_BATTLEFIELD_H * factor_c

    # --------------------------------------------------------------------------
    # 6. South Lowland Route (West Foundry -> South Works -> East Fortress Approach)
    # --------------------------------------------------------------------------
    south_segs = [
        (-22.0, 4.0, -16.0, 14.0),
        (-16.0, 14.0, -2.0, 20.0),
        (-2.0, 20.0, 14.0, 26.0),
        (14.0, 26.0, 26.0, 28.0),
        (26.0, 28.0, 34.0, 34.0),
        (34.0, 34.0, 34.0, 36.0),
    ]
    min_ds = 999.0
    for ax, az, bx, bz in south_segs:
        d_line, _ = dist_point_to_segment(gx, gz, ax, az, bx, bz)
        if d_line < min_ds:
            min_ds = d_line

    if min_ds < 18.0:
        factor_s = 1.0 - smoothstep(8.0, 16.0, min_ds)
        h = h * (1.0 - factor_s) + SOUTH_ROUTE_H * factor_s

    # Flatten South Works city pad
    ds = math.hypot(gx - SOUTH_WORKS_POS[0], gz - SOUTH_WORKS_POS[1])
    if ds < 15.0:
        factor_sw = 1.0 - smoothstep(8.0, 14.0, ds)
        h = h * (1.0 - factor_sw) + SOUTH_ROUTE_H * factor_sw

    # Terraced step cliff between Central Battlefield (Y=8.0m) and South Route (Y=4.5m)
    if -16.0 <= gx <= 12.0 and 8.0 <= gz <= 17.0:
        step_dist = gz - 8.0
        step_f = smoothstep(1.5, 6.0, step_dist)
        h = min(h, CENTRAL_BATTLEFIELD_H * (1.0 - step_f) + SOUTH_ROUTE_H * step_f)

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
        f_app = 1.0 - smoothstep(9.0, 16.5, d_gate_app)
        ramp_h = 8.2 * (1.0 - t_app) + FORTRESS_GATE_H * t_app
        h = max(h, h * (1.0 - f_app) + ramp_h * f_app)

    # Fortress Gate Plateau flattening (38, 20) - ample 40m wide flat pad for gate & walls
    dfg = math.hypot(gx - FORTRESS_GATE_POS[0], gz - FORTRESS_GATE_POS[1])
    if dfg < 23.0:
        factor_fg = 1.0 - smoothstep(14.5, 21.5, dfg)
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
    ravine_cx = 18.0 + 2.5 * math.sin(gz * 0.09)
    d_ravine_x = abs(gx - ravine_cx)

    # Bridge Slot: centered at gx = 18.0, gz = 0.0
    # Heavy Military Bridge has span = 32m (X: 2.0 to 34.0), clear gorge width = 16m (X: 10.0 to 26.0).
    is_in_bridge_corridor = abs(gz) <= 12.0
    bridge_blend = 1.0 - smoothstep(6.5, 12.0, abs(gz))

    # Base gorge half width: 8.5m nominal (17m total width)
    gorge_half_w = 8.5 + 2.0 * math.cos(gz * 0.11)
    if is_in_bridge_corridor:
        gorge_half_w = gorge_half_w * (1.0 - bridge_blend) + 8.0 * bridge_blend
        ravine_cx = ravine_cx * (1.0 - bridge_blend) + 18.0 * bridge_blend
        d_ravine_x = abs(gx - ravine_cx)

    # Ravine carving applies if north of South route (gz < 24.0)
    if d_ravine_x < gorge_half_w + 4.5 and gz < 24.0:
        cliff_t = smoothstep(gorge_half_w - 2.5, gorge_half_w + 1.2, d_ravine_x)
        floor_h = RAVINE_FLOOR_H
        if gz > 14.0:
            t_s = smoothstep(14.0, 24.0, gz)
            floor_h = floor_h * (1.0 - t_s) + SOUTH_ROUTE_H * t_s
        h = floor_h * (1.0 - cliff_t) + h * cliff_t

    # Bridge Abutment Landing Terraces (Ensures bridge sits on rock solid 8.0m deck ground)
    if 1.0 <= gx <= 10.2 and abs(gz) <= 8.5:
        f_ab_w = 1.0 - smoothstep(6.0, 8.5, abs(gz))
        h = h * (1.0 - f_ab_w) + CENTRAL_BATTLEFIELD_H * f_ab_w

    if 25.8 <= gx <= 35.0 and abs(gz) <= 8.5:
        f_ab_e = 1.0 - smoothstep(6.0, 8.5, abs(gz))
        h = h * (1.0 - f_ab_e) + CENTRAL_BATTLEFIELD_H * f_ab_e

    # --------------------------------------------------------------------------
    # 10. Perimeter Mountains & Rim Cliffs (Organic Basin Boundary)
    # --------------------------------------------------------------------------
    # Use box distance so corners (Player Base at -32,-32 and Enemy Base at 34,36)
    # are completely preserved and never swallowed by circular radius!
    box_dist = max(abs(gx), abs(gz))
    angle = math.atan2(gz, gx)
    # Fluctuate rim threshold organically between 51m and 60m
    rim_threshold = 54.0 + 4.5 * math.sin(angle * 3.0 + 0.5) + 2.5 * math.cos(angle * 5.0 - 0.8)

    if box_dist > rim_threshold - 5.0:
        f_edge = smoothstep(rim_threshold - 5.0, rim_threshold + 9.0, box_dist)
        crag_noise = 4.0 * math.sin(gx * 0.12 - gz * 0.10) + 2.5 * math.cos(gx * 0.20 + gz * 0.16)
        mountain_h = PERIMETER_CLIFF_H + crag_noise
        h = h * (1.0 - f_edge) + mountain_h * f_edge

    # --------------------------------------------------------------------------
    # 11. Organic Rock Micro-Noise & Subtle Geological Strata
    # --------------------------------------------------------------------------
    noise_weight = 0.24
    if dc < 18.0 or dp < 16.0 or de < 16.0 or dw < 12.0 or ds < 12.0 or deb < 12.0 or dfg < 14.0:
        noise_weight = 0.04
    if is_in_bridge_corridor and 2.0 <= gx <= 26.0:
        noise_weight = 0.02

    strata = 0.18 * math.sin(h * 1.57) if noise_weight > 0.15 else 0.0
    h += (noise_2d(gx, gz) + strata) * noise_weight
    return max(0.0, h)


# ==============================================================================
# MESH & MATERIAL GENERATION
# ==============================================================================
def create_materials():
    """Create the stylized-realistic PBR materials with polished Aether Crown palette."""
    mats = {}
    # 1. Dark muted grass (industrial fantasy olive green)
    mats["grass"] = make_pbr("terrain_grass_dark", (0.06, 0.08, 0.05), metallic=0.02, roughness=0.92)
    # 2. Industrial brown earth (iron-rich worn path / packed dirt)
    mats["dirt"] = make_pbr("terrain_dirt_worn", (0.22, 0.15, 0.08), metallic=0.05, roughness=0.82)
    # 3. Charcoal rock (stark, dramatic basalt cliff & canyon walls)
    mats["stone"] = make_pbr("terrain_stone_cliff", (0.08, 0.08, 0.09), metallic=0.10, roughness=0.92)
    # 4. Dark gray constructed ground (compacted staging/foundry/fortress ground)
    mats["industrial"] = make_pbr("terrain_industrial_ground", (0.11, 0.11, 0.12), metallic=0.28, roughness=0.70)
    # 5. Ravine sludge / industrial runoff
    mats["water"] = make_pbr("terrain_water_ravine", (0.02, 0.04, 0.05), metallic=0.22, roughness=0.16)
    # 6. Restrained cyan Aether rock vein accent
    mats["aether"] = make_pbr("terrain_aether_rock", (0.03, 0.12, 0.18), metallic=0.15, roughness=0.45,
                              emission_color=(0.10, 0.35, 0.45), emission_strength=1.5)
    return mats


def build_terrain_mesh(materials):
    """Builds the subdivided parametric terrain grid and assigns materials."""
    nx = int(MAP_WIDTH / GRID_STEP) + 1
    nz = int(MAP_DEPTH / GRID_STEP) + 1
    x_min = -MAP_WIDTH * 0.5
    z_min = -MAP_DEPTH * 0.5

    verts = []
    height_grid = []
    for iz in range(nz):
        gz = z_min + iz * GRID_STEP
        row = []
        for ix in range(nx):
            gx = x_min + ix * GRID_STEP
            elev = get_terrain_elevation(gx, gz)
            row.append(elev)
            verts.append((gx, -gz, elev))
        height_grid.append(row)

    faces = []
    for iz in range(nz - 1):
        for ix in range(nx - 1):
            i0 = iz * nx + ix
            i1 = iz * nx + (ix + 1)
            i2 = (iz + 1) * nx + (ix + 1)
            i3 = (iz + 1) * nx + ix
            faces.append((i3, i2, i1, i0))

    mesh = bpy.data.meshes.new(name="AetherCrown_Terrain_Foundation_Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update(calc_edges=True)

    obj = bpy.data.objects.new(name="AetherCrown_Terrain_Foundation", object_data=mesh)
    bpy.context.collection.objects.link(obj)

    # Assign material slots in exact order:
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
        gx = poly.center.x
        gz = -poly.center.y
        elev = poly.center.z
        norm_z = poly.normal.z  # In Blender, +Z is up

        # 1. Very steep sheer cliffs (Canyon walls, vertical bluffs)
        # Normal Z < 0.70 is > 45 degrees incline -> sheer charcoal cliff
        if norm_z < 0.70:
            d_aether1 = math.hypot(gx - (-18.0), gz - (-12.0))
            d_aether2 = math.hypot(gx - (18.0), gz - (-14.0))
            if (d_aether1 < 6.0 or d_aether2 < 6.0) and 2.5 < elev < 14.0:
                poly.material_index = 5  # aether rock
            else:
                poly.material_index = 2  # charcoal stone cliff
            continue

        # 2. Canyon / Ravine Floor Water / Sludge
        if elev < 1.3:
            poly.material_index = 4  # sludge water
            continue
        elif elev < 2.8 and abs(gx - 16.0) < 11.0:
            poly.material_index = 2  # wet stone at canyon floor
            continue

        # 3. Industrial Staging Grounds / HQ Bases / Fortress Plateau
        dp = math.hypot(gx - PLAYER_HQ_POS[0], gz - PLAYER_HQ_POS[1])
        de = math.hypot(gx - ENEMY_HQ_POS[0], gz - ENEMY_HQ_POS[1])
        dfg = math.hypot(gx - FORTRESS_GATE_POS[0], gz - FORTRESS_GATE_POS[1])
        dw = math.hypot(gx - WEST_FOUNDRY_POS[0], gz - WEST_FOUNDRY_POS[1])
        deb = math.hypot(gx - EAST_BASTION_POS[0], gz - EAST_BASTION_POS[1])

        if dp < 15.0 or de < 16.0 or dfg < 14.5 or dw < 10.0 or deb < 10.0:
            poly.material_index = 3  # dark gray industrial ground
            continue

        # 4. Strategic Three Routes (Continuous brown earth corridors)
        # Prioritize path classification before moderate slope check so ramps stay continuous!
        # North route: (-32,-32) -> (-18,-26) -> (0,-18) -> (16,-16) -> (28,-8) -> (34,6) -> (34,24) -> (34,36)
        d_nr1, _ = dist_point_to_segment(gx, gz, -32.0, -32.0, -18.0, -26.0)
        d_nr2, _ = dist_point_to_segment(gx, gz, -18.0, -26.0, 0.0, -18.0)
        d_nr3, _ = dist_point_to_segment(gx, gz, 0.0, -18.0, 16.0, -16.0)
        d_nr4, _ = dist_point_to_segment(gx, gz, 16.0, -16.0, 28.0, -8.0)
        d_nr5, _ = dist_point_to_segment(gx, gz, 28.0, -8.0, 34.0, 6.0)
        d_nr6, _ = dist_point_to_segment(gx, gz, 34.0, 6.0, 34.0, 36.0)
        min_north_dist = min(d_nr1, d_nr2, d_nr3, d_nr4, d_nr5, d_nr6)

        # Central route: (-32,-32) -> (-22,4) -> (-8,0) -> (10,0) and (26,0) -> (38,20) -> (34,36)
        d_cr0, _ = dist_point_to_segment(gx, gz, -32.0, -32.0, -22.0, 4.0)
        d_cr1, _ = dist_point_to_segment(gx, gz, -22.0, 4.0, -8.0, 0.0)
        d_cr2, _ = dist_point_to_segment(gx, gz, -8.0, 0.0, 10.0, 0.0)
        d_cr3, _ = dist_point_to_segment(gx, gz, 26.0, 0.0, 38.0, 20.0)
        d_cr4, _ = dist_point_to_segment(gx, gz, 38.0, 20.0, 34.0, 36.0)
        min_central_dist = min(d_cr0, d_cr1, d_cr2, d_cr3, d_cr4)

        # South route: (-22,4) -> (-16,14) -> (-2,20) -> (14,26) -> (26,28) -> (34,36)
        d_sr1, _ = dist_point_to_segment(gx, gz, -22.0, 4.0, -16.0, 14.0)
        d_sr2, _ = dist_point_to_segment(gx, gz, -16.0, 14.0, -2.0, 20.0)
        d_sr3, _ = dist_point_to_segment(gx, gz, -2.0, 20.0, 14.0, 26.0)
        d_sr4, _ = dist_point_to_segment(gx, gz, 14.0, 26.0, 26.0, 28.0)
        d_sr5, _ = dist_point_to_segment(gx, gz, 26.0, 28.0, 34.0, 36.0)
        min_south_dist = min(d_sr1, d_sr2, d_sr3, d_sr4, d_sr5)

        min_route_dist = min(min_north_dist, min_central_dist, min_south_dist)
        if min_route_dist < 6.8:
            poly.material_index = 1  # industrial brown earth path
            continue

        # 5. Central Battlefield Arena (Broad clash floor: organic mix of dirt and industrial slag)
        dc = math.hypot(gx - CENTRAL_NEXUS_POS[0], gz - CENTRAL_NEXUS_POS[1])
        if dc < 18.0:
            arena_noise = noise_2d(gx * 0.35, gz * 0.35)
            poly.material_index = 1 if arena_noise > -0.15 else 3
            continue

        # 6. Default Ground: Dark Muted Grass / Stone Edges
        if norm_z < 0.84:
            poly.material_index = 2  # charcoal stone edge
        else:
            poly.material_index = 0  # dark muted grass

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
    """Exports a 16-bit grayscale PNG heightmap for Godot Navigation / Physics / Minimap."""
    if not HAS_PIL:
        print("PIL not available in Blender Python environment, skipping PNG heightmap generation.")
        return

    min_h = 0.0
    max_h = 26.0  # Normalized to 0..26m range

    img = Image.new("I;16", (nx, nz))
    pixels = []
    for iz in range(nz):
        for ix in range(nx):
            h = height_grid[iz][ix]
            norm = max(0.0, min(1.0, (h - min_h) / (max_h - min_h)))
            val16 = int(norm * 65535.0)
            pixels.append(val16)
    img.putdata(pixels)
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    img.save(filepath)
    print(f"Heightmap exported: {filepath} ({nx}x{nz}, 16-bit)")


# ==============================================================================
# MAIN WORKFLOW
# ==============================================================================
def main():
    print("=== Aether Crown RTS Production Terrain Foundation 01 Generator (Final Polish) ===")

    # Reset scene
    bpy.ops.wm.read_factory_settings(use_empty=True)

    # 1. Materials
    print("Creating stylized-realistic PBR materials...")
    materials = create_materials()

    # 2. Build Terrain Mesh
    print("Generating parametric terrain mesh (140m x 140m, 1m grid)...")
    terrain_obj, height_grid, nx, nz = build_terrain_mesh(materials)

    poly_count = len(terrain_obj.data.polygons)
    vert_count = len(terrain_obj.data.vertices)
    tri_count = poly_count * 2
    print(f"Terrain Mesh Stats: {vert_count} verts, {poly_count} quads, {tri_count} tris")

    # 3. Save .blend source
    os.makedirs(os.path.dirname(SOURCE_BLEND), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=SOURCE_BLEND)
    print(f"Saved Blender source: {SOURCE_BLEND}")

    # 4. Export GLB
    os.makedirs(os.path.dirname(EXPORT_GLB_INTERMEDIATE), exist_ok=True)
    os.makedirs(os.path.dirname(EXPORT_GLB_GAME), exist_ok=True)

    # Export to intermediate
    bpy.ops.export_scene.gltf(
        filepath=EXPORT_GLB_INTERMEDIATE,
        export_format="GLB",
        use_selection=False,
        export_apply=True,
        export_yup=True,
    )
    print(f"Exported intermediate GLB: {EXPORT_GLB_INTERMEDIATE}")

    # Export directly to Godot assets
    bpy.ops.export_scene.gltf(
        filepath=EXPORT_GLB_GAME,
        export_format="GLB",
        use_selection=False,
        export_apply=True,
        export_yup=True,
    )
    print(f"Exported Godot game GLB: {EXPORT_GLB_GAME}")

    # 5. Export 16-bit Heightmap
    export_heightmap(height_grid, nx, nz, HEIGHTMAP_PNG)

    print("=== Terrain Foundation Generation Complete ===")


if __name__ == "__main__":
    main()
