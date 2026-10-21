# Brief — MVP (oynanabilir ilk döngü)

**Sahip:** Game Designer (lead) · **Durum:** v1.0, 2026-10-22 · **Karar kaydı:** [DECISIONS.md](../DECISIONS.md) D-004, D-006 … D-012
**Öncelik:** MVP, M1'den önce gelir. Bu belge ile M1 belgeleri çelişirse MVP süresince bu belge geçerlidir.
**Bütün sayılar `balance_prototype`'tır** (GAME_PLAN §15.3). Ayar değiştirmek için belge değiştirmek gerekmez, `data/` yeter.

## 1. Hedef

Küçük ama **baştan sona oynanabilir** tek bir döngü:

```text
uç → asteroide yaklaş → kazma ışınıyla kaz → asteroid kırılır, cevher düşer
   → cevheri topla → istasyona dön, sat → kredilerle bir parçayı L1 → L2 → L3 yükselt
```

- Yükseltme parçanın **modelini ekranda değiştirir** (`ShipAssembler` ile model swap) ve **küçük bir stat artışı** verir.
- Hedef süre: ilk yükseltme **3–5 dk** içinde. Bütün parçaları L3'e çıkarmak yaklaşık 30 dk.
- Starter gemi hazır: `assets/models/ships/starter_shuttle_01/` (PR #1, 12 GLB, L1–L3, Asrın onayladı). **Tasarımı değişmez.**

## 2. Kapsam dışı

Düşman ve çatışma (D-004: M1'e ertelendi) · Bomb · Drill · yakıt (tüketim, dolum, limp modu) · ısı ve enerji · gövde hasarı, ölüm ve respawn · kayıt sistemi · birden fazla sektör ya da gemi · salvage · envanter ızgarası · minimap · aktif slot barı · asteroid node katmanları (surface/vein/core) · sıvı ve gaz kargo · ses tasarımı (placeholder ses serbest) · ana menü.

Veri modelinde var olan alanlar (`fuel_*`, `heat_*`, `hull`, `storage_gas` vb.) silinmez. MVP'de sadece okunmazlar.

## 3. Sahne ve oynanış

**Sahne:** `res://scenes/main/mvp_sector.tscn`. Tek sektör, merkezde bir istasyon, çevresinde 20 asteroid (S/M/L), uzay arka planı.

| Öğe | Değer (başlangıç, `balance_prototype`) |
|---|---|
| Oynanabilir alan | İstasyon merkezde, yarıçap 120 m. 130 m'de yumuşak sınır, gemiyi içeri iter |
| Asteroid sayısı | 20: 8 S, 8 M, 4 L. M ve L'lerden 3'ü cevher damarlı varyant (`asteroid_ore_*`) |
| Asteroid yerleşimi | İstasyondan 25–100 m uzakta, 3–5'lik kümeler, sabit seed |
| Yeniden doğma | Kırılan asteroid 60 s sonra, oyuncudan en az 40 m uzakta yeniden doğar (döngü tükenmesin) |
| Ölçek | Gemi 1,84 m (D-009). Asteroid yarıçapı S 0,9–1,2 m, M 2,2–2,8 m, L 3,5–4,5 m. İstasyon 12–16 m çapında, dock alanı yarıçapı yaklaşık 5 m |

**Kontroller ve kamera:** Gameplay Designer'ın `m1_flight_tuning.md` belgesindeki gibi (Şema A).

| Girdi | Action | Davranış |
|---|---|---|
| W/S | `move_forward` / `move_back` | Burun yönünde itki / geri itki |
| A/D | `move_left` / `move_right` | Yanal itki |
| Fare | — | Burun imleci takip eder (dönüş hızı `maneuver_speed` ile sınırlı) |
| Sol tık | `fire_primary` | Kazma ışını (basılı tutulur) |
| Shift | `boost` | Kısa boost. MVP'de yakıt harcamaz, yalnızca süre ve cooldown sınırı var |
| Space | `brake` | Fren (W basılıyken drift) |
| E | `interact` | Dock alanındayken istasyon panelini açar ve kapatır |
| Tekerlek | `zoom_in` / `zoom_out` | Zoom kademeleri |

- Kamera ortografik, dikeyden 10° eğik. `m1_flight_tuning.md`'deki SL değerleri 3 m'lik gemiye göre hesaplandı, Gameplay Designer bunları 1,84 m'ye göre yeniden ölçekler. Başlangıç önerisi: `ortho_sizes` = [18, 24, 32] m, varsayılan 24 m.
- Bütün action'lar `project.godot`'ta zaten var. Yeni action gerekmiyor.

**Kazma:** Sol tıkla burundaki `FX_MiningOrigin`'den imlece doğru ışın çıkar. Menzil yaklaşık 10 m (başlangıç değeri). Asteroidin tek bir HP havuzu vardır. HP sıfırlanınca asteroid kırılır, yerinde cevher pickup'ları saçılır. Işın kargoya doğrudan bir şey aktarmaz.

**Toplama:** Pickup'lar pasif mıknatısla çekilir (yaklaşık 5 m yarıçap) ve temas edince kargoya girer. Kargo doluysa pickup çekilmez, yerinde kalır, HUD "Kargo dolu" gösterir. Kayıp ya da duplikasyon olmaz. MVP'de pickup'ın ömrü yoktur, havuzda en fazla 150 aktif pickup bulunur.

**Cevher türleri:** `ore_common_solid` (sıradan asteroidler) ve `crystal_blue_solid` (damarlı varyantlar, daha değerli). İkisi de katıdır, 1 u hacim kaplar.

**İstasyon:** Dock alanına girince "E: İstasyon" ipucu görünür. Panel açıkken gemi girdisi durur ve gemi yavaşça durur. Panelde iki iş yapılır:
1. **Sat:** "Hepsini sat" düğmesi bütün kargoyu krediye çevirir.
2. **Yükselt:** Head, Body, Wings, Engine için birer satır bulunur. Her satırda şu anki seviye (L1–L3), bir sonraki seviyenin maliyeti, stat önizlemesi (şimdiki → sonraki) ve "Yükselt" düğmesi var. L3'te düğme kapalıdır. Kredi yetmezse düğme kapalıdır ve eksik tutar yazar.

**Ekonomi (başlangıç değerleri, Gameplay Designer ayarlar):**

| | Değer |
|---|---|
| Kargo (`carry_capacity` / `storage_solid`) | L1 30 u, L2 40 u, L3 50 u (Body) |
| Asteroid HP | S 30, M 80, L 160 (Laser 14 HP/s, `mining_power` 10 = ×1.0) |
| Düşen cevher | S 2–3, M 5–7, L 10–14 birim. Damarlı varyantlarda yaklaşık yarısı kristal |
| Satış değeri | `ore_common_solid` 4 kr/u, `crystal_blue_solid` 12 kr/u |
| Yükseltme maliyeti (parça başına) | L2 yaklaşık 320–360 kr; L3 değeri ilk L3 ≤ 10 dk'da gelecek şekilde ayarlanır. Kesin değerler `docs/briefs/mvp_balance.md`'de. **Yalnızca kredi** (D-011). Debug build'de F9 ile +500 kr (demo/test için) |
| Stat artışı | `m1_flight_tuning.md` §3 tablosu (Head `mining_power` 10/12/14, Engine `flying_speed` 12/13,2/14,4, Wings `maneuver_speed` 270/300/330, Body kargo 30/40/50) |

Kontrol hesabı: dolu kargo yaklaşık 20 cevher ve 10 kristaldir, bu da yaklaşık 200 kr eder. İlk tur 3–4 dk sürer ve ilk L2 yükseltmesine yeter.

## 4. Kesin kararlar (MVP)

| Konu | Karar |
|---|---|
| Gemi boyu | **1,84 m** (L1, burun → nozul). Asrın'ın onayladığı model bu. Brief'lerdeki "~3 m" geçersiz. Asteroid, istasyon, kamera ve menzil ölçeği buna göre (D-009) |
| Parça seti | Her geminin sabit Head/Body/Wings/Engine seti var, başka gemiden parça takılmaz. Her parçanın L1–L3 seviyesi var (D-006) |
| MVP içeriği | `ShipHullDefinition` ve 4 parçada `authored_up_to_level = 3` (12 GLB hazır) |
| Node isimleri | Body GLB'sinde `Socket_Head`, `Socket_Wings`, `Socket_Engine`. Hardpoint'ler `Hardpoint_L`, `Hardpoint_R` (`Hardpoint_Nose` opsiyonel, `Hardpoint_Top` rezerve). Engine'de `FX_EngineTrail_<n>` (n 0'dan başlar), Head'de `FX_MiningOrigin`. Blender objeleri `Head_<hull_id>` vb. (D-008) |
| Id ve dosyalar | Parça id'si `<part>_<hull_id>` (örn. `head_starter_shuttle_01`). Model `assets/models/ships/<hull_id>/<part>_L<n>.glb`, veri `data/parts/<part_id>.tres`, `data/ships/<hull_id>.tres`. Grade eki (`_e`, `_d`) yok |
| EventBus | Tek global sinyal hub'ı: autoload adı `EventBus`, dosyası `res://scripts/core/event_bus.gd`. AGENTS.md §2'ye göre autoload'lar `scripts/core/` altında duruyor, mevcut kod da burada. Engineering brief'teki `Events` adı geçersiz (D-012) |
| Oturum durumu | Autoload `GameState` (`res://scripts/core/game_state.gd`). Kredi, kargo ve `ShipInstanceState` burada tutulur. Satış ve yükseltme API'si de burada |
| Yükseltme | İstasyonda yapılır, yalnızca kredi ile, tek seferde +1 seviye, seviye düşürme yok (D-011) |
| Motor | Godot 4.7.x (D-007). Box'ta kurulu sürüm 4.7.2 |

## 5. Roller, yollar ve branch'ler

**Taban branch:** `eng/mvp-integration`. Veri modeli, `ShipAssembler`, EventBus ve starter gemi içinde. Herkes kendi branch'ine bunu merge eder ya da rebase yapar. AGENTS.md §2'deki sahiplik geçerli. Aşağıdaki **MVP istisnaları** dışında kimse başkasının yoluna yazmaz.

| Rol | Teslimler | Yollar | Branch · worktree |
|---|---|---|---|
| **Godot Engineer** (entegrasyon sahibi) | `mvp_sector.tscn` kompozisyonu: istasyon, asteroid yerleşimi ve yeniden doğma, sınır, kamera, HUD ve VFX instance'ları. EventBus'a MVP sinyalleri. `GameState`: kargo, kredi, satış, yükseltme uygulama, stat yeniden hesaplama. `ShipAssembler` model swap (`part_upgraded` gelince ilgili parçayı yeniden kurar). Asteroid sahne çerçevesi (HP, kırılma, pickup saçma). Pickup sistemi (mıknatıs, havuz, kargoya teslim). İstasyon dock alanı. Veri şeması sınıfları (`ResourceDefinition` satış değeri, `AsteroidDefinition`). Validator'ın MVP modu (D-011). Testler | `project.godot`, `scripts/core/**`, `scripts/data/**`, `scenes/main/**`, `tests/**`. **MVP istisnası:** `scenes/world/asteroid.tscn` + `scripts/mining/asteroid.gd`, `scenes/pickups/ore_pickup.tscn` + `scripts/loot/ore_pickup.gd`, `scenes/world/station.tscn` + `scripts/core/station_dock.gd` | `eng/mvp-integration` · `/workspace/project-space-mvp` |
| **Gameplay Designer** | `player_ship.tscn` (`CharacterBody3D`, `Visual` altında `ShipAssembler`), uçuş, kamera, kazma ışınının oynanış mantığı (hedef seçimi, menzil, hasar tick'i, ışın sinyalleri). Döngü sayıları ve `.tres` verisi: asteroid HP'si ve düşen cevher, cevher değeri, kargo kapasitesi, L2/L3 maliyetleri ve statları, döngü süresi hedefi (ilk yükseltme 3–5 dk) | `scripts/ship/**`, `scripts/mining/**` (asteroid.gd hariç), `scenes/ship/**`, `scenes/world/game_camera.tscn`, `data/**`. `data/ships/` ve `data/parts/` dosyalarını Engineer oluşturdu. Bundan sonra yalnızca Gameplay Designer düzenler | `gameplay/flight-feel` · `/workspace/project-space` |
| **3D Modeler** | Asteroidler (S/M/L, her boyutta 3 varyant, cevherli varyantlar, kırılma parçaları; batch 1 hazır). Cevher pickup modelleri (`ore_pickup_01`, `crystal_pickup_01`, ≤ 200 tri, top-down okunaklı). İstasyon (`station_01`): dock alanı üstten bakınca okunaklı olmalı. Dock merkezine `Dock_Center` empty'si konur | `assets/models/**`, `art/**` | `art/mvp-env-assets` · `/workspace/project-space-wt-mvp-art` |
| **VFX Engineer** | Motor izi (`FX_EngineTrail_<n>`'e takılır, boost'ta yoğunlaşır), kazma ışını (scroll eden çekirdek, glow, temas noktasında ısıma ve kıvılcım), asteroid kırılma efekti (boyuta göre ölçeklenir), cevher pickup parlaması ve toplanma "pop"u, uzay arka planı (yıldız alanı ve nebula), `environment_space.tres` + post-process | `assets/shaders/**`, `assets/materials/**`, `assets/vfx/**`, `scenes/vfx/**`, `scripts/vfx/**` | `vfx/mvp-effects` · `/workspace/wt-vfx` |
| **UI Designer** | HUD: kredi, kargo doluluğu (çubuk + `used/capacity`), etkileşim ipucu, "Kargo dolu" toast'u. İstasyon paneli: satış ve parça başına L1–L3 yükseltme, maliyet ve seviye önizlemesi. Theme ve font | `assets/ui/**`, `assets/fonts/**`, `scenes/ui/**`, `scripts/ui/**` | `ui/mvp-hud` · `/workspace/wt/ui-mvp` |

**Sahneler arası arayüz (sinyal dışında):**
- `GameState.sell_all_cargo() -> int` (kazanılan kredi), `GameState.get_upgrade_cost(part: StringName) -> int` (L3'teyse −1), `GameState.try_upgrade(part: StringName) -> bool`, `GameState.get_part_level(part: StringName) -> int`, `GameState.get_stats() -> Dictionary[StringName, float]`, `GameState.preview_stats(part: StringName) -> Dictionary[StringName, float]` (bir üst seviyede çözülmüş statlar). UI yalnızca bu metotları çağırır, kendi oyun mantığı tutmaz.
- VFX sahneleri: `scenes/vfx/engine_trail.tscn` (kök metot `set_thrust(amount: float, boosting: bool)`, `player_ship` çağırır) ve `scenes/vfx/vfx_director.tscn` (sektöre bir kez instance edilir, EventBus'ı dinleyip ışın, kırılma ve pickup efektlerini kendisi oluşturur). `scenes/vfx/space_background.tscn` ve `environment_space.tres`'i Engineer sektöre koyar.
- `asteroid.tscn`'nin kök node'unda `apply_mining_damage(amount: float, hit_position: Vector3)` metodu ve `size: StringName` (`&"S"`/`&"M"`/`&"L"`) alanı bulunur. Kazma ışını yalnızca bunu çağırır.

## 6. Arayüz kontratı: EventBus sinyalleri

Mevcut `event_bus.gd`'deki sinyaller korunur, adları ve argümanları değişmez (`hull_changed`, `fuel_changed`, `energy_changed`, `heat_changed`, `slot_selected`, `player_died`, `player_respawned`; MVP'de yayınlanmazlar). MVP aşağıdakileri **ekler**. Değerler mutlaktır, delta değildir. Konumlar dünya uzayındadır.

| Sinyal | Yayınlayan | Dinleyen |
|---|---|---|
| `mining_beam_started(origin: Vector3, target: Vector3)`: dünya konumları (`FX_MiningOrigin` ve isabet noktası); koddaki imza esas | Gameplay (kazma ışını) | VFX (ışını açar) |
| `mining_beam_stopped()` | Gameplay (kazma ışını) | VFX |
| `asteroid_damaged(asteroid: Node3D, hit_position: Vector3, hp_ratio: float)`: ışın temas ettiği her fizik karesinde | Engineer (`asteroid.gd`) | VFX (ışın ucu, kıvılcım, kızarma) |
| `asteroid_destroyed(position: Vector3, radius: float)` (metre; S/M/L sınıfı gerekirse yarıçaptan türetilir) | Engineer (`asteroid.gd`) | VFX (kırılma), Engineer (yeniden doğma sayacı), Gameplay (ışını keser) |
| `ore_spawned(position: Vector3, item_id: StringName, amount: int)` | Engineer (pickup sistemi) | VFX (parlama) |
| `ore_collected(item_id: StringName, amount: int, position: Vector3)` | Engineer (pickup sistemi, kargo kabul edince) | VFX (pop), UI (küçük "+n" geri bildirimi) |
| `cargo_added(item_id: StringName, amount: int)` *(mevcut)* | Engineer (`GameState`) | UI |
| `cargo_rejected(item_id: StringName, amount: int, reason: StringName)` *(mevcut, `REJECT_*` sabitleri)* | Engineer (`GameState`) | UI ("Kargo dolu") |
| `cargo_changed(used: int, capacity: int)` | Engineer (`GameState`) | UI (HUD), Gameplay (kütle etkisi) |
| `cargo_sold(units: int, credits_earned: int)` | Engineer (`GameState`) | UI (panel geri bildirimi) |
| `credits_changed(credits: int)` | Engineer (`GameState`) | UI |
| `dock_entered()` / `dock_exited()` | Engineer (`station_dock.gd`) | UI (ipucu, paneli kapatma), Gameplay |
| `station_panel_toggled(is_open: bool)` | UI (istasyon paneli) | Gameplay (gemi girdisini durdurur), Engineer |
| `part_upgraded(part: StringName, level: int)`: `part` ∈ `&"head"`, `&"body"`, `&"wings"`, `&"engine"` | Engineer (`GameState.try_upgrade`) | Engineer (`ShipAssembler` model swap), UI (panel), VFX (opsiyonel parlama) |
| `upgrade_failed(reason: StringName, part: StringName)`: `reason` ∈ `&"NOT_ENOUGH_CREDITS"`, `&"MAX_LEVEL"`, `&"NOT_DOCKED"` | Engineer (`GameState.try_upgrade`) | UI |
| `ship_stats_changed(stats: Dictionary)`: çözülmüş statlar | Engineer (`GameState`, başlangıçta ve her yükseltmede) | Gameplay (uçuş, ışın), UI (önizleme) |

- Sinyal eklemek serbesttir. Ad ya da argüman değiştirmek kontrat değişikliğidir (Godot Engineer + Game Designer). Engineer bu listeyi ilk iş olarak tek bir küçük commit'le `eng/mvp-integration`'a koyar. Diğerleri o commit'i merge eder ve kodunu ona göre yazar.
- Kargo red nedeni olarak koddaki `REJECT_TOTAL_FULL` geçerlidir (belgelerdeki `CARRY_FULL`/`CARGO_FULL` ile aynı anlamda).

## 7. Bağımlılık ve sıra

- **Herkes hemen ve paralel başlar.** Kimse kimseyi beklemez.
- **Placeholder kuralı:** Model ya da VFX gelmeden önce primitif mesh kullanılır (asteroid = `SphereMesh`/`BoxMesh`, istasyon = halka + kutu, pickup = küçük küp, ışın = ince `CylinderMesh`). Entegrasyon asset beklemez. Asset gelince yalnızca yol değişir.
- Önerilen sıra:
  1. Engineer: EventBus sinyalleri + `GameState` iskeleti (ilk commit), ardından primitiflerle `mvp_sector.tscn`.
  2. Gameplay: uçuş + kamera, ardından kazma ışını, ardından data `.tres`. Modeler: pickup'lar + istasyon. VFX: arka plan + ışın, ardından kırılma, pickup ve iz. UI: HUD, ardından panel.
  3. Engineer entegre eder. Game Designer döngüyü oynar ve süreyi ölçer, Gameplay sayıları ayarlar.

## 8. Kabul kriterleri (MVP "tamam" tanımı)

- [ ] Döngü baştan sona hatasız oynanıyor: uç → kaz → kırıl → topla → dock → sat → yükselt. Konsolda hata yok, softlock yok.
- [ ] Bir parça L2'ye ve L3'e yükseltilince **model ekranda değişiyor** (4 parçanın her biri için), stat artışı uygulanıyor (örn. Body yükselince kargo kapasitesi HUD'da artıyor).
- [ ] İlk yükseltme yeni bir oyuncu için 3–5 dk içinde geliyor.
- [ ] Kargo dolunca pickup yerinde kalıyor, cevher kaybı ya da duplikasyon yok.
- [ ] Box'ta headless testler (`tests/`, GUT) ve smoke testi geçiyor. Smoke testi `mvp_sector.tscn`'i yükleyip API üzerinden döngüyü bir kez koşturuyor: asteroidi kır, pickup'ı topla, sat, yükselt, `scene_path`'in değiştiğini doğrula. Validator PASS veriyor.
- [ ] Hedef 60 fps (1080p, debug overlay'de gösterilir).
- [ ] HUD alt envanter barı içermiyor (AGENTS.md §8).
- [ ] Grok Bot'a oynanış videosu (Godot Movie Maker, `--write-movie`) ya da ekran görüntüleriyle rapor verildi (Engineer hazırlar, Game Designer kontrol eder).

## 9. Çalışma kuralları

- Box'ta aynı anda **tek** Godot ya da Blender penceresi açık olur. Mümkünse headless çalışılır (`godot --headless`, `blender -b`).
- Herkes kendi branch'inde ve worktree'sinde çalışır. Başkasının branch'ine, worktree'sine ya da çalışma dosyalarına dokunulmaz.
- Commit'ler AGENTS.md §4'e uyar: `type(scope): özet`, yazar `Asreonn`. **AI, co-author ya da araç satırı eklenmez.** Push yapılmaz, token istenmez.
- Hazır olunca **branch adı + worktree yolu** Grok Bot'a ve PS Game Designer'a bildirilir. Push ve PR'ı Grok Bot, Asrın'ın PC'sinden yapar.
- **Asrın'a soru sorulmaz.** Önce bu belgeye, DECISIONS.md'ye, GAME_PLAN.md'ye ve PDF'e bakılır, karar verilir ve ilerlenir. Gerçekten bloklayan bir durum PS Game Designer'a iletilir.
- Görsel değişikliklerde ekran görüntüsü zorunludur (AGENTS.md §3). `PROGRESS.md`'ye bitmeyen iş bitti diye yazılmaz.
