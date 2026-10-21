# MVP Denge Sayıları ve His (Gameplay Designer)

**Sahip:** Gameplay Designer · **Durum:** v0.3, 2026-10-22 (gerçek sahnede ölçüldü, sim kalibre edildi, maliyetler ince ayar) · **Bütün sayılar `balance_prototype`** (GAME_PLAN §15.3).
**Girdi:** [`mvp.md`](mvp.md) v1.0 (başlangıç değerleri), D-006, D-009 (gemi 1,84 m), D-011 (yalnız kredi).
**Branch:** `gameplay/mvp-loop` (taban `eng/mvp-integration` @ `3aff395`).
**PS Game Designer onayı:** ilk yükseltme ~4:10, L2 320–360 kr, ilk alım Head L2, seyir 12 m/s, Engine L3 14,4 m/s. v0.2 isteği: ilk L3 ≤ 10:00 (medyan), tam L3 ~20–25 dk.

Döngü: uç → asteroidi ışınla kaz → kırılır, cevher saçılır → mıknatısla topla → istasyonda sat → parçayı L1→L2→L3 yükselt.

## 0. Nerede ne var

| Ne | Dosya | Durum |
|---|---|---|
| Hull + 4 parça, L1–L3 statları ve maliyetleri | `data/ships/starter_shuttle_01.tres`, `data/parts/*_starter_shuttle_01.tres` | **.tres, bu branch'te** |
| Uçuş + kamera hissi | `data/ships/starter_flight_tuning.tres` (`FlightTuning`) | **.tres** |
| Kazma lazeri | `data/modules/laser_mk1.tres` (`MiningLaserDefinition`) | **.tres** |
| Asteroid S/M/L, cevher fiyatı, sektör, pickup | `data/asteroids/*.tres`, `data/resources/*.tres`, `data/sectors/mvp_sector_01.tres`, `data/loot/pickup_tuning.tres` | **.tres, kaynak bunlar** (Engineer JSON'dan üretti, sayılar Gameplay'de). `data/balance/mvp_economy_proposal.json` yalnız test stub'ı için, değerleri aynı |
| Denge simülasyonu | `tests/tools/mvp_balance_sim.gd` + `run_mvp_balance_sim.gd` | Oyunun okuduğu `.tres`'leri okur (sektör, asteroid, cevher, gemi, lazer) |
| Gerçek sahne ölçümü | `tests/tools/real_loop_bot.gd` + `run_real_loop_measure.gd` | `mvp_sector.tscn`'i headless autopilotla oynar (§4.0) |
| Uçuş/kamera ölçümü | `tests/tools/flight_metrics.gd` + `run_flight_metrics.gd` | |

## 1. Gemi parçaları (starter_shuttle_01, native grade E)

