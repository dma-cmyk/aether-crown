"""Generate the Aether Crown RTS Production Terrain Texture Pack (Fourier Spectral Synthesis).

Generates 4 seamless/tileable PBR texture sets (1024x1024):
1. Dark Industrial Grass (albedo, normal, roughness)
2. Worn Industrial Dirt (albedo, normal, roughness)
3. Charcoal Cliff Rock (albedo, normal, roughness)
4. Industrial Slag Ground (albedo, normal, roughness)

Outputs:
game/assets/textures/terrain/<set_name>/terrain_<set_name>_<map_type>.png

Requirements:
- 100% mathematically seamless / periodic boundary conditions via Fourier space filtering.
- True isotropic synthesis (zero directional banding or diagonal grid artifacts).
- Tuned specifically for RTS distance viewing (medium-scale breakup: 4m - 16m).
- No external textures, fully reproducible via NumPy + PIL.
"""

import math
import os
import sys
import numpy as np
from PIL import Image

SCRIPT_DIR = os.path.abspath(os.path.dirname(__file__))
ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
TEXTURE_OUT_DIR = os.path.join(ROOT, "game", "assets", "textures", "terrain")

RES = 1024  # 1024x1024 texture resolution


# ==============================================================================
# MATHEMATICAL HELPERS (Fourier Spectral Synthesis for 100% Seamlessness & Isotropy)
# ==============================================================================
def generate_fourier_noise(res, alpha=2.2, k_min=1.5, k_max=256.0, aniso_y=1.0, seed=42):
    """Generates a seamless, isotropic fractional Brownian motion (fBm) field using Fourier filtering.

    - Periodic boundary condition is guaranteed by the discrete Fourier transform.
    - True isotropy: power spectrum depends solely on radial wavenumber k = sqrt(kx^2 + (ky/aniso_y)^2).
    - aniso_y > 1.0 stretches features horizontally (used for geological rock strata).
    """
    np.random.seed(seed)
    
    # Frequency grids (-res/2 to res/2)
    kx = np.fft.fftfreq(res) * res
    ky = np.fft.fftfreq(res) * res
    kxx, kyy = np.meshgrid(kx, ky)
    
    # Anisotropic / Isotropic radial wavenumber
    k_radial = np.sqrt(kxx**2 + (kyy / aniso_y)**2)
    k_radial[0, 0] = 1.0  # Avoid division by zero at DC
    
    # Power spectral density S(k) ~ 1 / (k^2 + k_min^2)^(alpha/2)
    # Bandpass / low-pass filter
    spectrum = 1.0 / np.power(k_radial**2 + k_min**2, alpha / 2.0)
    spectrum[k_radial > k_max] = 0.0
    spectrum[0, 0] = 0.0  # Zero DC component (zero-mean)
    
    # White noise with independent random phase
    phase = np.random.uniform(0.0, 2.0 * np.pi, (res, res))
    amplitude = np.random.rayleigh(1.0, (res, res))
    complex_fourier = amplitude * (np.cos(phase) + 1j * np.sin(phase)) * spectrum
    
    # Inverse FFT to get spatial field
    spatial = np.fft.ifft2(complex_fourier).real
    
    # Normalize to [0.0, 1.0]
    s_min = spatial.min()
    s_max = spatial.max()
    norm = (spatial - s_min) / (s_max - s_min + 1e-6)
    return norm.astype(np.float32)


def height_to_normal_map(height_field, strength=2.2):
    """Computes a tangent space normal map (OpenGL format: +Y up) with seamless periodic roll."""
    dz_dx = (np.roll(height_field, -1, axis=1) - np.roll(height_field, 1, axis=1)) * 0.5
    dz_dy = (np.roll(height_field, -1, axis=0) - np.roll(height_field, 1, axis=0)) * 0.5

    nx = -dz_dx * strength
    ny = dz_dy * strength  # OpenGL / Godot Y+ up
    nz = np.ones_like(height_field)

    norm = np.sqrt(nx * nx + ny * ny + nz * nz)
    nx /= norm
    ny /= norm
    nz /= norm

    r = ((nx + 1.0) * 0.5 * 255.0).astype(np.uint8)
    g = ((ny + 1.0) * 0.5 * 255.0).astype(np.uint8)
    b = ((nz + 1.0) * 0.5 * 255.0).astype(np.uint8)

    return np.stack([r, g, b], axis=-1)


def save_image(array, filepath):
    """Saves uint8 numpy array to PNG."""
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    img = Image.fromarray(array)
    img.save(filepath, format="PNG")
    print(f"Saved texture: {filepath}")


