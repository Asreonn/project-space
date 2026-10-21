# Ore pickups (MVP batch 2)

Generator: `pickups.py`, headless: `blender -b -P pickups.py`. It writes `assets/models/pickups/*.glb`, `*_collision.glb` and `pickups.blend`.
Renders: `blender -b -P ../_shared/env_renders.py -- pickups`.

| asset | resource | look | size | tris | collision tris |
|---|---|---|---|---|---|
| ore_pickup_01 | ore_common_solid | stubby orange ore crystals on a dark rock chip, mild glow | 0.48 x 0.44 x 0.38 m | 88 | 36 |
| crystal_pickup_01 | crystal_blue_solid | three tall blue crystal points, strong glow | 0.63 x 0.65 x 0.38 m | 82 | 34 |

- Pivot is the visual centre, so spin and bob tweens look right. 1u = 1 m, +Y up. No empties.
- Colours match the asteroids: orange = common ore seam, blue = crystal vein.
- Materials: `M_ps_palette` and `M_ps_glow` (shared palette, embedded in the GLB).
- The size reads top-down at the 18-32 m ortho camera. The magnet radius (~5 m) is gameplay, not mesh.
- Collision: one convex hull, for an Area3D / ConvexPolygonShape3D.
