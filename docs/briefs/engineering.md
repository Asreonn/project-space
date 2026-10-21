# Brief — Godot Engineer

**Sahip olduğun yollar:** `project.godot`, `export_presets.cfg`, `addons/**`, `scripts/core/**`, `scripts/data/**`, `scripts/debug/**`, `scenes/main/**`, `tests/**`, `.github/**`, `.gitignore`, `.gitattributes`, `docs/TOOLS.md`.
**Branch öneki:** `eng/` · **Görev:** tüm PR'ları review eder ve **squash merge** edersin (tasarım PR'larında Game Designer onayını bekle).

## Rolün

Mimariyi kurar, içeriği koddan ayırırsın (§15). Diğer rollerin paralel çalışabilmesi için sözleşmeleri (veri şeması, sinyaller, sahne arayüzleri) **ilk hafta** yayınlarsın.

## [KESİN] kararlar

- Motor Godot 4.7.x stable, Forward+, GDScript (DECISIONS D-001).
- İçerik/kod ayrımı; ikinci gemi eklemek kod kopyalamayı gerektirmez (§15, §21).
- Aynı item/ship tanımı tek veri kaynağı (§15.4). Item duplikasyonu ve kapasite bypass'ı engellenir.
- Native grade, item grade, upgrade level, condition, loadout ayrı saklanır (§15.4) — save M7, ama şema şimdiden.
- Object pooling (projectile, loot, debris) (§3.3, §15.4).
- Sınıf kilidi yok, universal hardpoint, ayrı electronics bütçesi (§4.4) — veri modelinde zorunlu.
- TBD değerler uydurulmaz → `balance_prototype` (§15.3).

## Mimari önerisi (§15.1–15.2'nin Godot karşılığı)

