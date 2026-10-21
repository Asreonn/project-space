# PROGRESS

Gerçek durum kaydı (GAME_PLAN §21.11). Bitmeyeni bitti yazma. Tarih: Europe/Istanbul.

| Tarih | Rol | Ne yapıldı | Durum | PR |
|---|---|---|---|---|
| 2026-10-21 | Bootstrap | Repo, Godot 4.7 iskeleti, dokümanlar, brief'ler, roadmap, araç notları | ✅ | — |
| 2026-10-21 | Godot Engineer | Gemi veri şeması (`scripts/data/`: Grade, ShipStat, StatModifier, CostEntry, ShipPartLevel, ShipPartDefinition, ShipHullDefinition, ShipInstanceState, ShipStatsResolver, ShipDataValidator), `ShipAssembler` (`scripts/core/`), starter hull + 4 parça `.tres` (yalnız L1, değerler `balance_prototype`), `scenes/main/ship_assembly_test.tscn`, GUT 9.7.1 + 37 birim testi | 🟡 Branch `feat/m1-ship-data-model`, push/PR yok. Parça modelleri (GLB) yok → kod placeholder üretiyor; `model_anchors.md` bekleniyor | — |
| 2026-10-22 | VFX Engineer | MVP efektleri (`scenes/vfx/`): `vfx_director.tscn` (EventBus → kazma ışını + kıvılcım, asteroid kırılma S/M/L veya yarıçap, cevher parıltısı, toplama pop'u, sabit havuz), `engine_trail.tscn` (`set_thrust(amount, boosting)`, `FX_EngineTrail_<n>` otomatik), `space_background.tscn` (nebula + 2 yıldız katmanı parallax + gezegen, palet `.tres`), `environment_space.tres` (AgX, glow, hafif grade), `post_fx.tscn` (vignette + çok hafif CA), `vfx_lookdev.tscn` + yakalama modu, `m_lowpoly_base/emissive.tres` | 🟡 Branch `vfx/mvp-effects` (box, bundle), push/PR yok. Sektöre entegre edilmedi (Engineer/Gameplay instance edecek). FPS gerçek GPU'da ölçülmedi: box yalnız llvmpipe (yazılım), sayılar yalnız göreli. Asteroid hasar kızarması, part_upgraded parlaması, hasar/patlama (MVP dışı) yok | — |
