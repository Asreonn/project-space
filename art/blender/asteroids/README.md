# Asteroids (MVP batch 1)

Generator: `asteroids.py` (Blender 5.2, headless) using `../_shared/ps_common.py`.
`blender -b -P asteroids.py` writes `assets/models/asteroids/*.glb`, `*_collision.glb` and `asteroids.blend`.
Preview renders: `blender -b -P ../_shared/env_renders.py -- asteroids|sockets`. These need
`previews/starter_shuttle_01_L1_preview.glb` for scale (the file lives on the ship branch).

Units 1u = 1 m, Godot +Y up, pivot = bbox centre. One mesh per asset using the shared palette:
`M_ps_palette` (opaque) and `M_ps_glow` (emissive seams / veins).

| asset | form | radius (half-extent XZ) | tris | collision tris |
|---|---|---|---|---|
| asteroid_s_01/02/03 | boulder / angular / twin-lobe | 0.9 / 1.05 / 1.2 m | 140 each | 112 / 98 / 88 |
| asteroid_m_01/02/03 | boulder / angular / twin-lobe | 2.2 / 2.5 / 2.8 m | 290 each | 174 / 152 / 144 |
| asteroid_l_01/02/03 | boulder / angular / twin-lobe | 3.5 / 4.0 / 4.5 m | 480 each | 220 / 168 / 192 |
| asteroid_ore_m_01 | boulder + glowing vein bands | 2.5 m | 296 | 142 |
| asteroid_ore_l_01 | angular + glowing vein bands | 4.0 m | 416 | 148 |
| asteroid_chunk_01/02/03 | break-apart shards | 0.6 / 1.0 / 1.3 m long | 18 / 18 / 16 | same hull |

Sizes follow `docs/briefs/mvp.md` §3 (binding): radius S 0.9-1.2, M 2.2-2.8, L 3.5-4.5 m. Ship = 1.84 m.

The ore colour shows the ore type (mvp.md §3):
- Regular rocks: a thin flush orange glowing seam (`ore_common_solid`) across the top, readable top-down.
- `asteroid_ore_*`: recessed blue glowing veins (`crystal_blue_solid`).
- Glow faces use `M_ps_glow`. Everything else uses `M_ps_palette`.

Empties are children of the mesh. Each socket's +Y points outward along the surface normal:
- `OreSocket_0..n`: surface node mounts (S 2, M 3, L 4). They are spread over the upper half and
  the silhouette so they read top-down.
- `VeinSocket_0..1`: ore variants only, placed on the glowing veins. Node layers are out of MVP scope
  (mvp.md §2), so the sockets are provided for later.
- `CoreSocket`: core node, at the pivot.

Collision: `<name>_collision.glb` is one convex hull mesh. Use it for a ConvexPolygonShape3D.
