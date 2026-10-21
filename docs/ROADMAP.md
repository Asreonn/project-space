# ROADMAP — Project Space

> **Motor kararı:** GAME_PLAN §3.3/§20 motoru "açık" bırakıyordu. Artık **Godot 4 (4.7.x stable, Forward+, GDScript)** kesinleşti — bkz. [DECISIONS.md](DECISIONS.md) D-001.
>
> Milestone'lar GAME_PLAN §16 (P0–P9) fazlarını üretim paketlerine böler. Strateji aynı: **önce his ve kısa tamamlanabilir döngü, sonra genişlik** (§16, §17).

| Milestone | Kapsam | GAME_PLAN fazı |
|---|---|---|
| **M0 — Bootstrap** ✅ | Repo, Godot iskeleti, docs, brief'ler, araç zinciri | — |
| **M1 — Vertical Slice** ⏳ | Uçuş + kamera + asteroid alanı + laser madencilik + loot + temel HUD + 1 düşman + VFX/post-process | P0 + P1 (Laser) + P2 (tek düşman) |
| M2 — Mining Trio | Bomb + Drill, solid/liquid/gas depolama, transfer noktası | P1 tamamı |
| M3 — Combat Basics | Silah + turret tabanı, düşman davranışları, recovery/respawn | P2 |
| M4 — Salvage & Customization | Enkaz, sökme, Head/Engine/Wings/Body swap, universal hardpoint, passive electronics | P3 |
| M5 — Grade & Second Hull | E→SSS şeması, native grade, ikinci gövde | P4 |
| M6 — Region & Services | 2 sektör, radar keşfi, istasyon hizmetleri, kredi | P5 |
| M7 — Prototype Close | Save/load, profil, kullanıcı testi, demo | P6 |
| M8+ | Keşif genişlemesi, Mother Ship, crew… | P7–P9 |

---

## M1 — Vertical Slice (şimdiki hedef)

**Amaç:** 3–5 dakikalık, eğlenceli hissettiren tek ekran: gemiyle uç, asteroid alanında laser ile maden çıkar, saçılan/çıkan kaynağı topla, bir düşman drone'u savuştur; her şey referanstaki cozy pastel low-poly görünümde.

### Kapsam

1. **Starter ship** — tek gemi, ayrı `Head/Body/Engine/Wings` parçaları + hardpoint anchor'ları (§4.3, §14.2). İyi uçmalı: hızlanma, dönüş, fren, boost, hafif drift (§3.2). Flying Speed ≠ Maneuver Speed.
2. **Kamera** — 2.5D top-down, neredeyse tam üstten, hafif takip + zoom (§3.1). Perspektif (düşük FOV) ve ortografik ikisi de denenir; playtest sonrası seçilir.
3. **Asteroid alanı** — 2–3 asteroid varyasyonu (sıradan, cevherli, kristalli), seed'li yerleşim, havuzlanmış nesneler (§3.3, §15.4).
4. **Laser madencilik döngüsü** — uzak menzil, orta verim, küçük alan, ısı (§6). Asteroid yüzey/damar node'u → kaynak → **solid** depoya → kapasite dolu geri bildirimi (§6.1, §7).
5. **Loot pickup** — kopan parçalar / düşman hurdası; yaklaşınca çekim (magnet) ve toplama; kargo tipine göre kabul/ret.
6. **Temel HUD** — sol üst Hull + Fuel, sol kenarda 4 aktif slot (1: Laser aktif, 2–4 kilitli/boş), sol altta yuvarlak minimap/radar, bağlamsal heat göstergesi. **Alt envanter barı yok** (§13.1).
7. **Bir düşman** — basit drone/scout: yaklaş → ateş et → geri çekil; hasar alır, ölünce hurda/loot bırakır. Oyuncunun basit sabit silahı (fire_primary). Ölümde maliyetsiz respawn (§9.3 ÖNERİ). _(İsim/silüet: DECISIONS D-004)_
8. **VFX + post-process geçişi** — nebula/yıldız arka planı (parallax), motor izi, laser ışını + temas ısıması + kıvılcım, toplama parıltısı, hasar flaşı, patlama; glow/bloom, tonemap, renk derecelendirme, hafif vignette. Cozy, ölçülü (§14.1).
9. **Debug overlay** (F3) — FPS, hız, fuel, heat, kargo (§16 P0).

