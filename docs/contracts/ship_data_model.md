# Sözleşme: Gemi Veri Modeli (Godot 4.7.x)

> **Sahip:** PS Gameplay Designer (kurallar ve alanlar), PS Godot Engineer (GDScript sınıfları `res://scripts/data/`, montaj `res://scripts/core/ship_assembler.gd`). Şemayı değiştirmek için iki rolün de onayı gerekir. Repoya taşındığında yolu `docs/contracts/ship_data_model.md` olacak (`docs/**` sahibi Game Designer).
> **Bağlayıcı kaynak:** `GAME_PLAN.md` v0.2: §3.3, §4.2–4.4, §5.1–5.2, §14.2, §15, §24. Repo: `AGENTS.md` §2 ve §5, `docs/DECISIONS.md`.
> **Durum:** v0.2.1, 2026-10-21. Hardpoint id'leri `L`/`R`/`Nose`/`Top`; `authored_up_to_level`; cap kontrolü cap'siz değerlerle. Gameplay Designer incelemesinden (`Docs/design/m1_contract_review.md`) kabul edilen maddeler ve Godot Engineer'ın yol seti işlendi. "Açık" diye işaretli her şey karar değil, öneri.

## 1. Kesin kurallar
| Kural | Kaynak |
|---|---|
| Motor Godot **4.7.x** stable, Forward+, GDScript. Veriler `Resource` (`.tres`) | GAME_PLAN §3.3, §15; repo D-001 [KESİN] |
| Her gemi modelinin (hull) **sabit** Head, Body, Wings, Engine seti var. Başka gemiden parça takılmaz | §4.3 [KESİN 21 Eki] |
| Her parçanın 3 görsel + stat seviyesi var: L1, L2, L3 | §4.3 [KESİN 21 Eki] |
| PDF'teki "grade artarsa parçalar görsel olarak upgrade olur" notunun karşılığı L1–L3 | §4.3 [KESİN 21 Eki] |
| Yeni gemi kendi yeni 4 parçası ve 3'er seviyesiyle gelir | §4.3 [KESİN 21 Eki] |
| Kalite ölçeği `E → D → C → B → A → S → SS → SSS`. Öğe kalitesidir, oyuncu seviyesi değil | §5.1 [KESİN] |
| Native grade sabit. Upgrade aynı grade içindeki doğal tavana yaklaştırır, grade'i değiştirmez | §5.2 [KESİN] |
| **L3 = grade içi doğal tavan** (`upgrade_caps`) | §5.2, 21 Eki (inceleme md. 1 kabul) |
| Parça → ana stat (PDF): Head → Damage (attack/mining), Engine → Flying Speed, Wings → Maneuver Speed, Body → Carry Capacity (hacim) | §4.2, PDF s.1 |
| Fuel Capacity ve Fuel Rate hiçbir parçaya zorunlu bağlı değil (PDF "None") | §4.2 |
| Energy (aktif) ile Electronics/Passive Capacity ayrı değişkenler | §4.2, §4.4 [KESİN] |
| Tanım ve runtime state ayrı. Save; native grade, parça seviyesi, upgrade level, condition ve loadout'u ayrı saklar | §15.4 |
| `TBD` sayılar uydurulmaz. Prototip değerleri `balance_prototype` olarak işaretlenir | §15.3 |
| Montaj veriden, kodla yapılır (`ShipAssembler`). Hull başına `.tscn` yok | Godot Engineer kararı, 21 Eki |