- **Veri:** `Resource` alt sınıfları `scripts/data/`: `ShipHullDefinition`, `ShipPartDefinition`, `ModuleDefinition`, `ResourceDefinition`, `AsteroidDefinition`, `EnemyDefinition`, `LootTableDefinition` (M1); diğerleri ilgili milestone'da. `.tres` örnekleri `data/`.
- **Autoload'lar** (`scripts/core/`): `EventBus` (`scripts/core/event_bus.gd`, global sinyal bus; M1 listesi: `hull_changed(current, maximum)`, `fuel_changed(current, maximum)`, `energy_changed(current, maximum)`, `heat_changed(current, maximum)`, `slot_selected(slot_number)`, `cargo_added(item_id, amount)`, `cargo_rejected(item_id, amount, reason)`, `player_died()`, `player_respawned()`), `Pools` (object pool), `GameState` (oturum durumu), `Debug` (F3 overlay).
- **Sistemler:** `ShipStatsResolver` (parçalar + modüller → efektif stat), `HardpointLoadout`, `CargoStorage` (solid/liquid/gas), `MiningExtractor` ↔ `AsteroidResourceNode`.
- **Sahne arayüzleri:** `player_ship.tscn` kök `ShipRoot` + `Visual` (glb instance) + `Hardpoints/` (Node3D'ler glb'deki `Hardpoint_*` boşlarından) + `FX/`.
- Fizik: XZ düzlemine kilit (Y pozisyon + X/Z rotasyon sabit), gravity 0 (project.godot'ta).

## M1 görevlerin

1. Hafta 1'de sözleşmeler: veri sınıfları, `EventBus` sinyalleri, sahne arayüzleri → `docs/ARCHITECTURE.md`.
2. `scenes/main/main.tscn` kompozisyonu: world, player, camera, HUD, VFX environment.
3. `Pools`, `Debug` overlay (FPS, hız, fuel, heat, kargo, draw calls).
4. glTF import ayarları/post-import script (hardpoint boşlarını Node3D'ye, collision üretimi `-col` soneki vb.) — Modeler ile.
5. Testler: smoke (var) + kargo/stat resolver birim testleri (gdUnit4 eklemeyi değerlendir) ; GitHub Actions: headless import + smoke (`.github/workflows/ci.yml`, barebones Godot binary indir).
6. Export preset: Linux + Windows (box'ta export template'leri kurulu).
7. Her PR'ı review et: sahiplik ihlali, LFS, isimlendirme, AI trailer yasağı, smoke test.

## Kabul

Diğer roller sözleşmeye göre paralel ilerleyebiliyor; `main` her zaman çalışıyor; CI yeşil; M1 sahnesi tek komutla açılıyor.

## Referans

- GAME_PLAN §15 (mimari), §16 (fazlar), §18 (test planı), §21 (başlangıç emri).
- `docs/TOOLS.md` (Godot MCP, Blender CLI, export).
- Görsel: `docs/references/02_Gameplay_Mood/01_Starter_Mining.png` (hedef sahne kompozisyonu).


---

## Ek — GAME_PLAN.md'den ilgili bölümler (birebir)

> Aşağıdaki metin `docs/GAME_PLAN.md` v0.1'den kopyalandı; çelişkide GAME_PLAN + `docs/DECISIONS.md` geçerlidir. **Motor artık Godot 4** (D-001) — §3.3/§20'deki "motor açık" ifadeleri kapandı.


### 3. Kamera, fizik ve kontroller

#### 3.1 Perspektif

- **[KESİN]** Yukarıdan görünen, hafif açı hissi taşıyan **2.5D top-down** dünya.
- **[HEDEF]** Gemiler gerçek 3D hacimli modellere sahip olur; oynanış konumu ve hedefleme bir ana düzlemde anlaşılır.
- **[HEDEF]** Kamerada gerektiğinde hafif takip/zoom; asteroid ve gemi silüetleri UI'yı kapatmaz.
- **[ÖNERİ]** Ortografik veya düşük perspektif bozulmalı kamera. Nihai kamera açısı oynanabilir prototiple seçilecek.

#### 3.2 Gemi sürüşü

- Hızlanma/yavaşlama ve dönme hissi.
- **Flying Speed** ile **Maneuver Speed** birbirinden ayrılır.
- Boost ve kısa süreli drift / inertia hissi; arcade okunabilirliği korunur.
- Büyük kargo, ağır donanım ve farklı motorların manevra/hız/yakıt etkileri.
- Düşman ateşinden kaçma ve asteroidden sıyrılma becerisi.
- **[AÇIK]** WASD + fare yönlendirme mi, ikiz analog hissi mi, alternatif sürüş modları mı; kontrol şeması playtest ile kilitlenmeli.

#### 3.3 Performans hedefi

- Gemiler ve asteroidler düşük poligonlu, tekrardan kullanılabilir modüler varlıklar.
- Yoğun nebula ve parçacıklar görsel referanstır; ekranda binlerce pahalı şeffaf efekt zorunlu değildir.
- Nesne havuzu (projectile, loot, debris), görünürlük/LOD ve yükleme bütçeleri baştan düşünülür.
- **[AÇIK]** Oyun motoru kesinleşmiş değil; Godot/Unity seçimi bu belge tarafından zorlanmamalı.


### 4. Gemiler: katalog, eğilimler ve bütünleşik statlar

#### 4.1 Gemi arketipleri

**[PDF][KESİN]** Dört ad **class kilidi değil, eğilim etiketidir**:

- **Fighter:** Savaş, dayanıklılık, silah ve refleks çatışması eğilimi.
- **Explorer:** Hız/menzil, radar, keşif ve hareketlilik eğilimi.
- **Miner:** Maden donanımı, enerji, kargo ve kazı verimliliği eğilimi.
- **Salvager:** Enkaz tarama, sökme, çekme, hasarlı parçaları taşıma eğilimi.

Bir gemi hem Fighter hem Explorer, hatta Miner/Salvager yeteneklerini taşıyabilir. Geminin tasarımı ve fabrika çıkış değerleri **başlangıç yönünü** belirler, neyi yapabileceğini kesin biçimde yasaklamaz.

**[KESİN]** Oyuncu gemilerinin çok sayıda farklı modeli/silüeti olmalı; hepsinin gövde biçimi, kapasitesi, hareket hissi, doğal limitleri ve geliştirme potansiyeli aynı şablonun kopyası olmamalı. Tam katalog miktarı kesinleşmiş değil.

#### 4.2 Temel gemi statları

| Stat | Kaynak / ilişkili parça | Oynanış etkisi |
|---|---|---|
| **Damage / Mining power** | **Head** + takılı araç/silah | Saldırı ve kaynak çıkarma etkisi |
| **Flying Speed** | **Engine** | İleri hareket / azami hız eğilimi |
| **Maneuver Speed** | **Wings** | Dönüş, kaçınma, çeviklik |
| **Carry Capacity (hacim)** | **Body** | Taşınabilir kargo miktarı |
| **Fuel Capacity** | Gemi ve ilgili tank/altyapı | Depodaki yakıt miktarı |
| **Fuel Rate** | Gemi ve itki/yük bütçesi | Tüketim hızı |
| **Energy Capacity** | Güç sistemi | Aktif kullanım/çalışma bütçesi |
| **Module Capacity** | Gemi gövdesi / bağlantılar | Takılabilen silah/madencilik aracı limitleri |
| **Radar Range** | Radar ve sensörler | Algılama ve görsel/sensör menzili |
| **Hull / Health** | Gövde ve ilgili güçlendirmeler | Hasara dayanım |
| **Heat** | Silah, araç, motor, soğutma | Sürekli çalışma ve aşırı yük sınırı |
| **Mass** | Gövde, donanım, yük | Kontrol, hız, manevra ve tüketim maliyeti |
| **Shield (varsa)** | Savunma donanımı | Hasar emme / yenilenme |
| **Electronics / Passive Capacity** | Ayrı elektronik bütçesi | Pasif stat modüllerini taşıma limiti |

**PDF nüansı:** Notlarda Fuel Capacity ve Fuel Rate belirli bir zorunlu parçaya bağlanmamış (`None`). Bu yüzden bunlar sadece tek bir motor parçasından türeyen sabitler olarak kodlanmamalı. Gemi temeli, tanklar, motor ve donanımla değişebilir.

**Önceki kararlardan güncelleme:** PDF'deki “Energy Capacity (passive skill limit)” daha sonra **ayrı pasif elektronik kapasite** kararıyla ayrıştı. Bu belge, aktif çalışma enerjisi ile **pasif elektronik bütçesini ayrı değişkenler** olarak kabul eder; gerçek denge sayıları henüz açık.

#### 4.3 Modüler ana anatomisi

**[PDF][KESİN]** Gemi parça tasarımında en az dört ana görsel/işlevsel katman:

1. **Head:** burun/ön modül, saldırı ve madencilik eğilimi.
2. **Engine:** motor ve itki grubu; uçuş karakteristiği.
3. **Wings:** kanat/manevra kontrol bileşenleri.
4. **Body:** ana gövde, hacim, kargo ve iç sistem taşıma.

- Her parçanın kendine ait formu, grade'i, yükseltilebilir değerleri ve takıldığı gemi üzerindeki uyumluluğu olabilir.
- **[PDF]** Grade'e bağlı parça görünümü değişir; düşükten yükseğe yalnızca sayısal değil görsel kalite de hissedilmeli.
- **[KESİN]** Gemiler aynı hazır modelin yalnızca rengini değiştirerek çoğaltılmamalı.
- **[ÖNERİ]** Her ana parça için açık local anchor/pivot ve standart bağlantı arabirimi kur; hangi kombinasyonların clipping'e neden olacağı test edilmeli.

#### 4.4 Universal hardpoint politikası

**[KESİN — 18 Ekim kararı]** Gemideki aktif hardpoint'ler Fighter/Miner gibi sınıf etiketlerine veya “bu yuva yalnızca silah içindir” gibi keyfî kategori sınırlarına bağlanmaz. Oyuncu herhangi bir uygun aktif ekipmanı herhangi bir evrensel bağlantı noktasına takabilir.

**Özgürlüğün bedeli bütçelerden gelir:**

- Mass / geminin toplam kütlesi
- Energy / güç tüketimi
- Heat / ısınma
- Fuel / yakıt ekonomisi
- Recoil veya atışın hareket üzerindeki etkisi
- Speed ve maneuver cezaları
- Modelin doğal stat tavanları ve **Module Capacity**
- Fiziksel çakışma/ölçek kısıtları (uygulamada ayrı kontrol edilir; keyfî class kilidi üretilmez)

**[KESİN]** Pasif sayısal stat bonusları, aktif hardpoint'leri tıkamak yerine **ayrı Electronics/Passive Capacity** bütçesi kullanır.

#### 4.5 Silah ve araç davranışları

- Hibrit yaklaşım: sabit yönlü silahlar ile bağımsız dönebilen turret/araçlar birlikte mümkün.
- Oyuncunun yön değiştirmesi, kaçınması ve atışı manuel kontrol etmesi önemli.
- **[HEDEF]** Her silah/araç kendi ses, geri tepme, açılma, enerji ve etki görseline sahip.
- **[ÖNERİ]** Turret dönüş hızı / firing arc / projectile speed veriye dayalı olsun; tam açı ve sınırlama sayıları test edilmeden kilitlenmesin.


### 15. Sistem mimarisi — motor bağımsız teslimat

**[HEDEF]** İçerik ile oyun kodu ayrılmalı; gemi ve item katalogları genişlediğinde onlarca özel kod bloğu oluşmamalı.

#### 15.1 Önerilen veri varlıkları

- `ShipHullDefinition` — model, nativeGrade, baseStats, upgradeCaps, hardpoints, native capacities.
- `ShipPartDefinition` — Head/Engine/Wings/Body, grade, visual prefab, stat modifiers, caps.
- `ModuleDefinition` — aktif/pasif, grade, enerji/ısı/kütle, davranış, VFX/SFX, kısıtlar.
- `ResourceDefinition` — solid/liquid/gas, grade, hacim, kütle, işleme sınıfı.
- `AsteroidDefinition` — mesh family, vein/core nodes, resource pool, health/fracture.
- `WreckDefinition` — sökülebilir bileşenler, condition, loot pool.
- `EnemyDefinition` — gövde/ekipman/AI davranış seti.
- `RegionDefinition` — atmosfer, nesne kümesi, tehlike, kaynak dağılımı.
- `LootTableDefinition` — grade ağırlıkları ve kaynak tipleri.
- `MotherShipDefinition` — native grade, gövde/ham kapasite, oda planı, hangar alanları.
- `RoomDefinition`, `CrewDefinition`, `RecipeDefinition` — ilgili fazlarda.

#### 15.2 Ayrıştırılacak çalışma sistemleri

1. `FlightController` + `ShipStatsResolver`.
2. `HardpointLoadout` + `ActiveModules` + `PassiveElectronics`.
3. `Damage/Heat/Energy/Fuel`.
4. `MiningExtractor` + `AsteroidResourceNode`.
5. `CargoStorage` (solid/liquid/gas).
6. `LootAndSalvage`.
7. `CombatProjectiles` + `EnemyAI`.
8. `GradeAndUpgradeRules`.
9. `WorldSectors` + `RadarDiscovery`.
10. `SaveLoad`, `Economy` ve daha sonra `MotherShipRooms`.

#### 15.3 Veri kontratı örneği (nihai JSON şeması değil)

```yaml
ship:
  id: starter_shuttle_01
  model_id: starter_shuttle_01
  native_grade: E
  affinity: [explorer, miner]   # Eğilim; sınıf kilidi DEĞİL
  body: body_starter_01
  head: head_starter_01
  wings: wings_starter_01
  engine: engine_starter_01
  hardpoints: [hp_left, hp_right]
  base_stats:
    hull: TBD
    flying_speed: TBD
    maneuver_speed: TBD
    fuel_capacity: TBD
    fuel_rate: TBD
    energy_capacity: TBD
    electronic_capacity: TBD
    radar_range: TBD
  storage:
    solid: TBD
    liquid: TBD
    gas: TBD
```

`TBD` değerleri **karar verilmemiştir**; ajanın kendiliğinden kalıcı game balance olarak uydurmaması gerekir. Prototip için geçici test değerleri kullanılır ve `balance_prototype` olarak işaretlenir.

#### 15.4 Teknik ilkeler

- Save dosyası native grade, item grade, upgrade level, condition ve loadout'u ayrı saklar.
- Prototipte bile aynı item/ship tanımı tek veri kaynağı olmalı.
- Asteroid/maden/salvage iş akışında item duplikasyonu ve kapasite bypass'ı engellenmeli.
- Büyük miktarda asteroid/loot için object pooling.
- Ortam/konum üretimi seed tabanlı ve debug edilebilir olabilir (**[ÖNERİ]**).
- Klasör isimleri ve veri formatı seçilen oyun motorunun kurallarına göre uyarlanabilir; yukarıdaki mantıksal sınırlar korunur.


### 16. Aşamalı geliştirme yol haritası

> **Strateji:** Devasa içerik kataloğu ile başlamayın. Önce fiziksel his + kısa tamamlanabilir oyun döngüsü, sonra sistem genişliği.

#### P0 — Playable Flight & Visual Baseline

**Amaç:** Oyuncunun hissini değerlendirebileceği, görsel referansa benzeyen **ilk oynanabilir ekran**.

- [ ] Seçilen oyun motorunda temiz, versiyonlanan repo/oyun projesi.
- [ ] 2.5D top-down sahne, kamera, temel input.
- [ ] Tek, düşük poligonlu cute starter gemi (ayrılabilir ana parçalar).
- [ ] Uçuş, dönüş, hızlanma, fren, boost/drift için ilk hareket denemesi.
- [ ] Koyu pastel nebula/uzay arka planı + az sayıda asteroid.
- [ ] Sol üst **Hull + Fuel** barları.
- [ ] Solda dört pozisyona kadar aktif araç/skill slotu (ilk etapta kısmi çalışabilir).
- [ ] Sol altta minimap.
- [ ] Oynanışta altta inventory barı **yok**.
- [ ] Test/debug overlay: FPS, velocity, fuel, stat budget.

**Kabul:** Gemi çevrilip sürülebiliyor, kadraj ölçeğinde rahat görülüyor, düşük poligonlu ortam ilk konseptteki cozy hissi taşıyor.

#### P1 — Mining Vertical Loop

- [ ] Katı kaynak taşıyan iki asteroid prototipi.
- [ ] **Laser**: ranged, heat, orta verim, küçük alan, kargoya kontrollü aktarım.
- [ ] **Bomb**: ammo, geniş alan, düşük verim, yerde saçılan collectable parçalar.
- [ ] **Drill**: close, yüksek verim, küçük alan, cephanesiz temel kullanım.
- [ ] Asteroid damar/çekirdek/zayıf bölge prototipi.
- [ ] Cargo türleri **solid/liquid/gas**, ayrı limitlerin teknik desteği.
- [ ] Toplama/capacity dolu geri bildirimi.
- [ ] Kısa tur: madeni bul → çıkar → topla → transfer noktasına getir.

**Kabul:** Üç araç aynı işi farklı oynanışla yapıyor ve katı/sıvı/gaz sınıfları veri düzeyinde birbirine karışmıyor.

#### P2 — Basic Combat

- [ ] İlk pirate/scout düşman gemisi.
- [ ] Sabit yönlü temel silah + turret mantığı için taban.
- [ ] Projectile, HP/damage, hasar tepkisi, basit ölüm/scrap üretimi.
- [ ] Düşmanın basit yaklaş, saldır, geri çekil davranışı.
- [ ] Oyuncu silah ve mining ekipmanını aynı gemide taşıyabilir.
- [ ] Loot üretimi; geçici kurtarma/respawn.

**Kabul:** Oyuncu kısa bir çatışmayı bilinçli manevra ve atışla bitirebilir; oyun görsel olarak hâlâ okunaklıdır.

#### P3 — Salvage & Ship Customization

- [ ] Enkaz nesnesi, tarama ve sökülebilir hedef.
- [ ] Tractor/cutter veya uygun araçla ilk parça sökme akışı.
- [ ] Hasarlı modül condition / salvage kararı.
- [ ] Kargo/loot ekranı; altta sürekli HUD inventory olmadan çalışır.
- [ ] Head / Engine / Wings / Body swap için işleyen modüler veri modeli.
- [ ] Universal hardpoint tak-çıkar.
- [ ] Ayrı passive electronics bütçesi.

**Kabul:** Düşmandan/enkazdan kazanılan modül gerçekten oyuncu gemisine takılabilir veya kaynak için parçalanabilir.

#### P4 — Grade & Second Hull

- [ ] `E → ... → SSS` genel kalite şeması.
- [ ] Native grade sabitliği ve grade içi upgrade limitleri.
- [ ] İlk iki farklı gemi gövdesi arasında anlamlı stat/silüet farkı.
- [ ] Her dört ana gemi parçası için görsel upgrade ayrımı.
- [ ] Grade nedeniyle doğal tavanları farklı olan parçalar.
- [ ] Heat/energy/mass/fuel/maneuver trade-off'larını test et.

**Kabul:** Upgrade yapılmış düşük grade model ile üst grade model arasında **kalıcı** ilerleme farkı var; iki gemi yalnızca farklı renkte değil.

#### P5 — Region & Service Loop

- [ ] Farklı kaynak/risk dağılımına sahip en az iki sektör.
- [ ] Radar keşfi, işaretli enkaz, asteroid, tehlike ikonları.
- [ ] Basit istasyon hizmeti: tamir, kargo boşaltma, ekipman/gemi erişimi.
- [ ] Basit kredi ve satış; temel upgrade/maliyet geri bildirimi.
- [ ] Fuel menzil/geri dönüş kararına anlamlı etki eder.

**Kabul:** Oyuncu yalnızca madencilik sahnesini değil, **uç → bul → çıkar/savaş/sök → dön → geliştir** akışını baştan sona oynayabiliyor.

#### P6 — Prototip kapanış / vertical slice

- [ ] 2 oynanabilir farklı gemi, birkaç aktif ekipman, en az bir düşman ve birkaç asteroid/loot türü.
- [ ] Mining + combat + salvage + upgrade tek kayıtta birbiriyle uyumlu.
- [ ] Basit save/load, veri doğrulama, çökme/duplikasyon önleme.
- [ ] FPS/VRAM/CPU profili; başlangıç görsel stilinin oyun içi doğrulaması.
- [ ] Kullanıcı testi: ilk 10–20 dakikada yön bulma, araç öğrenme, ödül hissi.
- [ ] Kaybolan item, kapasite/grade istismarı, softlock kontrolleri.

**Kabul:** Tek başına oynanabilen kısa ama başı ve sonu olan demoda temel ürün kalitesi hissediliyor.

#### P7 — Discovery & Content Expansion

- [ ] Yeni sektör/gezegen çevresi/asteroid biyomları.
- [ ] Ek gemi modelleri ve daha fazla grade varyasyonu.
- [ ] Bounty/keşif/salvage sözleşmeleri (oyuncuyu tek yola zorlamadan).
- [ ] Düşman varyasyonu ve risk/loot farkları.
- [ ] Sıvı/gaz çıkarma içeriğini görsel ve mekanik olarak derinleştirme.

#### P8 — Mother Ship Branch

- [ ] İlk Mother Ship modeli, özgün dış silüet ve iç yerleşim.
- [ ] Uygun hangar/bağlantı alanı; oyuncu gemisinin doklanması.
- [ ] Oda slotları ve ilk işlevsel odalar: storage, repair, salvage/refinery.
- [ ] Grade/native cap, room upgrades, farklı modellerin ayrı planları.
- [ ] Oyuncunun erken/orta oyunda uygun alt grade modeli hedefleyebilmesini destekleyen ekonomi.
- [ ] Daha sonraki içerik hedefi olarak farklı Mother Ship silüetlerine genişleme.

#### P9+ — İleri sistemler / karara bağlı

- [ ] Crew/habitat görselleştirme ve hafif işlevler.
- [ ] Birden fazla gemi saklama ve sınırlı görev atama.
- [ ] Daha büyük galaksi, farklı sistemler ve ileri seyahat.
- [ ] Gelişmiş düşmanlar, boss, nadir teknoloji.
- [ ] Hafif oda bazlı otomasyon ve görsel üretim/işleme.
- [ ] Modüler içerik araçları ve genişletilmiş oyunsal varyasyon.


### 18. Test planı ve kabul kriterleri

| Alan | Kritik senaryo | Başarı koşulu |
|---|---|---|
| Uçuş | Boş/kısmen dolu kargoyla dön, boost et, drift yap | Kontrol hissi tutarlı ve okunaklı |
| Gemi anatomisi | Head/Body/Engine/Wings değiştir | Model socket'leri korunur; statlar yeniden hesaplanır |
| Grade | E gövdeyi limitine kadar yükselt | Grade değişmez, kendi tavanını aşamaz |
| Hardpoint | Mining ve savaş modülünü iki farklı noktada dene | Class/type kilidi yok; bütçeler uygulanır |
| Electronics | Aktif slot doluyken pasif modül tak | Ayrı elektronik bütçesi kullanılır |
| Laser | Küçük maden hedefinden uzakta kaynak çıkar | Orta verim, küçük alan, uygun depoya aktarım |
| Bomb | Birden çok nodu patlat | Alan geniş; verim düşük; yerde toplanacak parçalar oluşur |
| Drill | Yakından damar çıkar | Yüksek verim, kısa erişim ve net temas hissi |
| Storage | Uygun gaz deposu olmadan gaz topla | İşlem doğru sebeple reddedilir |
| Salvage | Hasarlı modülü sök, tak, sat | Condition ve grade korunur |
| Combat | Düşmanı yok et, kaçın, loot al | Kontrol ve feedback anlamlı |
| UI | Mining/gameplay esnasında | HP/Fuel + aktif bar + sol alt minimap, sürekli inventory yok |
| Recovery | Gemi yok edilince | Softlock/kalıcı telafisiz kayıp olmadan döngüye dönülür |
| Save/load | Farklı gemi + item upgrade + kargo | Veri kaybı ve duplikasyon yok |
| Performance | Kalabalık asteroid alanı | Belirlenen hedef donanımda akıcı deneyim; bütçe sonradan sayısallaştırılır |


### 20. Hâlâ açık kararlar / ajanın kendi kendine kesinleştirmemesi gerekenler

| Konu | Mevcut durum | Varsayılan üretim yaklaşımı |
|---|---|---|
| Oyun motoru | Karar yok | Motor bağımsız prototip ve veri planı; uygulama öncesi karar |
| Kesin oyun adı | `Project Space` / `Space Miner` çalışma adı | Geçici adla devam |
| Tam gemi kataloğu | Çok farklı model isteniyor, sayı kilitli değil | Starter + ikinci farklı hull |
| Tam Mother Ship kataloğu | Çok model ve farklı interior gerekli | P8 ilk model, sonra genişleme |
| Oynanış kamera açısı | Daha top-down, 2.5D | Playtest ile belirlenir |
| Input şeması | Nihai onay yok | Prototipte değiştirilebilir |
| Fuel/Energy/Heat sayıları | Kesin değil | `TBD`, geçici balans |
| Grade istatistik çarpanları | Sıra E–SSS kesin, sayılar değil | Tek balans tablosu, karara açık |
| Resource/material adları | Katı/sıvı/gaz sınıfları kesin, tam liste değil | Geçici isimlerle prototiple |
| Loot box, düşme oranı | Loot çeşitliliği isteniyor; RNG şekli açık | Veri altyapısı, monetizasyon varsayma |
| Kargo grid boyutu | Geçmişte 6×7 geçti, kilitli değil | Ayrı ekran, modüler boyut |
| Asteroid hasar tekniği | Araç davranışları kesin; kesme algoritması değil | Node/fracture yaklaşımı |
| Uzay haritası/gate/warp | Son kurallar belirlenmedi | İlk etap tek sektör |
| Crew AI/maaş/offline | İleri fikirler | Kapsam dışı |
| Mother Ship başlangıç fiyatı | Erken erişilebilir alt model hedefi var | Balans daha sonra |
| Görevler/factions/bosslar | Aday fikirler | İlk döngüyü beklesin |
| Save ve dağıtım detayları | Teknik karar yok | En azından P6'da sağlam save/load |


### 21. Modelleme ve kodlama ajanına başlangıç görevi

> **HEDEF:** Bu tasarımı tam oyuna çevirmeye kalkma. Önce küçük, yüksek kaliteli, test edilebilir **P0/P1** ürettir.

#### İlk uygulama emri

1. `GAME_PLAN.md` dosyasını bağlayıcı tasarım kaynağı olarak oku; `[ÖNERİ]` veya `[AÇIK]` alanları onaylanmış kurala çevirme.
2. Mevcut repo/asset/kod varsa önce incele; varsa hiçbir çalışmayı sebepsiz silme veya ikinci bir altyapı kurma.
3. Starter ship için basit low-poly **Body + Head + Wings + Engine** asset hiyerarşisi oluştur.
4. Hafif 2.5D top-down kamera ve sürüş prototipi yap.
5. Sol üst HP/Fuel, sol aktif araç barı, sol alt minimap ekle; inventory bar ekleme.
6. İki okunaklı asteroid prototipi ve ilk Laser işlevini kur.
7. Laser → kaynak çıkar → doğru cargo tipine koy → kapasite bildir zincirini çalıştır.
8. Ardından Bomb ve Drill farklarını ekle; yalnızca görsel olarak aynı üç silah yapma.
9. Oyun içinde grade, modül ve hardpoint sistemi için data tanımlarını **erken** kur; tam içerik üretimini ertele.
10. Küçük demo üzerinde profil/test yap; hareket ve okunabilirliği değerlendir.
11. Gerçek sonuçları `PROGRESS.md` veya benzeri kısa dosyada kayıt altına al; tamamlanmayanı tamamlandı diye yazma.

#### Bitmiş sayılma koşulu

```text
[ ] Starter ship sürülebiliyor
[ ] Kamera top-down ve görsel stil cozy low-poly
[ ] HP + Fuel + sol aktif ekipman + sol alt minimap doğru
[ ] 2 farklı asteroid düzgün okunuyor
[ ] Laser/Bomb/Drill davranışları farklı
[ ] En az bir kaynak çıkarılıp doğru depo tipine gidiyor
[ ] Geminin dört ana parçası veri/model seviyesinde ayrılmış
[ ] Hardpoint sistemi class kilidi getirmiyor
[ ] Oyun sahnesi düşük karmaşıklıkta akıcı
[ ] Aynı projeye ikinci gemi eklemek mevcut kodu kopyalamayı gerektirmiyor
```