# ==============================================================================
# TEXTURE SET GENERATORS
# ==============================================================================
def generate_dark_grass(out_dir):
    """1. DARK INDUSTRIAL GRASS: Muted dark olive, damaged dry patches, dark soil variation (Spectral fBm)."""
    print("Generating Dark Industrial Grass textures...")
    # Macro patches (broad 10m scale variation)
    macro = generate_fourier_noise(RES, alpha=2.6, k_min=1.2, seed=101)
    # Medium patches (4m dry/worn grass clumps)
    medium = generate_fourier_noise(RES, alpha=2.1, k_min=4.0, seed=102)
    # Fine soil grain
    fine = generate_fourier_noise(RES, alpha=1.7, k_min=14.0, seed=103)

    # Color palette:
    # Deep healthy-ish dark olive: rgb(44, 58, 30)
    # Damaged/industrial brown soil: rgb(64, 48, 32)
    # Dry yellowish/grayish patch: rgb(58, 64, 40)
    c_deep = np.array([44, 58, 30], dtype=np.float32)
    c_soil = np.array([64, 48, 32], dtype=np.float32)
    c_patch = np.array([58, 64, 40], dtype=np.float32)

    # Masks based on smooth spectral noise
    soil_mask = np.clip((macro - 0.50) * 3.2, 0.0, 1.0)[..., np.newaxis]
    patch_mask = np.clip((medium - 0.55) * 2.8, 0.0, 1.0)[..., np.newaxis]

    albedo = (1.0 - soil_mask) * c_deep + soil_mask * c_soil
    albedo = (1.0 - patch_mask * 0.45) * albedo + (patch_mask * 0.45) * c_patch
    albedo += (fine[..., np.newaxis] - 0.5) * 16.0
    albedo = np.clip(albedo, 0, 255).astype(np.uint8)

    # Roughness: grass 0.90-0.95 (230-242), dry soil 0.82-0.86 (209-220)
    roughness = (228 + (1.0 - soil_mask.squeeze()) * 14 - fine * 8).astype(np.uint8)

    height = macro * 0.6 + medium * 0.28 + fine * 0.12
    normal = height_to_normal_map(height, strength=1.8)

    save_image(albedo, os.path.join(out_dir, "terrain_dark_grass_albedo.png"))
    save_image(normal, os.path.join(out_dir, "terrain_dark_grass_normal.png"))
    save_image(roughness, os.path.join(out_dir, "terrain_dark_grass_roughness.png"))


def generate_worn_dirt(out_dir):
    """2. WORN INDUSTRIAL DIRT: Compacted brown earth, iron/rust contamination, traffic wear."""
    print("Generating Worn Industrial Dirt textures...")
    macro = generate_fourier_noise(RES, alpha=2.5, k_min=1.2, seed=201)
    gravel = generate_fourier_noise(RES, alpha=1.9, k_min=5.0, seed=202)
    grit = generate_fourier_noise(RES, alpha=1.5, k_min=16.0, seed=203)

    # Colors:
    # Compacted clay/iron earth: rgb(96, 66, 40)
    # Heavy traffic tread dark earth: rgb(64, 44, 26)
    # Rust slag / ore dust: rgb(116, 62, 30)
    c_earth = np.array([96, 66, 40], dtype=np.float32)
    c_dark = np.array([64, 44, 26], dtype=np.float32)
    c_rust = np.array([116, 62, 30], dtype=np.float32)

    traffic_mask = np.clip((macro - 0.46) * 3.0, 0.0, 1.0)[..., np.newaxis]
    rust_mask = np.clip((gravel - 0.58) * 3.0, 0.0, 1.0)[..., np.newaxis]

    albedo = (1.0 - traffic_mask) * c_earth + traffic_mask * c_dark
    albedo = (1.0 - rust_mask) * albedo + rust_mask * c_rust
    albedo += (grit[..., np.newaxis] - 0.5) * 18.0
    albedo = np.clip(albedo, 0, 255).astype(np.uint8)

    roughness = (196 + (1.0 - traffic_mask.squeeze()) * 18 + grit * 14).astype(np.uint8)

    height = macro * 0.55 + gravel * 0.30 + grit * 0.15
    normal = height_to_normal_map(height, strength=2.2)

    save_image(albedo, os.path.join(out_dir, "terrain_industrial_dirt_albedo.png"))
    save_image(normal, os.path.join(out_dir, "terrain_industrial_dirt_normal.png"))
    save_image(roughness, os.path.join(out_dir, "terrain_industrial_dirt_roughness.png"))