## 2. Kavramlar ve ilişki
```
ShipHullDefinition  res://data/ships/<hull_id>.tres   (1 gemi modeli, native_grade sabit)
 ├─ base_stats            Dictionary[StringName, float]
 ├─ upgrade_caps          Dictionary[StringName, float]  (grade içi doğal tavan = L3 değeri)
 ├─ hardpoints            Array[StringName]  (gemiye sabit; starter M1: L, R; Nose opsiyonel)
 ├─ authored_up_to_level int  (içeriği girilmiş en yüksek seviye; M1 = 1)
 ├─ flight_tuning         FlightTuningDefinition  (uçuş karakteri, stat değil)
 └─ head / body / wings / engine → ShipPartDefinition  res://data/parts/<part>_<hull_id>.tres
                                     └─ levels[3] → ShipPartLevel (sub-resource: L1, L2, L3)
                                           ├─ scene_path  res://assets/models/ships/<hull_id>/<part>_L<n>.glb
                                           ├─ modifiers   Array[StatModifier]  (o seviyenin MUTLAK katkısı)
                                           └─ cost        Array[CostEntry]     (bu seviyeye çıkma maliyeti)
ShipInstanceState (runtime/save): hull_id + part_levels {head, body, wings, engine → 1..3}
ShipAssembler     res://scripts/core/ship_assembler.gd: hull + state → Node3D görsel ağacı
```

**Native grade ile seviyenin ilişkisi**
- Grade **hull'a** aittir ve sabittir (`native_grade`). Parçaların ayrı bir grade alanı yoktur, hull'un grade'ini paylaşırlar (plan §4.3 / §5.2: daha yüksek grade parça ancak yeni gemiyle gelir).
- L1→L3 yükseltmesi plandaki "aynı grade içindeki doğal tavana yaklaşma"nın somut hali. Grade'i hiçbir zaman değiştirmez.
- **L3 = tavan.** `upgrade_caps`'teki her stat için L3'teki çözülmüş değer cap'e **eşittir** (±0.001). Cap'in L3'ten büyük olması, ulaşılamayan bir tavan demektir ve veri hatası sayılır (§6, kural 6).
- Yüksek grade, daha yüksek `upgrade_caps` ve base stat ile gelir. L3'e çıkmış bir E gemisi, L1'deki bir C gemisini bazı işlerde geçebilir ama L3'teki C'yi geçemez (§5.3). Hangi statın grade ile ne kadar arttığı **açık** (GAME_PLAN §20, "grade çarpanları").

**Stat çözümleme**
- Yüksek iyi statlar: `final = min((base + Σ add) × Π mul, cap)`.
- **Düşük iyi statlar** (`ShipStat.LOWER_IS_BETTER = [mass, fuel_rate]`): `final = max((base + Σ add) × Π mul, cap)`. Bu statlarda cap tavan değil **taban**dır.
- `upgrade_caps`'te bulunmayan statlar sınırsızdır. Hardpoint/pasif modül ve kargo kütlesi bundan sonra ayrı katmanda uygulanır (bu sözleşmenin dışında; alanlar `gameplay_data.md`'de).
- **Seviye modifier'ları mutlaktır:** `ShipPartLevel.modifiers` o seviyedeki toplam katkıdır, önceki seviyeye eklenen delta değildir. Resolver yalnızca o anki seviyenin listesini okur. L2'ye delta girilirse statlar düşer.
- Her parçanın **ana statı** PDF'teki eşlemedir. Ek (ikincil) modifier'lar serbesttir. Fuel statları **hiçbir parçaya zorunlu bağlanmaz**; hull'un base değerinde durur, parçalar isteğe bağlı modifier verir.

**Upgrade maliyeti (inceleme md. 4 kabul)**
- L1: maliyet yok.
- L2: **yalnızca katı kaynak** (örn. ore + crystal). Kredi istemez, çünkü kredinin kaynağı (satış) P5'te (repo ROADMAP M6) geliyor.
- L3: **katı kaynak + kredi**. Salvage hurdası P3'te (repo M4) L3 maliyetine eklenebilir.
- Parçalar birbirinden bağımsız yükselir; tek seferde +1 seviye, L3'ün üstü yok, seviye düşürme ve iade yok. Ön koşul ya da kapı yok.
- **Açık:** Upgrade'in **nerede** yapıldığı (transfer noktası, istasyon ya da menü). P3/M4 kararı. M1'de upgrade yapılmaz.

## 3. Stat anahtarları ve birimler
`StringName` sabitleri `ShipStat` içinde tanımlıdır. İsim değişikliği sözleşme değişikliği sayılır.

