# MVP Denge Sayıları ve His (Gameplay Designer)

**Sahip:** Gameplay Designer · **Durum:** v0.1, 2026-10-22 · **Bütün sayılar `balance_prototype`** (GAME_PLAN §15.3).
**Girdi:** [`mvp.md`](mvp.md) v1.0 (başlangıç değerleri), D-006, D-009 (gemi 1,84 m), D-011 (yalnız kredi).
**Branch:** `gameplay/mvp-loop` (taban `eng/mvp-integration` @ `eb01e01`).

Döngü: uç → asteroidi ışınla kaz → kırılır, cevher saçılır → mıknatısla topla → istasyonda sat → parçayı L1→L2→L3 yükselt.

## 0. Nerede ne var

| Ne | Dosya | Durum |
|---|---|---|
| Hull + 4 parça, L1–L3 statları ve maliyetleri | `data/ships/starter_shuttle_01.tres`, `data/parts/*_starter_shuttle_01.tres` | **.tres, bu branch'te** |
| Uçuş + kamera hissi | `data/ships/starter_flight_tuning.tres` (`FlightTuning`) | **.tres** |
| Kazma lazeri | `data/modules/laser_mk1.tres` (`MiningLaserDefinition`) | **.tres** |
| Asteroid S/M/L, cevher fiyatı, sektör, pickup | `data/balance/mvp_economy_proposal.json` | **Öneri.** Şema sınıfları (Engineer) henüz commit'li değil; alan adları Engineer'ın WIP şemasıyla aynı. Sınıflar gelince Engineer/ben `.tres`'e çeviririz |
| Denge simülasyonu | `tests/tools/mvp_balance_sim.gd` + `run_mvp_balance_sim.gd` | Gerçek `.tres` + JSON'u okur |
| Uçuş/kamera ölçümü | `tests/tools/flight_metrics.gd` + `run_flight_metrics.gd` | |

## 1. Gemi parçaları (starter_shuttle_01, native grade E)

