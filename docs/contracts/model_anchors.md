# model_anchors — starter_shuttle_01 (L1, L2, L3)

Status: L1 design approved. L2 and L3 are new and waiting on art approval. Sockets, hardpoints and seam rings are frozen for every level.
Units 1u = 1 m. Godot: Y-up, nose -Z, play plane Y = 0. Blender source: nose +Y, up +Z.
Conversion Blender (x, y, z) -> Godot (x, z, -y). Every node has identity rotation and scale 1 (transforms applied).

## Files
| What | Path (repo) |
|------|-------------|
| Part GLBs (12) | `assets/models/ships/starter_shuttle_01/<part>_L<n>.glb`, part ∈ head/body/wings/engine, n ∈ 1..3 |
| Collision | `assets/models/ships/starter_shuttle_01/starter_shuttle_01_collision.glb` (one convex mesh, 110 tris, envelope of the all-L3 ship) |
| Sources | `art/blender/ships/starter_shuttle_01/` (`starter_shuttle_01_L{1,2,3}.blend` with images packed, `starter_shuttle_01.py` generator, `ps_palette_base.png`, `ps_palette_emit.png`) |
| Preview GLBs | not in the repo (modeler box only) |
- There is no per-hull `.tscn`. Code assembles the ship through the body's `Socket_*` empties.
- Part id is `<part>_starter_shuttle_01`.
- Godot import settings (in the committed `.glb.import` files): `gltf/embedded_image_handling=3` (embed uncompressed), so no texture files get extracted next to the GLBs. `meshes/generate_lods=false`.

## Node naming
| GLB | glTF root node (= mesh object) | mesh data | materials |
|-----|-------------------------------|-----------|-----------|
| body_L<n>.glb   | Body_starter_shuttle_01   | body_L<n>_mesh   | M_ps_palette, M_ps_glow |
| head_L<n>.glb   | Head_starter_shuttle_01   | head_L<n>_mesh   | M_ps_palette, M_ps_glow |
| wings_L<n>.glb  | Wings_starter_shuttle_01  | wings_L<n>_mesh  | M_ps_palette, M_ps_glow |
| engine_L<n>.glb | Engine_starter_shuttle_01 | engine_L<n>_mesh | M_ps_palette, M_ps_glow |
- No `<part>_L<n>` wrapper node is put inside the glTF. Godot's importer adds a scene root named after the file.
- Both materials sample one 64x64 palette (4x4 cells, each 16 px, so every mip down to 4x4 keeps cell colors exact).
  M_ps_glow adds the emission map for the canopy glass, cyan lights and nozzle glow disks.

## Body (root, origin = ship center (0,0,0)). Children, identical in body_L1/L2/L3
| Empty          | Godot local (x, y, z)  | Blender (x, y, z)    | Notes |
|----------------|------------------------|----------------------|-------|
| Socket_Head    | (0, 0, -0.05)          | (0, 0.05, 0)         | head_L* origin |
| Socket_Wings   | (0, 0, 0.20)           | (0, -0.20, 0)        | wings_L* origin (both wings, symmetric) |
| Socket_Engine  | (0, 0, 0.55)           | (0, -0.55, 0)        | engine_L* origin |
| Hardpoint_L    | (-0.31, -0.03, -0.30)  | (-0.31, 0.30, -0.03) | Outboard of the left hull cheek, ahead of the wing root |
| Hardpoint_R    | (0.31, -0.03, -0.30)   | (0.31, 0.30, -0.03)  | Mirror of Hardpoint_L |
| Hardpoint_Nose | (0, 0.02, -1.00)       | (0, 1.00, 0.02)      | Centerline, 6 cm ahead of the nose tip |
- Keep-out radius 0.05 m around each hardpoint. The script checks every level and combination:
  - Hardpoint_L/R clearance: 0.099 m at L1/L2 and 0.092 m at L3 (nearest is the wings).
  - Hardpoint_Nose clearance: 0.060 m (nearest is the head tip, the same for all levels).

## RESERVED — Hardpoint_Top (future, not created)
- Godot (0, 0.205, 0.36), Blender (0, -0.36, 0.205). This is the body spine plate between the two cyan light pairs.
- Keep-out radius 0.06 m at every level and in every combination. No fins or raised geometry may go there.
  - Nearest geometry from other parts: 0.195 m (engine cowl).
  - L3 spine rails sit at x ±0.084..0.104 and leave a 0.12 m gap in y around the spot.
  - The spine plate itself, 1.8 cm below the spot, is the mount surface.

## Head (origin = Socket_Head)
| Empty           | Godot local        | Ship space (Godot)  | Levels |
|-----------------|--------------------|---------------------|--------|
| FX_MiningOrigin | (0, 0.02, -0.895)  | (0, 0.02, -0.945)   | L1–L3 (same) |

## Engine (origin = Socket_Engine)
| Empty            | L1 local (Godot)       | L2 local               | L3 local               |
|------------------|------------------------|------------------------|------------------------|
| FX_EngineTrail_0 | (-0.112, 0.028, 0.35)  | (-0.118, 0.028, 0.38)  | (-0.126, 0.028, 0.41)  |
| FX_EngineTrail_1 | ( 0.112, 0.028, 0.35)  | ( 0.118, 0.028, 0.38)  | ( 0.126, 0.028, 0.41)  |
- These sit at the nozzle exits, which move back as the nozzles grow. Each level has the same names and identity rotation. The trail points along Godot +Z.

## Hull seam contract (modeling side; every level keeps these rings)
- Head|Body seam at Blender y = +0.05: half-width 0.265, top z 0.180, bottom z -0.085.
- Body|Engine seam at Blender y = -0.55: half-width 0.290, top z 0.160, bottom z -0.085.
- Half-profile (mirrored): (0,zt) (0.35w,0.97zt) (0.72w,0.78zt) (w,0.25zt)=chine (0.86w,0.70zb) (0.45w,zb) (0,zb).
- Curve slopes and normals at the seam rings are level-independent, so any part level matches any neighbor level with no step or shading break.
- Each hull part is capped at its seam with a dark fan, so a part viewed alone has no hole.

## Dimensions (all parts at the same level, Godot)
| Level | Length (nose -> nozzle exit) | Span | Max height |
|-------|------------------------------|------|------------|
| L1 | 1.835 m | 1.40 m | 0.28 m |
| L2 | 1.865 m | 1.48 m | 0.29 m |
| L3 | 1.895 m | 1.60 m | 0.39 m (engine tail fins) |

## Tris
| Part   | L1  | L2  | L3  |
|--------|-----|-----|-----|
| head   | 276 | 332 | 372 |
| body   | 188 | 220 | 292 |
| wings  | 336 | 428 | 520 |
| engine | 336 | 364 | 396 |
| ship   | 1136| 1344| 1580|