Değerler **mutlak** (hull base + o seviyenin modifier'ı). L3 = `upgrade_caps` (grade içi tavan). Kütle her seviyede sabit.

| Parça | Stat | L1 | L2 | L3 (=cap) | L2 maliyeti | L3 maliyeti |
|---|---|---|---|---|---|---|
| **Head** | `mining_power` (10 = ×1,0) | 10 | **13 (+%30)** | 16 (+%60) | **320 kr** | **330 kr** |
| Head | `damage` (MVP'de okunmaz) | 10 | 12 | 14 | | |
| **Body** | `carry_capacity` = `storage_solid` (u) | 30 | 40 (+%33) | 50 | **340 kr** | **400 kr** |
| Body | `hull` (MVP'de okunmaz) | 100 | 130 | 160 | | |
| **Wings** | `maneuver_speed` (°/s) | 270 | 300 | 330 | 360 kr | 380 kr |
| **Engine** | `flying_speed` (m/s) | 12,0 | 13,2 | 14,4 | 340 kr | **380 kr** |
| Toplam | | | | | **1360 kr** | **1490 kr** → **2850 kr** (v0.2: 2940, v0.1: 4580) |

- Kütle: frame 0,5 + Head 0,4 + Body 1,6 + Wings 0,5 + Engine 0,7 = **3,7 t**; lazer 0,2 t → `reference_mass` 3,9 t. Cevher 0,03 t/u (kristal 0,02): dolu L3 ambar ≈ +1,5 t → ivme ≈ ×0,8.
- Hull base'te MVP'de okunmayan alanlar duruyor (`fuel_*`, `energy_capacity` 50, `heat_capacity` 100, `radar_range` 80 …; validator kural 7 fuel ister).
- **Head L2 bilerek en ucuz L2:** ilk alınan yükseltme hissedilen olsun (lazer 14 → 18,2 HP/s; M asteroid 6,7 s → 5,2 s).
- **Head L3 (330 kr) bilerek en ucuz L3:** "ekonomi önce" oyuncusu Head L2 → Body L2 → Head L3 sırasıyla ilk L3'ü ~9:50'de alır. L3 maliyeti her parçada L2'den yüksek kalır (Head 320 → 330).
- v0.3: gerçek sahnede toplama (pickup kovalama) simin varsaydığından uzun çıktı (§4.0); oyuncu tempo hedefleri için Body L2 360 → 340, Head L3 360 → 330, Body L3 420 → 400, Engine L3 400 → 380.
- **Debug: F9 = +500 kr** (`debug_add_credits` aksiyonu, `scripts/debug/debug_cheats.gd`, `player_ship.tscn` altında `DebugCheats`). `GameState.add_credits(500)` çağırır; yalnız `OS.is_debug_build()` true iken çalışır, release export'ta düğüm kendini siler. Tempo ölçümlerine dahil değil.

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
| Motor izi (VFX) | `Visual/EngineTrail` (`scenes/vfx/engine_trail.tscn`), her physics frame `set_thrust(yatay hız / flying_speed, boosting)` | 0..1'e kırpılır; boost görünümü ayrı bayrak |
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

## 4. Tempo (gerçek sahne + kalibre sim)

### 4.0 Gerçek sahne ölçümü (eng/mvp-integration @ `3aff395`)

`godot --headless --fixed-fps 60 --path . -s res://tests/tools/run_real_loop_measure.gd -- --seed=N --runs=40 --max-time=2400`. Autopilot gerçek `mvp_sector.tscn`'i oynar: gerçek `MiningLaser`, `Asteroid` (HP, drop), `PickupPool` mıknatısı, `StationDock`, `GameState` satış ve yükseltme. Politika: en yakın asteroid, drop'unu topla, < 2 u yer kalınca dön, sat, plandaki sıradaki parçayı al. Seed 0/11/22/33/44; 14 L1 turu.

| Girdi | Gerçek oyun | Sim | Not |
|---|---|---|---|
| Kargo kapasitesi | 30 / 40 / 50 u | aynı | `GameState.get_cargo_capacity()` |
| Asteroid başına cevher (S / M / M-kristal / L / L-kristal) | 3 / 6 / 4 / 12 / 7 u | aynı | Tur başına saçılan 26–40 u, ortalama 2,0 S + 2,9 M + 0,9 L kırılıyor |
| Pickup kaybı | **0**: ömür yok (`lifetime 0`), kargo dolunca kalanlar sahada bekliyor (tur başına medyan 3,5 u, sonraki turda toplanıyor) | yok | Mıknatıs 5 m, toplama 1 m |
| Satış fiyatı | ore 4, kristal 12 kr (`sell_all_cargo`): 30 ore = 120, 26+4 = 152 | aynı | |
| Lazer dps | 14,0 / 18,2 / 22,4 | aynı | |
| Asteroid sayısı / HP / respawn | 8/6/2/3/1, 30–180 HP, 60 s | aynı | Sim artık sektör `.tres`'ini okur |

| L1 turu (medyan) | Süre | Uçuş | Kazma | Toplama | Dock+satış | Kredi | İlk yükseltme | İlk L3 | Tam L3 |
|---|---|---|---|---|---|---|---|---|---|
| **Gerçek sahne (bot)** | 77 s | 22 s | 32 s | 16 s | 5 s | **152** | **3:40** | **9:33** | **22:33** |
| Sim "bot" profili | 77 s | 25 s | 34 s | 15 s | 5 s | 152 | 3:35 | 8:34 | 20:49 |
| Sim "human" profili (tempo) | 89 s | 31 s | 41 s | 17 s | 5 s | 152 | 4:06 | 9:51 | 23:32 |

Tam L3 sütunları v0.3 maliyetleriyle. v0.2 maliyetleriyle gerçek bot 3:40 / 9:33 / 22:10, sim bot 3:35 / 8:59 / 21:28 verdi.

**"Tur başına ~48 kr" nereden çıktı:** Engineer'ın video demosu (`tests/tools/demo_autoplay.gd`) gerçek bir tur oynamıyor. 3 asteroid kazıyor (L'leri ve istasyondan 70 m ötesini atlıyor), 8 s topluyor ve 12/30 u ile dönüyor: 12 × 4 = 48 kr. Headless çalıştırınca tam bu çıkıyor ("cargo 12/30"). Sonra Head L2/L3 için F9 kullanıyor. Oyun ekonomisi doğru: dolu L1 ambar 120–208 kr (medyan 152). Engineer'ın kendi smoke testi de aynı sonucu veriyor (tur 1: 120, tur 2: 152).

**Sim kalibrasyonu:** Simde iki profil var (`set_profile`):
- **bot:** gerçek ölçüme oturtuldu (tam isabet, sabit yol hızı ×1,0, toplama 1,6 s + pickup başına 0,25 s). `run_mvp_balance_sim.gd` ve `test_sim_bot_profile_matches_real_scene` bu profil ölçümden %20'den fazla saparsa FAIL verir. Ölçüm değerleri `MvpBalanceSim.MEASURED_REAL`'da.
- **human:** botun üstüne yeni oyuncu kayıpları (isabet %85, yol ×0,8, toplama 1,8 s + 0,25 s). Tempo hedefleri bununla kontrol ediliyor.

Eski sim (v0.2) toplamayı 1,5 s + 0,15 s ile, yani gerçeğin ~%30 altında modelliyordu.

**Referans alım planı ("ekonomi önce"):** Head L2 → Body L2 → **Head L3** → Engine L2 → Wings L2 → Body L3 → Engine L3 → Wings L3. Oyuncu sıradaki adım için para biriktirir, yetince alır.

### 4.1 Hedef kontrolü (sim human, 25 seed)

| Ölçüt | min | medyan | max | Hedef |
|---|---|---|---|---|
| İlk yükseltme (Head L2) | 2:55 | **4:06** | 4:54 | 3–5 dk (~4) |
| İlk L3 (Head) | 9:03 | **9:51** | 10:52 | medyan ≤ 10:00, max ≤ 11:00 |
| Bütün parçalar L3 | 22:42 | **23:32** | 25:09 | 20–25 dk |

Gerçek bot (mükemmel oyuncu, 5 seed): ilk yükseltme 2:43–3:46 (medyan 3:40), ilk L3 7:48–10:25 (9:33), tam L3 21:16–23:16 (22:33). İnsan oyuncu bunlardan biraz yavaş, sim human onu temsil ediyor.

Test eşikleri (`run_mvp_balance_sim.gd`, `test_mvp_balance_data.gd`): ilk yükseltme medyanı 180–300 s, ilk L3 medyanı ≤ 600 s (en yavaş seed > 660 s ise uyarı), tam L3 medyanı 1200–1500 s. Sim bot ölçümden ±%20 içinde olmalı.

### 4.2 Medyan oyun (sim human; tam L3'e göre medyan seed)

| Tur | Başlangıç | Süre | Uçuş | Kazma+toplama | Dock | Asteroid | Birim | Kredi | Seviyeler |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 0:00 | 93 s | 31 s | 58 s | 5 s | 6 | 30 | 168 | H1 B1 W1 E1 |
| 2 | 1:33 | 99 s | 33 s | 61 s | 5 s | 7 | 30 | 120 | H1 B1 W1 E1 |
| 3 | 3:12 | 98 s | 32 s | 58 s | 8 s | 7 | 30 | 176 | H1 B1 W1 E1 |
| 4 | 4:50 | 94 s | 33 s | 53 s | 8 s | 7 | 30 | 208 | H2 B1 W1 E1 |
| 5 | 6:24 | 110 s | 37 s | 68 s | 5 s | 9 | 40 | 216 | H2 B2 W1 E1 |
| 6 | 8:15 | 97 s | 33 s | 55 s | 8 s | 7 | 40 | 192 | H2 B2 W1 E1 |
| 7 | 9:51 | 98 s | 36 s | 57 s | 5 s | 8 | 40 | 248 | H3 B2 W1 E1 |

| # | Parça | Seviye | Maliyet | Zaman |
|---|---|---|---|---|
| 1 | Head | L2 | 320 | 4:50 |
| 2 | Body | L2 | 340 | 6:24 |
| 3 | Head | L3 | 330 | **9:51** |
| 4 | Engine | L2 | 340 | 13:08 |
| 5 | Wings | L2 | 360 | 14:56 |
| 6 | Body | L3 | 400 | 18:01 |
| 7 | Engine | L3 | 380 | 20:08 |
| 8 | Wings | L3 | 380 | **23:32** |

Bu seed ilk yükseltmede medyanın arkasında (4:50); 25 seed medyanı 4:06.

### 4.3 Seyir hızı taraması (sim human, L1 `flying_speed` değiştirilerek, medyan)

| L1 m/s | L1 tur | İlk yükseltme | İlk L3 | Bütün L2 | Bütün L3 |
|---|---|---|---|---|---|
| 10 | 94 s | 4:11 | 10:32 | 15:48 | 25:01 |
| **12** | 89 s | 4:06 | 9:51 | 15:03 | 23:32 |
| 14 | 86 s | 4:13 | 9:28 | 14:54 | 23:09 |
| 16 | 84 s | 4:06 | 8:52 | 14:26 | 22:26 |

### 4.4 Brief'in başlangıç değerlerinden ve v0.1'den neden ayrıldım

| Sürüm | L2 | L3 | İlk yükseltme | İlk L3 | Tam L3 |
|---|---|---|---|---|---|
| Brief başlangıcı | 120 | 300 | 1:28 | — | 14:00 |
| v0.1 | 320–360 | 750–850 | 4:10 | ~18 | 34:57 |
| v0.2 | 320–360 | 360–420 | 4:10 | 9:47 | 22:57 |
| **v0.3 (şimdi, kalibre sim human)** | 320–360 | **330–400** | **4:06** | **9:51** | **23:32** |

- Brief maliyetleriyle döngü çok hızlı: 120 m'lik sektörde bir tur ~1,5 dk, 30 u dolu ambar ~150 kr (sektörde 3 damarlı asteroid, kristal payı ~%10; brief ~%33 varsaymıştı).
- v0.1 ilk yükseltmeyi tutturdu ama L3'ler uzun bir öğütmeye dönüşüyordu (Game Designer: ilk L3 ≤ 10 dk, tam L3 20–25 dk).
- v0.2: L2'ler ve ilk yükseltme aynı; L3'ler L2'nin hemen üstünde. Head L3 en ucuz, ki ilk L3 hissedilen parça olsun (lazer 18,2 → 22,4 HP/s).
- Asteroid HP, cevher fiyatı, kargo, Engine, Wings brief'teki gibi. Head 10/13/16 (brief 10/12/14), ilk yükseltme hissedilsin diye.

## 5. Hangi semptomda hangi düğme

| Semptom | Önce | Sonra |
|---|---|---|
| İlk yükseltme geç (> 5 dk) | Head L2 maliyeti ↓ (320 → 260) | cevher fiyatı ↑, `ore_units` ↑ |
| İlk L3 geç (> 10 dk) | Body L2'yi plandan sonraya at (Head L2 → Head L3 ~7 dk) | Head L3 ↓ (alt sınır: Head L2 + 1) |
| İlk yükseltme erken (< 3 dk) | Head L2 maliyeti ↑ | — |
| L3'e çıkmak sıkıcı / uzun | L3 maliyetleri ↓ | kristal varyant sayısı ↑ (2+1 → 3+2) |
| Demo/test için para lazım | F9 (+500 kr, yalnız debug build) | — |
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

## 6. Açık sorular ve entegrasyon notları

**v0.3 ölçüm notları (Engineer):** Gerçek ekonomi simle uyumlu, oyun kodunda değişiklik gerekmiyor. Yalnız `tests/tools/demo_autoplay.gd` demosu tek seferlik kısa bir tur oynuyor (3 asteroid, 12 u, 48 kr). Videoda "tam tur" gösterilecekse demo L'leri de kazıp kargo dolana kadar devam etmeli; mevcut F9 akışı demo için yeterli.

**Kararlaştırılanlar (PS Godot Engineer, 2026-10-22):** `scripts/mining/mining_laser.gd` Gameplay'de kalır; `ShipAssembler` `Visual/ShipAssembler` altında kalır, `MvpGame` uyarlanır; `MiningLaserDefinition` Engineer'ın (kopyamız branch'ten çıkarıldı).

**EventBus imzaları (kod esas, `scripts/core/event_bus.gd` @ `20d6e66`):**
- `mining_beam_started(origin: Node3D, target: Node3D)`: origin = `FX_MiningOrigin` düğümü, target = asteroid (isabet yoksa `null`). Işın yeni bir asteroide kilitlendiğinde tekrar yayılır. **Not:** `mvp.md` (`30dc05d`) bu sinyali `Vector3, Vector3` diye düzeltti ama commit'li kod `Node3D, Node3D`. VFX director her ikisini kabul ediyor (`Variant`). `mvp.md` koda göre geri düzeltilmeli.
- `mining_beam_updated(origin: Node3D, end: Vector3)`: Engineer'ın WIP'inde, henüz commit'li değil. Lazer sinyal varsa her physics frame yayar (`has_signal` korumalı); test sinyal gelene kadar pending.
- `asteroid_destroyed(position: Vector3, radius: float)`: Engineer güncelledi; lazer ve test stub'ı uyumlu.
- `station_panel_toggled(is_open)` gelince gemi girdiyi kesip frenliyor, lazer susuyor. `ship_stats_changed(stats)` gemiye uygulanıyor.

**PS Game Designer:**
1. Damarlı asteroid tek cevher: kristal-only varyant mı (benim öneri), yoksa iki cevherli drop mu (şema değişikliği)?
2. Referans alım planı Head L2 → Body L2 → Head L3. Oyuncu tüm L2'leri önce alırsa ilk L3 ~15 dk'ya kayar; istasyon paneli Head L3'ü öne çıkarabilir (UI notu).

**PS Godot Engineer:**
1. `mining_beam_updated`'ı commit'leyince WIP'teki `mining_laser.gd` satırını düşür: emit bu branch'te zaten var (aynı argümanlar).
2. Ekonomi önerisi (`data/balance/mvp_economy_proposal.json`) ile `data/` altındaki asteroid/cevher `.tres`'leri aynı değerlerde tutulmalı (sim JSON'u okur).
3. `MvpGame` gemiyi `player_ship.tscn`'den kurarken `EngineTrail` ve `DebugCheats` sahnede hazır; ayrıca eklemeye gerek yok.
4. `project.godot`'a `debug_add_credits` (F9) aksiyonu eklendi.