| Anahtar | Birim | Not |
|---|---|---|
| `damage` | puan (10 = ×1.0) | Head ana statı (saldırı) |
| `mining_power` | puan (10 = ×1.0) | Head ana statı (madencilik) |
| `flying_speed` | m/s | Engine ana statı. İvme ayrı stat değil: `a = flying_speed / flight_tuning.accel_time_to_max` |
| `maneuver_speed` | °/s | Wings ana statı |
| `carry_capacity` | u (hacim birimi) | Body ana statı, toplam hacim tavanı |
| `storage_solid` / `storage_liquid` / `storage_gas` | u | Faz başına kapasite |
| `fuel_capacity` | FU | Hull base |
| `fuel_rate` | FU/s (tam itki) | Hull base, **düşük iyi** |
| `energy_capacity` | EU | Aktif bütçe |
| `energy_regen` | EU/s | **Yeni.** Hull base, ileride pasif modül hedefi |
| `heat_capacity` | HU | |
| `heat_dissipation` | HU/s | **Yeni.** Hull base, ileride pasif modül hedefi |
| `electronic_capacity` | pasif puan | Pasif modül bütçesi (§4.4) |
| `module_capacity` | boyut puanı | Modül başına `module_size` harcanır |
| `radar_range` | m | |
| `hull` | HP | **Azami gövde HP'si.** `ShipHullDefinition` (gemi modeli) ile karıştırılmasın |
| `mass` | t | **Düşük iyi** |
| `shield` | SP | M1'de 0 |

- **Kargo kabul kuralı** (inceleme A-9, işlendi; bkz. §8 not): bir `v` hacimlik miktar ancak `storage_<faz> > 0` **ve** `used_<faz> + v ≤ storage_<faz>` **ve** `used_total + v ≤ carry_capacity` ise kabul edilir. Aksi halde ret nedeni döner (`NO_GAS_TANK`, `PHASE_FULL`, `CARGO_FULL`). Faz kapasitelerinin toplamı `carry_capacity`'yi aşabilir (ambar paylaşımlı), ama tek bir `storage_<faz>`, `carry_capacity`'yi aşamaz.
- `damage` ile `mining_power` ayrı anahtarlardır.