Değerler **mutlak** (hull base + o seviyenin modifier'ı). L3 = `upgrade_caps` (grade içi tavan). Kütle her seviyede sabit.

| Parça | Stat | L1 | L2 | L3 (=cap) | L2 maliyeti | L3 maliyeti |
|---|---|---|---|---|---|---|
| **Head** | `mining_power` (10 = ×1,0) | 10 | **13 (+%30)** | 16 (+%60) | **320 kr** | 800 kr |
| Head | `damage` (MVP'de okunmaz) | 10 | 12 | 14 | | |
| **Body** | `carry_capacity` = `storage_solid` (u) | 30 | 40 (+%33) | 50 | 360 kr | 850 kr |
| Body | `hull` (MVP'de okunmaz) | 100 | 130 | 160 | | |
| **Wings** | `maneuver_speed` (°/s) | 270 | 300 | 330 | 360 kr | 750 kr |
| **Engine** | `flying_speed` (m/s) | 12,0 | 13,2 | 14,4 | 340 kr | 800 kr |
| Toplam | | | | | **1380 kr** | **3200 kr** → **4580 kr** |

- Kütle: frame 0,5 + Head 0,4 + Body 1,6 + Wings 0,5 + Engine 0,7 = **3,7 t**; lazer 0,2 t → `reference_mass` 3,9 t. Cevher 0,03 t/u (kristal 0,02): dolu L3 ambar ≈ +1,5 t → ivme ≈ ×0,8.
- Hull base'te MVP'de okunmayan alanlar duruyor (`fuel_*`, `energy_capacity` 50, `heat_capacity` 100, `radar_range` 80 …; validator kural 7 fuel ister).
- **Head L2 bilerek en ucuz L2:** ilk alınan yükseltme hissedilen olsun (lazer 14 → 18,2 HP/s; M asteroid 6,7 s → 5,2 s).

## 2. Uçuş ve kamera (gemi 1,84 m)

| Parametre | Değer | Not |
|---|---|---|
| Seyir / boost | 12 m/s / ×1,6 = 19,2 m/s | Boost 1,2 s, cooldown 2 s, **yakıt yok** |
| 0 → %95 hız | 0,67 s | `accel_time_to_max` 0,7 |
| Coast duruşu (12 m/s) | 9,1 m (5 SL) | `coast_damp` 0,8 → **1,25** (küçük gemiye göre buz hissi azaltıldı) |
| Space fren | 2,3 m (1,3 SL) | `brake_damp` 3,5 |
| 180° dönüş | 0,72 s | `maneuver_speed` 270, `turn_gain` 10, `turn_response` 26 |
| Drift (Space+W), 1 s sonra korunan yanal hız | %67 | `drift_grip_mult` 0,08 |
| Çarpışma hasarı | 0 | MVP'de hasar yok |
| Kamera | ortho, 10° eğik, `ortho_sizes` [18, 24, 32], varsayılan 24 | `look_ahead_max` 6 → 3,5 m, `aim_offset_max` 4 → 2,5 m, `boost_zoom_out` 0,12 → 0,2 |

**Kamera okunurluğu (16:9, `flight_metrics.gd`):**

| Dikey görüş | Yatay | Gemi / ekran yüksekliği | 1080p'de | Lazer 10 m / yarı yükseklik | Yarı yüksekliği geçiş @10 / 12 / 14 / 16 m/s |
|---|---|---|---|---|---|
| 18 m | 32,0 m | %10,2 | 110 px | %111 (dikeyde ekran dışına taşar) | 0,90 / 0,75 / 0,64 / 0,56 s |
| **24 m** | 42,7 m | **%7,7** | 83 px | %83 | 1,20 / **1,00** / 0,86 / 0,75 s |
| 32 m | 56,9 m | %5,8 | 62 px | %62 | 1,60 / 1,33 / 1,14 / 1,00 s |

**Tempo kararı:** 40 m görüşte "12 m/s yavaş" endişesi 24 m görüşte geçerli değil: 12 m/s ekranın yarısını 1 s'de geçiyor (6,5 SL/s), bu küçük gemi için canlı bir tempo. 14–16 m/s 24 m'de tepki penceresini 0,75–0,86 s'ye indiriyor (asteroid arasında seğirme riski). **Öneri: L1 12 m/s kalsın, Engine L3 14,4 m/s tavan.** 10–16 taraması ekonomiyi çok az değiştiriyor (§4.3): hız, ilerlemenin değil hissin düğmesi.

## 3. Kazma, asteroid, cevher, istasyon

| Lazer `laser_mk1` | Değer |
|---|---|
| Hasar | 14 HP/s × `mining_power`/10 (L1 14, Head L2 18,2, L3 22,4) |
| Menzil / ışın yarıçapı | 10 m / 0,18 m (24 m görüşte ekranda kalır) |
| Ateş yayı | burundan ±35° (fareye döner, dışına çıkmaz) |
| Spin-up | 0,12 s |
| Enerji / ısı | MVP'de yok |

| Asteroid (öneri) | Adet | Yarıçap | HP | Cevher | Birim | Değer | L1 kırma süresi* |
|---|---|---|---|---|---|---|---|
| `asteroid_rock_s` | 8 | 1,0 m | 30 | ore | 3 | 12 kr | 2,6 s |
| `asteroid_rock_m` | 6 | 2,5 m | 80 | ore | 6 | 24 kr | 6,8 s |
| `asteroid_ore_m` (damarlı) | 2 | 2,5 m | 90 | crystal | 4 | 48 kr | 7,7 s |
| `asteroid_rock_l` | 3 | 4,0 m | 160 | ore | 12 | 48 kr | 13,6 s |
| `asteroid_ore_l` (damarlı) | 1 | 4,0 m | 180 | crystal | 7 | 84 kr | 15,3 s |
| **Sektör toplamı** | 20 | | 1560 | | 111 u | 564 kr | |

\* %85 isabetle (yeni oyuncu).

| Cevher | Satış | Kütle |
|---|---|---|
| `ore_common_solid` | 4 kr/u | 0,03 t/u |
| `crystal_blue_solid` | 12 kr/u | 0,02 t/u |

- **Sektör:** oynanış yarıçapı 120 m, yumuşak sınır 130 m, asteroid halkası 25–100 m, 3–5'lik kümeler, kümeler arası boşluk ≥ 3 m, yeniden doğma 60 s (oyuncudan ≥ 40 m), dock yarıçapı 5 m, başlangıç kredisi 0.
- **Pickup:** mıknatıs 5 m, çekiş 40 m/s² / en fazla 18 m/s, toplama 1 m, ömür yok, en fazla 150 aktif, saçılma 1,5–3,5 m/s, kargo doluysa çekmez.
- Engineer'ın WIP `AsteroidDefinition`'ı asteroid başına **tek** cevher tutuyor; brief'teki "damarlıda yarısı kristal" bu yüzden ayrı kristal varyantıyla yapıldı (değer olarak aynı).

## 4. Tempo (sim çıktısı)

`godot --headless --path . -s res://tests/tools/run_mvp_balance_sim.gd` (25 seed, deterministik). Varsayımlar sim dosyasının başında: uzun yolda ortalama hız ×0,8, kısa sıçramada ×0,5, isabet %85, kırılma sonrası toplama 1,5 s + pickup başına 0,15 s, dock+satış 5 s, alım başına 3 s. Yükseltme sırası: önce bütün L2'ler (Head → Body → Engine → Wings), sonra L3'ler, alınabilen ilk.

### 4.1 Hedef kontrolü

| Ölçüt | min | medyan | max | Hedef |
|---|---|---|---|---|
| İlk yükseltme (Head L2) | 2:48 | **4:10** | 4:42 | 3–5 dk (~4) |
| Bütün parçalar L3 | 32:02 | **34:57** | 37:13 | ~30 dk (brief), 30–60 (görev) |

### 4.2 Medyan oyun: ilk turlar ve yükseltme zaman çizelgesi

| Tur | Başlangıç | Süre | Uçuş | Kazma+toplama | Dock | Asteroid | Birim | Kredi | Seviyeler |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 0:00 | 89 s | 34 s | 50 s | 5 s | 8 | 30 | 152 | H1 B1 W1 E1 |
| 2 | 1:29 | 80 s | 25 s | 50 s | 5 s | 5 | 30 | 152 | H1 B1 W1 E1 |
| 3 | 2:49 | 98 s | 31 s | 59 s | 8 s | 6 | 30 | 192 | H1 B1 W1 E1 |
| 4 | 4:27 | 87 s | 31 s | 48 s | 8 s | 6 | 30 | 208 | H2 B1 W1 E1 |
| 5 | 5:54 | 82 s | 31 s | 46 s | 5 s | 6 | 39 | 156 | H2 B2 W1 E1 |

| # | Parça | Seviye | Maliyet | Zaman |
|---|---|---|---|---|
| 1 | Head | L2 | 320 | **4:27** |
| 2 | Body | L2 | 360 | 5:54 |
| 3 | Engine | L2 | 340 | 8:51 |
| 4 | Wings | L2 | 360 | 11:41 |
| 5 | Head | L3 | 800 | 18:11 |
| 6 | Engine | L3 | 800 | 24:17 |
| 7 | Body | L3 | 850 | 30:12 |
| 8 | Wings | L3 | 750 | 34:57 |

Tur ≈ 80–100 s, L1'de 30 u ≈ 150–200 kr; L3 ambarla 50 u ≈ 230–250 kr.

### 4.3 Seyir hızı taraması (L1 `flying_speed` değiştirilerek, medyan)

| L1 m/s | L1 tur | İlk yükseltme | Bütün L2 | Bütün L3 |
|---|---|---|---|---|
| 10 | 89 s | 4:07 | 12:51 | 36:34 |
| **12** | 85 s | 4:10 | 12:13 | 34:57 |
| 14 | 83 s | 4:01 | 12:04 | 33:59 |
| 16 | 81 s | 3:40 | 11:35 | 33:14 |

### 4.4 Brief'in başlangıç değerlerinden neden ayrıldım

Brief değerleriyle (L2 120 kr, L3 300 kr, Head 10/12/14) sim: **ilk yükseltme 1:28, bütün L3 14:00** — iki hedef de tutmuyor. Brief'teki "ilk tur 3–4 dk" varsayımı 120 m'lik sektörde gerçekleşmiyor: bir tur ~1,5 dk, 30 u dolu ambar ~150 kr (sektörde yalnız 3 damarlı asteroid var, kristal payı ~%10, brief ~%33 varsaymış).

| Değişiklik | Brief | Bu branch | Neden |
|---|---|---|---|
| L2 maliyeti | 120 | 320–360 | İlk yükseltme 1:28 → 4:10 |
| L3 maliyeti | 300 | 750–850 | Bütün L3 14 → 35 dk |
| Head `mining_power` | 10/12/14 | 10/13/16 | İlk yükseltme hissedilsin (+%30, görev şartı) |
| Asteroid HP, cevher fiyatı, kargo, Engine, Wings | brief | **aynı** | Kırma süreleri (S 2,6 s, M 6,8 s) iyi hissediyor; ekonomiyi maliyetle ayarlamak his statlarını bozmuyor |

## 5. Hangi semptomda hangi düğme

| Semptom | Önce | Sonra |
|---|---|---|
| İlk yükseltme geç (> 5 dk) | Head L2 maliyeti ↓ (320 → 260) | cevher fiyatı ↑, `ore_units` ↑ |
| İlk yükseltme erken (< 3 dk) | Head L2 maliyeti ↑ | — |
| L3'e çıkmak sıkıcı / uzun | L3 maliyetleri ↓ | kristal varyant sayısı ↑ (2+1 → 3+2) |
| Kazmak yavaş / sıkıcı | `node_damage_per_s` 14 ↑ | asteroid `max_hp` ↓ |
| Asteroid "pop" etmiyor, anında kırılıyor | S `max_hp` 30 ↑ | `spin_up` ↑ |
| Tur çok uzun | `ring_min/max_radius` ↓ | Body `carry_capacity` ↓ |
| Sektör tükeniyor, bekleme var | `respawn_delay` 60 ↓ | asteroid sayısı ↑ |
| Toplama sinir bozucu | `magnet_radius` 5 ↑, `pull_max_speed` ↑ | — |
| Uçuş "buz gibi" | `coast_damp` ↑ | `lateral_grip` ↑ |
| Uçuş hızlı / seğirmeli | varsayılan zoom 24 → 32 | `flying_speed` ↓ |
| Gemi küçük görünüyor | zoom 24 → 18 | — |
| Boost hissiz | `boost_speed_mult` ↑ | `boost_zoom_out` ↑ |
| Kazarken hedef ekran dışında | `beam_range` ↓ veya zoom ↑ | `aim_offset_max` ↑ |

## 6. Açık sorular

**PS Game Designer:**
1. Maliyetler brief'in ~2,7 katı (§4.4). Kabul mü, yoksa sektörü/turu uzatmayı mı tercih edersin (ör. halka 40–110 m)?
2. Brief'te Head 10/12/14; ben 10/13/16 yaptım (ilk yükseltme hissedilsin). Uygun mu?
3. Damarlı asteroid tek cevher: kristal-only varyant mı (benim öneri), yoksa iki cevherli drop mu (şema değişikliği)?
4. Kontrat §2 "L2 yalnız katı kaynak" D-011 ile askıda; `ship_data_model.md`'ye MVP notu düşülmeli.

**PS Godot Engineer:**
1. `scripts/mining/mining_laser.gd` brief'e göre Gameplay'in; senin WIP'inle **aynı API** (`setup`, `set_stats`, `mine`, `beam_origin/end`, `hit_asteroid`, `firing_changed`) ile yazdım. Asteroid'e `Asteroid` tipi yerine `apply_mining_damage()` üzerinden duck typing ile bağlanıyor; böylece senin `asteroid.gd`'n gelmeden derleniyor. Merge'de seninkini düşür ya da farkları söyle.
2. `scripts/data/mining_laser_definition.gd` senin WIP dosyanın **birebir kopyası** (lazer `.tres`'i için). Commit'lediğinde benimkini sil.
3. `player_ship.tscn`'de `ShipAssembler` brief'e göre `Visual/ShipAssembler` altında; `MvpGame` şu an `$Ship/ShipAssembler` bekliyor. Gemi `hull_definition` verilirse assembler'ı kendisi kurar; `MvpGame` kuruyorsa boş bırak.
4. EventBus: brief `mining_beam_started(origin: Node3D, target: Node3D)` diyor, commit'li kod `(origin: Vector3, target: Vector3)`. Kodu esas aldım; brief düzeltilmeli.
5. `dock_panel_toggled(open)` gelince gemi girdiyi kesip frenliyor (`input_locked`), lazer de susuyor.
6. Şema: `authored_up_to_level` (hull + parça, MVP = 3) henüz sınıflarda yok; validator MVP modu (D-011) yok. `ShipStatsResolver` LOWER_IS_BETTER (mass, fuel_rate) uygulamıyor; o yüzden bu statlara cap koymadım.
7. `tests/tools/lint_strict.sh` `--check-only -s` ile çalıştığı için autoload'ları (EventBus) tanımıyor: EventBus kullanan her script "Identifier not found" verir (seninki de verecek). Önerim: lint'i autoload'lar yüklendikten sonra script'leri `load()` eden bir runner ile yapmak. Bunun dışında yeni script'lerimde strict uyarı yok.
8. İki M1 testini MVP verisine uydurdum (ayrı commit): `test_empty_l2_l3_do_not_change_base` artık sentetik hull kullanıyor, `test_full_content_mode_flags_missing_l2_l3` L2/L3'ü kendisi boşaltıyor; yeni test: starter tam içerik (L1–L3, modeller) validator'dan geçiyor.