def generate_charcoal_rock(out_dir):
    """3. CHARCOAL CLIFF ROCK: Dark basalt, horizontal strata layers, chiseled rock fractures."""
    print("Generating Charcoal Cliff Rock textures...")
    # Horizontal strata: aniso_y=4.5 stretches features horizontally (broad strata layers)
    strata = generate_fourier_noise(RES, alpha=2.2, k_min=1.5, aniso_y=4.5, seed=301)
    # Cross fractures and rock joints
    cracks = generate_fourier_noise(RES, alpha=1.8, k_min=4.0, aniso_y=1.0, seed=302)
    # Fine stone chisel grain
    grain = generate_fourier_noise(RES, alpha=1.4, k_min=18.0, aniso_y=1.5, seed=303)

    raw_h = strata * 0.65 + cracks * 0.25 + grain * 0.10
    # Terracing effect for geological ledges
    stepped_h = np.round(raw_h * 10.0) / 10.0 * 0.30 + raw_h * 0.70

    # Colors:
    # Slate basalt: rgb(46, 46, 50)
    # Deep fissure shadow: rgb(26, 26, 28)
    # Mineral vein stripe: rgb(66, 52, 40)
    c_slate = np.array([48, 48, 52], dtype=np.float32)
    c_shadow = np.array([26, 26, 28], dtype=np.float32)
    c_mineral = np.array([66, 52, 40], dtype=np.float32)

    shade_mask = np.clip((stepped_h - 0.46) * 2.5, 0.0, 1.0)[..., np.newaxis]
    mineral_mask = np.clip((strata - 0.65) * 3.2, 0.0, 1.0)[..., np.newaxis]

    albedo = (1.0 - shade_mask) * c_shadow + shade_mask * c_slate
    albedo = (1.0 - mineral_mask) * albedo + mineral_mask * c_mineral
    albedo += (grain[..., np.newaxis] - 0.5) * 14.0
    albedo = np.clip(albedo, 0, 255).astype(np.uint8)

    roughness = (224 + (1.0 - shade_mask.squeeze()) * 16 - stepped_h * 12).astype(np.uint8)
    normal = height_to_normal_map(stepped_h, strength=2.8)

    save_image(albedo, os.path.join(out_dir, "terrain_charcoal_rock_albedo.png"))
    save_image(normal, os.path.join(out_dir, "terrain_charcoal_rock_normal.png"))
    save_image(roughness, os.path.join(out_dir, "terrain_charcoal_rock_roughness.png"))


def generate_industrial_slag(out_dir):
    """4. INDUSTRIAL SLAG GROUND: Charcoal industrial soil, crushed slag, compacted factory ground."""
    print("Generating Industrial Slag Ground textures...")
    macro = generate_fourier_noise(RES, alpha=2.5, k_min=1.2, seed=401)
    slag = generate_fourier_noise(RES, alpha=1.9, k_min=6.0, seed=402)
    grit = generate_fourier_noise(RES, alpha=1.5, k_min=20.0, seed=403)

    # Colors:
    # Asphalt/slag base: rgb(52, 52, 58)
    # Coal dust patch: rgb(30, 30, 34)
    # Gunmetal grit speck: rgb(76, 78, 86)
    c_slag = np.array([52, 52, 58], dtype=np.float32)
    c_coal = np.array([30, 30, 34], dtype=np.float32)
    c_grit = np.array([76, 78, 86], dtype=np.float32)

    dust_mask = np.clip((macro - 0.44) * 2.8, 0.0, 1.0)[..., np.newaxis]
    grit_mask = np.clip((slag - 0.60) * 3.0, 0.0, 1.0)[..., np.newaxis]

    albedo = (1.0 - dust_mask) * c_slag + dust_mask * c_coal
    albedo = (1.0 - grit_mask) * albedo + grit_mask * c_grit
    albedo += (grit[..., np.newaxis] - 0.5) * 14.0
    albedo = np.clip(albedo, 0, 255).astype(np.uint8)

    roughness = (184 + dust_mask.squeeze() * 28 - grit_mask.squeeze() * 16).astype(np.uint8)
    height = macro * 0.52 + slag * 0.32 + grit * 0.16
    normal = height_to_normal_map(height, strength=2.2)

    save_image(albedo, os.path.join(out_dir, "terrain_industrial_slag_albedo.png"))
    save_image(normal, os.path.join(out_dir, "terrain_industrial_slag_normal.png"))
    save_image(roughness, os.path.join(out_dir, "terrain_industrial_slag_roughness.png"))


# ==============================================================================
# MAIN
# ==============================================================================
def main():
    print("=== Aether Crown Production Terrain Texture Pack Generator (Fourier fBm) ===")
    out_grass = os.path.join(TEXTURE_OUT_DIR, "dark_grass")
    out_dirt = os.path.join(TEXTURE_OUT_DIR, "industrial_dirt")
    out_rock = os.path.join(TEXTURE_OUT_DIR, "charcoal_rock")
    out_slag = os.path.join(TEXTURE_OUT_DIR, "industrial_slag")

    generate_dark_grass(out_grass)
    generate_worn_dirt(out_dirt)
    generate_charcoal_rock(out_rock)
    generate_industrial_slag(out_slag)

    print("=== Texture Pack Generation Complete (12 maps in game/assets/textures/terrain/) ===")


if __name__ == "__main__":
    main()