## 4. Dosya yerleşimi (Godot Engineer'ın yol seti, AGENTS.md §2 ile uyumlu)
| Yol | İçerik | Sahip |
|---|---|---|
| `res://scripts/data/grade.gd`, `ship_stat.gd`, `stat_modifier.gd`, `cost_entry.gd`, `ship_part_level.gd`, `ship_part_definition.gd`, `ship_hull_definition.gd`, `ship_instance_state.gd`, `ship_stats_resolver.gd`, `ship_data_validator.gd` | Şema sınıfları | Godot Engineer |
| `res://scripts/data/flight_tuning_definition.gd` | `FlightTuningDefinition` (yeni) | Godot Engineer |
| `res://scripts/core/ship_assembler.gd` | `ShipAssembler`: hull + state'ten görsel ağacı kurar | Godot Engineer |
| `res://scenes/main/ship_assembly_test.tscn` | Montaj debug sahnesi (L1–L3 geçişi, socket kontrolü) | Godot Engineer |
| `res://scenes/ship/player_ship.tscn` | Oyuncu gemisi (`CharacterBody3D`); `Visual` node'unun altında `ShipAssembler` | Gameplay Designer |
| `res://data/ships/<hull_id>.tres` | `ShipHullDefinition` (+ `flight_tuning` sub-resource) | Gameplay Designer |
| `res://data/parts/<part>_<hull_id>.tres` | `ShipPartDefinition`, 3 `ShipPartLevel` sub-resource'unu içinde taşır | Gameplay Designer |
| `res://assets/models/ships/<hull_id>/<part>_L<n>.glb`, `<hull_id>_collision.glb` | Modeller | 3D Modeler |
| `art/blender/ships/<hull_id>/` | `.blend` kaynakları (LFS; `art/` zaten `.gdignore`'lu) | 3D Modeler |

Örnek (starter): `data/ships/starter_shuttle_01.tres`, `data/parts/head_starter_shuttle_01.tres`, `assets/models/ships/starter_shuttle_01/head_L2.glb`, `assets/models/ships/starter_shuttle_01/starter_shuttle_01_collision.glb`, `art/blender/ships/starter_shuttle_01/starter_shuttle_01.blend`.

**Parça id formatı:** `<part>_<hull_id>`. `part` ∈ {`head`, `body`, `wings`, `engine`}. Örnek: `head_starter_shuttle_01`.

## 5. GDScript iskeleti (Godot 4.7.x)
```gdscript
# grade.gd
class_name Grade
enum Value { E, D, C, B, A, S, SS, SSS }   # sıra = kalite sırası (§5.1)

# ship_stat.gd
class_name ShipStat
const DAMAGE := &"damage"
const MINING_POWER := &"mining_power"
const FLYING_SPEED := &"flying_speed"
const MANEUVER_SPEED := &"maneuver_speed"
const CARRY_CAPACITY := &"carry_capacity"
const FUEL_CAPACITY := &"fuel_capacity"
const FUEL_RATE := &"fuel_rate"
const ENERGY_REGEN := &"energy_regen"
const HEAT_DISSIPATION := &"heat_dissipation"
const MASS := &"mass"
# ... §3'teki listenin geri kalanı
const LOWER_IS_BETTER: Array[StringName] = [&"mass", &"fuel_rate"]

# stat_modifier.gd
class_name StatModifier extends Resource
enum Op { ADD, MUL }
@export var stat: StringName
@export var op: Op = Op.ADD
@export var value: float = 0.0

# cost_entry.gd
class_name CostEntry extends Resource
@export var item_id: StringName      # ResourceDefinition id veya &"credits"
@export var amount: int = 0

# ship_part_level.gd
class_name ShipPartLevel extends Resource
@export_range(1, 3) var level: int = 1
@export_file("*.glb") var scene_path: String             # res://assets/models/ships/<hull_id>/<part>_L<n>.glb
@export var modifiers: Array[StatModifier] = []          # o seviyenin MUTLAK katkısı (kümülatif değil)
@export var cost: Array[CostEntry] = []                  # bu seviyeye ÇIKMA maliyeti; L1 boş, L2 kaynak, L3 kaynak + kredi
@export var balance_prototype: bool = true               # §15.3

# ship_part_definition.gd
class_name ShipPartDefinition extends Resource
enum Slot { HEAD, BODY, WINGS, ENGINE }
@export var id: StringName                 # <part>_<hull_id>, örn. &"head_starter_shuttle_01"
@export var hull_id: StringName            # tek sahibi; başka hull'a atanamaz
@export var slot: Slot
@export var display_name: String
@export var levels: Array[ShipPartLevel] = []   # sırası L1, L2, L3; en az authored_up_to_level eleman
@export_range(1, 3) var authored_up_to_level: int = 1    # hull'unkinden büyük olamaz; M1 = 1

func get_level(n: int) -> ShipPartLevel:
	# İçeriği girilmemiş seviye istenirse son authored seviyeye düşer.
	return levels[clampi(n, 1, mini(authored_up_to_level, levels.size())) - 1]

# flight_tuning_definition.gd  (uçuş karakteri; upgrade edilen stat değil)
class_name FlightTuningDefinition extends Resource
enum ControlScheme { A, B }   # A = WASD + burun fareye (varsayılan), B = W/S itki + A/D dönüş
@export var control_scheme: ControlScheme = ControlScheme.A
@export var reference_mass: float          # t
@export var accel_time_to_max: float       # s
@export var reverse_thrust_ratio: float
@export var strafe_speed_ratio: float
@export var lateral_grip: float            # 1/s
@export var coast_damp: float              # 1/s
@export var brake_damp: float              # 1/s
@export var drift_grip_mult: float
@export var drift_damp: float              # 1/s
@export var drift_thrust_mult: float
@export var drift_turn_mult: float
@export var turn_gain: float               # 1/s
@export var turn_response: float           # 1/s
@export var overspeed_decay: float         # 1/s
@export var boost_speed_mult: float
@export var boost_accel_mult: float
@export var boost_max_duration: float      # s
@export var boost_cooldown: float          # s
@export var boost_start_fuel: float        # FU
@export var boost_fuel_per_s: float        # FU/s
@export var boost_min_fuel: float          # FU
@export var fuel_idle_ratio: float
@export var limp_speed_mult: float
@export var mass_exp_accel: float
@export var mass_exp_turn: float
@export var mass_exp_brake: float
@export var collision_restitution: float
@export var collision_damage_threshold: float   # m/s
@export var collision_damage_per_mps: float     # HP / (m/s)
@export var maneuver_reference: float           # °/s
# Alan listesi ve starter değerleri: Docs/design/data/m1_starter_ship.json (balance_prototype)

# ship_hull_definition.gd
class_name ShipHullDefinition extends Resource
const MAX_PART_LEVEL := 3
@export var id: StringName                 # örn. &"starter_shuttle_01"
@export var display_name: String
@export var native_grade: Grade.Value = Grade.Value.E     # sabit (§5.2)
@export var affinity: Array[StringName] = []              # eğilim etiketi, kilit değil (§4.1)
@export var base_stats: Dictionary[StringName, float] = {}
@export var upgrade_caps: Dictionary[StringName, float] = {}   # grade içi doğal tavan = L3 değeri
@export var hardpoints: Array[StringName] = []            # starter M1: [&"L", &"R"]; &"Nose" opsiyonel
@export_range(1, 3) var authored_up_to_level: int = 1    # M1 = 1; üstündeki eksik model/değer uyarıdır, hata değil
@export var flight_tuning: FlightTuningDefinition
@export var head: ShipPartDefinition
@export var body: ShipPartDefinition
@export var wings: ShipPartDefinition
@export var engine: ShipPartDefinition
# assembly_scene alanı YOK: montaj ShipAssembler ile veriden yapılır.

func get_part(slot: ShipPartDefinition.Slot) -> ShipPartDefinition:
	match slot:
		ShipPartDefinition.Slot.HEAD: return head
		ShipPartDefinition.Slot.BODY: return body
		ShipPartDefinition.Slot.WINGS: return wings
		_: return engine

# ship_instance_state.gd  (runtime + save; tanım verisi içermez)
class_name ShipInstanceState extends Resource
@export var hull_id: StringName
@export var part_levels: Dictionary[StringName, int] = { &"head": 1, &"body": 1, &"wings": 1, &"engine": 1 }   # 1..3
# hull_hp, fuel, loadout, cargo: ayrı state nesneleri (bu sözleşmenin dışında)

func can_upgrade(part: StringName, def: ShipPartDefinition) -> bool:
	return part_levels.get(part, 1) < mini(ShipHullDefinition.MAX_PART_LEVEL, def.authored_up_to_level)

# ship_stats_resolver.gd
class_name ShipStatsResolver
static func resolve(hull: ShipHullDefinition, state: ShipInstanceState, apply_caps: bool = true) -> Dictionary[StringName, float]:
	var add: Dictionary[StringName, float] = {}
	var mul: Dictionary[StringName, float] = {}
	for slot: int in ShipPartDefinition.Slot.values():
		var part: ShipPartDefinition = hull.get_part(slot)
		var key := StringName(ShipPartDefinition.Slot.keys()[slot].to_lower())
		var lvl: ShipPartLevel = part.get_level(state.part_levels.get(key, 1))
		for m: StatModifier in lvl.modifiers:
			if m.op == StatModifier.Op.ADD:
				add[m.stat] = add.get(m.stat, 0.0) + m.value
			else:
				mul[m.stat] = mul.get(m.stat, 1.0) * m.value
	var keys: Dictionary[StringName, bool] = {}          # tekilleştirilmiş anahtar kümesi
	for s: StringName in hull.base_stats: keys[s] = true
	for s: StringName in add: keys[s] = true
	var out: Dictionary[StringName, float] = {}
	for s: StringName in keys:
		var v: float = (hull.base_stats.get(s, 0.0) + add.get(s, 0.0)) * mul.get(s, 1.0)
		if apply_caps and hull.upgrade_caps.has(s):
			var cap: float = hull.upgrade_caps[s]
			v = maxf(v, cap) if s in ShipStat.LOWER_IS_BETTER else minf(v, cap)
		out[s] = v
	return out
```

**`ShipAssembler` sözleşmesi** (`res://scripts/core/ship_assembler.gd`, Godot Engineer)
- Girdi: `ShipHullDefinition` + `ShipInstanceState`. Çıktı: çağıranın verdiği node'un (oyuncuda `player_ship.tscn` → `Visual`) altına kurulmuş görsel ağaç.
- Adımlar: body seviyesinin GLB'sini yükler, `Socket_Head`, `Socket_Wings`, `Socket_Engine` empty'lerinin transform'larını okur, diğer 3 parçanın o seviyedeki GLB'lerini bu noktalara instance eder. `Hardpoint_*` ve `FX_*` empty'lerini isimle bulup çağırana sunar (hull id `X` ↔ node `Hardpoint_X`, §7).
- Seviye değişince yalnızca ilgili parçayı yeniden kurar. Hull başına `.tscn` yoktur.
- Debug: `scenes/main/ship_assembly_test.tscn` dört parçayı L1–L3 arasında değiştirip socket ve hardpoint konumlarını gösterir.

**Notlar**
- Godot 4.7.x kilitli olduğu için `Dictionary[K, V]` (4.4+) tipli kullanılır. `.tres`'te String/StringName anahtar karışıklığı riski de böylece kalkar.
- Upgrade akışı (maliyetin düşülmesi, envanter kontrolü) `ShipUpgradeService`'te olacak, Godot Engineer yazar, M4'te.

## 6. Doğrulama (`res://scripts/data/ship_data_validator.gd`, editor/test)
**Hata (veri reddedilir)**
Kurallar 3–6 ve 8 yalnızca **authored** seviyeler için (`n ≤ part.authored_up_to_level`) hata üretir. Bunun üstündeki seviyelerde eksik model, maliyet ya da değer **uyarıdır** (W3). M1'de `authored_up_to_level = 1` olduğundan yalnızca L1 doludur ve bu bir hata değildir.

0. `1 ≤ part.authored_up_to_level ≤ hull.authored_up_to_level ≤ 3`.
1. Hull'da 4 parçanın hepsi dolu ve her birinin `slot`'u alanıyla eşleşiyor.
2. `part.hull_id == hull.id`. Bir `ShipPartDefinition` birden fazla hull'da kullanılmıyor (başka gemiden parça yok).
3. `levels.size() ≥ authored_up_to_level` (en çok 3) ve sırası `level` 1, 2, 3.
4. `part.id == "<part>_<hull_id>"` (örn. `head_starter_shuttle_01`), dosya `res://data/parts/<part.id>.tres`. Dolu her `scene_path` mevcut ve `res://assets/models/ships/<hull_id>/<part>_L<n>.glb` kalıbına uyuyor (`n == level`). Authored seviyelerin `scene_path`'i zorunlu.
5. (Authored seviyeler için) L1'in `cost`'u boş. L2'nin `cost`'u dolu ve **kredi içermiyor**. L3'ün `cost`'u katı kaynak **ve** kredi içeriyor.
6. **Cap kontrolü cap'siz değerlerle yapılır** (`ShipStatsResolver.resolve(hull, state, false)`; resolver cap uyguladığı için çözülmüş değerle kontrol anlamsız). Dört parça aynı seviyede `n` iken, `upgrade_caps`'teki her stat için L1, L2 ve L3'ün **hepsinde** cap'siz değer cap'i aşmıyor (düşük iyi statlarda cap'in altına inmiyor). L3 authored ise L3'ün cap'siz değeri cap'e **eşit** (±0.001); büyük olması tavanın L3'ten önce kesildiği, küçük olması ulaşılamayan tavan demektir.
7. `fuel_capacity` ve `fuel_rate` hull `base_stats`'ında tanımlı. Parça modifier'ı zorunlu değil.
8. **Mutlak seviye değerleri:** authored seviyelerde, her parçanın ana statında cap'siz L1 ≤ L2 ≤ L3 (`mass` / `fuel_rate` gibi düşük iyi statlarda L1 ≥ L2 ≥ L3).
9. Her authored seviyede `storage_<faz>` ≤ `carry_capacity` (ikisi de çözülmüş).
10. `hardpoints`'teki her id {`L`, `R`, `Nose`, `Top`} içinde ve `Top` M1'de yok, ve mevcut body GLB'lerinin hepsinde karşılık gelen `Hardpoint_*` empty'si bulunuyor.