### Kapsam dışı (M1)

Bomb, Drill, liquid/gas içeriği (yalnız veri düzeyinde destek), salvage/enkaz sökme, grade/upgrade, istasyon/ekonomi, save/load, Mother Ship, ses tasarımı (placeholder serbest).

### Kabul kriterleri

- [ ] Gemi 60 FPS'te akıcı, kontrol tutarlı; boost/drift hissedilir (Gameplay + Game Designer onayı).
- [ ] Normal zoom'da gemi, asteroid, düşman ve loot birbirinden net ayrılıyor (§14.4).
- [ ] Laser → kaynak → solid kargo → "kargo dolu" zinciri çalışıyor; gaz/sıvı reddi veri düzeyinde test edilmiş.
- [ ] HUD §13.1 şemasına birebir uyuyor; alt envanter barı yok.
- [ ] Düşmanla kısa çatışma okunaklı; ölüm → respawn softlock'suz.
- [ ] Görsel olarak `02_Gameplay_Mood/01_Starter_Mining.png` hissine yakın (top-down açıyla).
- [ ] Gemi parçaları veri + model düzeyinde ayrık; ikinci gemi eklemek kod kopyalamayı gerektirmiyor (§21).
- [ ] Smoke test geçiyor; `PROGRESS.md` güncel.

### Rol bazında M1 iş listesi (özet — ayrıntı brief'lerde)

| Rol | M1 teslimleri |
|---|---|
| Game Designer | M1 kapsam kilidi, düşman adı/silüet kararı (D-004), playtest checklist, haftalık kabul |
| Gameplay Designer | `ship_controller` uçuş hissi, laser madencilik, kargo, pickup magnet, düşman AI, `data/*.tres` prototip değerleri |
| 3D Modeler | Starter ship (4 parça + hardpoint'ler), 3 asteroid, laser modülü, 3 pickup, 1 düşman, (opsiyonel) uzak gezegen |
| UI Designer | HUD (hull/fuel, 4 slot, minimap), Theme, ikon seti (laser/bomb/drill/skill, solid/liquid/gas), kargo-dolu uyarısı |
| VFX Engineer | Environment/post-process, nebula+yıldız, motor izi, laser + hit, pickup, hasar/patlama, toon/low-poly materyal |
| Godot Engineer | Mimari (autoload'lar, event bus, veri şeması), main sahne entegrasyonu, object pooling, debug overlay, test/CI, review/merge |

### Önerilen sıra (paralel)

1. **Hafta 1:** Engineer veri şeması + iskelet sahneler → Gameplay graybox uçuş (primitive mesh) · Modeler starter ship blockout · VFX environment/nebula · UI HUD wireframe.
2. **Hafta 2:** Laser + asteroid node + kargo · asteroid modelleri · laser VFX · HUD bağlama.
3. **Hafta 3:** Pickup + düşman · düşman modeli · hasar/patlama VFX · minimap · polish + playtest → M1 kabul.

---

## M2+ (özet)

- **M2 Mining Trio:** Bomb (ammo, alan, saçılım) + Drill (yakın, yüksek verim); liquid/gas pickup ve tank kapasitesi; transfer noktası. Kabul: §16 P1.
- **M3 Combat Basics:** sabit silah + turret, pirate/scout ailesi, projectile pool, recovery. Kabul: §16 P2.
- **M4 Salvage & Customization:** enkaz tarama/sökme, condition, parça swap, universal hardpoint, electronics bütçesi. Kabul: §16 P3.
- **M5 Grade & Second Hull:** E→SSS, native cap, ikinci gemi. Kabul: §16 P4.
- **M6 Region & Services:** iki sektör, istasyon, kredi, fuel menzili. Kabul: §16 P5.
- **M7 Prototype Close:** save/load, profil, kullanıcı testi. Kabul: §16 P6.