**Uyarı (veri kabul edilir, log'a yazılır)**
- W1. Bir `MUL` modifier'ının statı `hull.base_stats`'ta tanımlı değil. O stat çözümlemede sessizce düşer.
- W3. `authored_up_to_level` üstündeki seviyede eksik `ShipPartLevel`, `scene_path`, `cost` ya da modifier (M1'de beklenen durum). `get_level()` ve `ShipAssembler` son authored seviyeye düşer; `can_upgrade()` bu seviyenin üstüne izin vermez.
- W2. Bir ikincil statta L1 → L3 sırası bozuk (ana stat dışındaki statlar için bilgi amaçlı).

## 7. 3D Modeler için kurallar
**Adlandırma ve dosyalar**
- Export: `res://assets/models/ships/<hull_id>/<part>_L<n>.glb`; `part` ∈ {`head`, `body`, `wings`, `engine`}, `n` ∈ {1, 2, 3}. Bir gemi = **12 GLB**. M1'de yalnızca L1 (4 GLB).
- Çarpışma: `<hull_id>_collision.glb` (convex, tek mesh), aynı klasörde.
- Kaynak: `art/blender/ships/<hull_id>/` (`.blend`, LFS). `art/` klasörü zaten `.gdignore`'lu.
- GLB içinde kök node `<part>_L<n>` olur, mesh ise `<part>_L<n>_mesh`.
- Materyaller VFX'in ortak kütüphanesinden (`assets/materials/m_lowpoly_base.tres`) ya da vertex color/palet ile gelir; materyal adı `M_<ad>`. Seviyeler arasında yalnızca renk değiştirmek yetmez, form ve silüet de değişmeli (§14.2-4).

**Eksen ve ölçek** (AGENTS.md §5, D-005)
- Godot tarafında: Y-up, burun **−Z**, 1 birim = 1 m, oynanış düzlemi XZ (Y = 0).
- Blender'da (Z-up) burun **+Y** yönüne bakar; glTF export "+Y Up" açık. Export sonrası Godot'ta −Z'ye döner.
- Transform'lar uygulanmış olmalı (scale 1, rotation 0). Starter ~3 m boy.

**Tek isim standardı [KESİN 2026-10-21]** (repo AGENTS.md §5 ile aynı; `PartSocket_*`, `Socket_Body`, `Hardpoint_hp_*`, `FX_Thruster_*` isimleri **geçersiz**)
- Blender obje adları: `Head_<hull_id>`, `Body_<hull_id>`, `Wings_<hull_id>`, `Engine_<hull_id>`; aktif donanım `Weapon_*`, `MiningLaser_*`, `MiningBomb_*`, `MiningDrill_*`.
- Body kök parçadır, origin'i gemi merkezidir (0,0,0; kütle ve dönüş merkezi). Onun için socket yok.
- Body GLB'si 3 empty taşır: `Socket_Head`, `Socket_Wings`, `Socket_Engine`. Head/Wings/Engine GLB'lerinin **origin'i** kendi socket noktasıdır. L1–L3'te socket empty'leri aynı yerde kalır; bir parçanın üç seviyesi aynı origin'i ve yönü paylaşır. Transform'lar ayrıca `docs/contracts/model_anchors.md`'ye yazılır.
- Wings iki kanadı tek GLB'de taşır, simetriktir.
- Hardpoint empty'leri **body** GLB'lerinde durur ve L1–L3'te **aynı konumda** kalır. Diğer parçaların seviye geometrisi hardpoint hacmine girmez.

| Hull id | Blender/GLB empty | M1 starter |
|---|---|---|
| `L` | `Hardpoint_L` | **var** (Laser) |
| `R` | `Hardpoint_R` | **var** (blaster) |
| `Nose` | `Hardpoint_Nose` | **opsiyonel**; modelde olabilir, hull'un `hardpoints` listesine M1'de girmez |
| `Top` | `Hardpoint_Top` | **M2'de** gelir (Bomb/Drill ile 3. aktif modül). M1 modelinde yok |

- Diğer empty'ler: `FX_EngineTrail_<n>` (engine parçalarında motor izi çıkışı, n = 0'dan başlar), `FX_MiningOrigin` (head'de, opsiyonel). Bu FX empty'lerinin seviyeye göre yer değiştirmesi serbesttir; kod ve VFX bunları her seviyede isimle bulur.
- Kontrol listesi (her seviye için): üstten ortografikte silüet okunuyor; L1→L3 geçişinde clipping ve socket kayması yok; aynı tasarım ailesinde kalıyor. Turntable + oyun içi kamera açısından render PR'a eklenir.
- Poligon bütçesi **açık** (§14.4). Geçici öneri (repo modeling brief ile uyumlu): parça seviyesi başına ≤ 1k tri, gemi toplamı ≤ 3k tri (L3 dahil).

## 8. Açık noktalar ve kapananlar
| # | Konu | Durum |
|---|---|---|
| 1 | L3 = grade içi doğal tavan mı? | **Kapandı:** evet; LOWER_IS_BETTER ile, validator kural 6 |
| 2 | Parçaların ayrı grade alanı | **Kapandı:** yok, hull'un grade'ini paylaşır |
| 3 | Her seviyenin stat artışı, grade çarpanları | Açık. Değerler `balance_prototype` (`m1_starter_ship.json`) |
| 4 | Upgrade maliyeti | **Kapandı:** L2 yalnız katı kaynak, L3 kaynak + kredi; salvage P3'te |
| 5 | Upgrade sırası / ön koşul | **Kapandı:** bağımsız, +1 |
| 6 | Seviye düşürme / iade | **Kapandı:** yok |
| 7 | Seviyeyle yeni hardpoint | **Kapandı:** hayır, hardpoint gemiye sabit. M1 starter'da 2 hardpoint (`L`, `R`). `Nose` opsiyonel, `Top` M2 |
| 15 | M1'de yalnızca L1 dolu | **Kapandı:** `authored_up_to_level` (hull + parça, M1 = 1); üstü uyarı |
| 8 | Gemi değişince eski gemi | Varsayılan: seviyeler gemide kalır, taşınmaz; eski gemi saklanır/satılır (P5+) |
| 9 | Kargo kabul kuralı | İşlendi (§3, validator 9) |
| 10 | `damage` / `mining_power` | Ayrı anahtarlar; 10 = ×1.0 |
| 11 | Godot sürümü | **Kapandı:** 4.7.x, tipli Dictionary |
| 12 | Poligon bütçesi | Açık. Geçici: parça ≤ 1k, gemi ≤ 3k tri |
| 13 | Upgrade nerede yapılır | Açık, M4/P3 kararı |
| 14 | `gameplay_data.md` (Module/Resource/Asteroid/LootTable alanları) | Açık; Gameplay Designer açacak (inceleme İ-6) |

**İnceleme (`m1_contract_review.md`) eşlemesi:** işlenenler A-1, A-4, A-9, İ-1, İ-2, İ-3, İ-4, İ-5; A-7'deki 4 hardpoint önerisi **reddedildi** (M1'de 2). Godot 4.7.x kilidiyle A-11 de kapandı. İ-7 (`hull` notu) §3'e eklendi.
