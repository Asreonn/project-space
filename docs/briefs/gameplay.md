# Brief — Gameplay Designer

**Sahip olduğun yollar:** `scripts/ship/**`, `scripts/mining/**`, `scripts/combat/**`, `scripts/loot/**`, `scenes/ship/**`, `scenes/world/**`, `scenes/enemies/**`, `scenes/pickups/**`, `data/**` (değerler; şema Engineer'da).
**Branch öneki:** `gameplay/` · **Review:** Godot Engineer (+ Game Designer his/kapsam için).

## Rolün

Oyunun **hissi** senin: uçuş, madencilik, toplama, çatışma. "Daha fazla özellik kötü hissedilen uçuşu kurtaramaz" (§2.3). Her değeri veri dosyasından okut, kodda sihirli sayı bırakma.

## [KESİN] kararlar

- 2.5D top-down refleks/konum çatışması; okunabilir, kurşun cehennemi değil (§9.1).
- Flying Speed (Engine) ve Maneuver Speed (Wings) **ayrı** statlar; Head → Damage/Mining power, Body → Carry Capacity (§4.2, PDF).
- Fuel Capacity/Fuel Rate tek bir parçaya zorunlu bağlanmaz (PDF "None") (§4.2).
- Energy (aktif) ve Electronics/Passive Capacity ayrı değişkenler (§4.2, §4.4).
- Universal hardpoint, sınıf/tip kilidi yok (§4.4). Gemi hem silah hem maden aracı taşıyabilir (§9.1).
- Laser: uzak, orta verim, küçük alan, enerji+ısı, kapasite varsa doğrudan kargoya (§6). Bomb/Drill kuralları da değişmez (M2).
- Solid/liquid/gas ayrı kapasite; uygun tank yoksa gaz toplanamaz (§7.1).
- Oynanış HUD'unda sürekli envanter yok (§7.3).
- Ölümde recovery; prototipte maliyetsiz respawn [ÖNERİ] (§9.3).
- TBD değerleri kalıcı balans gibi uydurma → `balance_prototype` işaretle (§15.3).

## M1 görevlerin

1. **Graybox uçuş** (`scripts/ship/ship_controller.gd`, `scenes/ship/player_ship.tscn`): `RigidBody3D` veya `CharacterBody3D` (Engineer ile karar), XZ düzlemine kilitli. Hızlanma/yavaşlama, dönüş, fren, boost (fuel tüketir), hafif drift/inertia. Kargo kütlesi manevrayı ölçülü etkiler.
2. **Kontrol şeması A/B:** (A) WASD hareket + fareye dönük burun, (B) W/S itki + A/D dönüş. İkisi de `data/` ayarıyla seçilebilir; playtest Game Designer ile (§3.2 [AÇIK]).
3. **Kamera** (`scenes/world/game_camera.tscn`): yumuşak takip, hıza bağlı hafif look-ahead, zoom (wheel). Perspektif FOV ~30–40 ve ortografik modları — seçim playtest ile.
4. **Asteroid alanı** (`scenes/world/asteroid_field.tscn`): seed'li yerleşim, 2–3 tip, yavaş dönüş; `AsteroidResourceNode` (surface + vein node'u) (§6.1).
5. **Laser madencilik** (`scripts/mining/mining_laser.gd`): ray/shape cast, menzil, ısı birikimi/soğuma, aşırı ısınma kilidi, node HP → kaynak üretimi → `CargoStorage.solid` → `cargo_full` sinyali.
6. **Kargo** (`scripts/loot/cargo_storage.gd`): solid/liquid/gas ayrı limit, kabul/ret nedeni döner (ör. `NO_GAS_TANK`). Birim test (tests/).
7. **Pickup** (`scenes/pickups/pickup.tscn`): kopan parça/hurda; menzilde magnet çekimi, toplanınca sinyal; havuzlanır.
8. **Düşman** (`scenes/enemies/enemy_drone.tscn`): durum makinesi idle → approach → attack → retreat; basit projectile; ölünce scrap pickup. Oyuncu silahı: basit sabit yönlü blaster (fire_primary).
9. **Prototip verisi** (`data/ships/starter_shuttle_01.tres`, `data/modules/laser_mk1.tres`, `data/resources/*.tres`, `data/enemies/drone_01.tres`): tüm sayılar `balance_prototype`.
10. Hasar/ölüm/respawn akışı; softlock yok.

## Kabul

ROADMAP M1 kabul kriterleri içindeki uçuş, laser zinciri, pickup, düşman maddeleri + `tests/` altında kargo testleri.

## Referans görseller

- `docs/references/02_Gameplay_Mood/01_Starter_Mining.png` (laser madencilik hissi, ölçek), `07_Golden_Mining.png`, `04_Blue_Crystal_Mining.png`.
- `01_Modeling_Atlases/03_Gameplay_Resources_Modules.png` (kaynak/modül çeşitleri — isimler kural değil).
- `01_Modeling_Atlases/04_TopDown_HUD_Ships_Items_Enemies.png` (top-down ölçek, düşman çeşitleri).
- PDF: `docs/references/03_Source/spacegamev1.pdf` (madencilik + stat kuralları).


---

## Ek — GAME_PLAN.md'den ilgili bölümler (birebir)

> Aşağıdaki metin `docs/GAME_PLAN.md` v0.1'den kopyalandı; çelişkide GAME_PLAN + `docs/DECISIONS.md` geçerlidir. **Motor artık Godot 4** (D-001) — §3.3/§20'deki "motor açık" ifadeleri kapandı.


### 2. Tasarım önceliği ve ana oynanış döngüleri

#### 2.1 Kısa oturum döngüsü

```text
İlginç nokta tespit et
       ↓
Oraya uç / yaklaş / tara
       ↓
Madencilik, salvage, çatışma veya keşif yap
       ↓
Kaynak / modül / hurda / bilgi elde et
       ↓
Kargo ve risk kararını ver
       ↓
Geri dön, aktar, işle, tamir et, sat veya tak
       ↓
Gemini geliştir → daha uzak / zor bölgelere açıl
```

#### 2.2 Paralel oyun tarzları

| Yaklaşım | Oyuncunun yaptığı | Temel ödül |
|---|---|---|
| Madenci | Asteroid tarar, damar/çekirdek bulur, Laser/Bomb/Drill seçer | Katı/sıvı/gaz kaynak, nadir maden |
| Salvager | Terk edilmiş gemi/enkaz bulur, parça söker ve taşır | Kullanılabilir modül, hurda, bileşen |
| Savaşçı | Korsan, drone veya tehlikeli hedefle çatışır | Ganimet, kredi, hasarlı teknoloji |
| Explorer | Yeni bölgeler, sinyaller, anormallikler ve kaynak kümeleri keşfeder | Keşif verisi, erişim, özel loot |
| Karma | Her birinden bir miktar yapar | Esnek, oyuncuya özgü ilerleme |

**[KESİN]** Hiçbir tarz bir gemiye kapatılmaz. Geminin mevcut parçaları, donanımı, grade'i ve sınırları o tarzda ne kadar başarılı olduğunu belirler.

#### 2.3 Tasarımın kalite sırası

1. Kontrol hissi / kamera / okunabilirlik.
2. Tek gemiyle tatmin edici uçuş, kısa çatışma ve loot.
3. Madencilik araçlarının hissedilir farkı.
4. Enkaz ve parça sökme.
5. Grade, ekipman, ekonomi, daha iyi gemi hedefi.
6. Bölgesel keşif, görevler ve Mother Ship genişlemesi.

**Üretim ilkesi:** Daha fazla özellik, kötü hissedilen bir uçuş sistemini kurtaramaz.


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


### 6. Madencilik: üç zorunlu yöntem

Bu bölümün mekanik çekirdeği **doğrudan `spacegamev1.pdf` sayfa 1** kaynağına dayanır.

| Yöntem | Menzil | Verim | Alan | Tüketim / gereksinim | Toplama davranışı |
|---|---|---|---|---|---|
| **Laser** | Uzak | Orta | Küçük | Enerji, ısı üretimi | Uygun kapasite varsa çıkarılan malzeme doğrudan kargoya aktarılabilir |
| **Bomb** | Uzak | Düşük | Büyük | Cephane; temasla veya isteğe bağlı patlama | Parçalar çevreye saçılır; yaklaşarak toplama gerekir |
| **Drill** | Yakın | Yüksek | Küçük | Yaklaşma/temas ve çalışma bütçesi | Uygun kapasite varsa malzeme doğrudan kargoya aktarılabilir |

**Laser:** Uzaktan ışın gönderir; hedefi ısı/erime mantığı ile kazır. Özellikle kontrollü damar çıkarma için kullanılır.

**Bomb:** Atılan bomba çarpmayla veya seçilen tetikleme koşuluyla patlar; büyük alan açar fakat ekonomik verim düşüktür. Kaynak saçılımı oyuncuya fiziksel toplama işi yaratır. Sınırlı cephane kullanır.

**Drill:** Yakından uygulanır ve yüksek verimlidir. PDF tasarımında sınırsız/cephanesiz çalışma yönü bulunur; fakat risk, yakıt, ısınma, süre ve yakınlık hâlâ oynanış maliyetleri olabilir. Bu maliyetlerin tam sayısı açık.

#### 6.1 Asteroid çıkarma modeli

**[HEDEF]** Sınırsız, serbest voxel/mesh kesimi şart değil. Üretim dostu yapı:

1. **Surface layer:** yüzeyden parça çıkarma; Laser için belirgin geri bildirim.
2. **Vein/precision nodes:** konsantre maden damarı / zayıf bölge; araç tercihini ödüllendirir.
3. **Core/fracture nodes:** kontrollü kırılma/patlatma; Bomb ve Drill'e taktiksel kullanım.
4. **Debris / loot release:** kontrollü fiziksel parçalar, toplama akışı.

Bu katmanlar eski geniş tasarımdaki teknik öneridir; **güncel PDF'deki Laser/Bomb/Drill kurallarını değiştiremez**.

#### 6.2 Madenciliğin hissi

- Lazer temasında sıcak iz / ışıma ve ufak parçacıklar.
- Drill çalışırken gemi burnunda titreşim, küçük kopmalar ve ritmik ilerleme.
- Bomb'da büyük fakat düşük detaylı parçalanma; kaynak küreleri kolay seçilmeli.
- Taşıma kapasitesi dolunca üretim/loot toplama net biçimde durur veya erişilebilir artık parçalar dünyada kalır.
- **[HEDEF]** Cazip madenleri bulmak, çıkarmak ve güvenle geri getirmek tek başına eğlenceli bir kısa görev olmalı.


### 7. Kaynak türleri, envanter ve taşıma

#### 7.1 Fiziksel kaynak sınıfları

**[PDF — sayfa 2]** Uzayda toplanan temel kaynaklar **katı, sıvı ve gaz** olarak ayrılır. **Her tip için uygun özel kapasite** gerekir.

- **Solid / Katı:** cevher, metal, kristal, fiziksel hurda.
- **Liquid / Sıvı:** ayrı depolama türünü kullanan sıvılar (**madde isimleri henüz kilitli değil**).
- **Gas / Gaz:** ayrı depolama türünü kullanan gazlar (**gaz türleri henüz kilitli değil**).

Yalnızca “toplam kargo 100” yaklaşımı doğru değil; örneğin katı deposu boş olsa bile uygun tank yoksa gaz toplanamaz.

#### 7.2 Kargo ve kapasite

- **Body** genel hacim kapasitesinin ana girdisi.
- Solid, liquid, gas için ayrı kapasiteler / konteynerler.
- Modül ve enkaz parçaları da kütle/hacim oluşturabilir.
- Kapasite aşımına UI'da erken ve açık uyarı verilir.
- Taşınan yük uçuş üzerinde ölçülü etki yaratır.
- **[AÇIK]** Eski sohbetlerde bir gemi için **6×7 slot inventory** gündeme geldi; envanterin nihai grid boyutu veya tüm gemiler için aynı olması kesin karar değil.

#### 7.3 Toplama ilkeleri

- Bazı malzeme çıktıları otomatik çekim/ışın aktarımı ile kargoya girebilir.
- Bomb ile saçılan kaynaklar, enkaz parçaları ve büyük loot için yaklaşma/tractor/hakimiyet gerektiren toplama anları korunur.
- Materyal miktarı, grade, hasar/condition ve saklama koşulu veri modelinde ayrı tutulur.
- Kargo ekranı açıldığında filtreleme (katı/sıvı/gaz/modül/hurda) ve hızlı aktarma düşünülmeli; **oynanış HUD'ında sürekli envanter barı yoktur**.


### 9. Savaş, düşmanlar ve hayatta kalma

#### 9.1 Savaş yönü

- **[KESİN]** 2.5D top-down refleks/konum alma çatışması.
- Sabit silah + turret hibriti.
- Menzil, hareket, dönüş, projectile hızı, ısınma, enerji ve silah grade'i farklı oyun tarzları yaratır.
- Oyuncu gemisi silahlanırken madencilik ekipmanlarını tamamen bırakmak zorunda değildir; hardpoint özgürlüğü esastır.
- **[HEDEF]** Rastgele kurşun cehennemi değil, okunabilir ve keyifli uzay karşılaşmaları.

#### 9.2 Düşman aileleri

Aşağıdakiler **görsel referans ve ilk tasarım önerileri**; son düşman kataloğu değildir:

| Aile | İşlev | İlk prototip? |
|---|---|---|
| Küçük pirate/scout | Kovalar, tek veya kısa seri ateş eder | Evet, bir örnek |
| Miner-raider | Kaynak bölgesinde taciz/loot riski | Daha sonra |
| Drone | Hafif çevik hedef | Daha sonra |
| Guard/turret | Alan tutma / sabit savunma | Daha sonra |
| Elite/boss | Özel saldırı paterni, nadir loot | Genişleme |

**[KESİN]** Korsan baskınları ve tehlike duygusu dünyada bulunabilir; ama erken oyunda devasa faction/filo sistemi kurmak zorunlu değil.

#### 9.3 Kaybetme ve recovery

**[KESİN]** Gemi imhasında **sigorta/kurtarma (insurance/recovery)** yaklaşımı olmalı. Tüm emeği cezalandıran koşulsuz kalıcı kayıp temel tasarım değil.

- Kurtarmanın maliyeti, hangi ekipmanın korunacağı ve kargonun ne kadarının risk altında olduğu **[AÇIK]**.
- **[ÖNERİ]** Prototipte maliyetsiz/kolay respawn; sistem olgunlaşınca önceden anlaşılır recovery bedeli.


### 17. İlk demo için net içerik sınırı

**İlk oynanabilir prototipte olması gerekenler:**

- **Bir starter ship**; ayrı Head/Engine/Wings/Body mimarisi.
- Bir pastel uzay/nebula bölgesi.
- 2–3 basit asteroid görsel varyasyonu.
- Laser/Bomb/Drill prototipleri; malzeme toplama.
- Başlangıçta birkaç kaynak örneği; teknik olarak solid/liquid/gas ayrımı.
- Can/fuel, solda aktif modül barı, sol altta radar.
- Kısa return/transfer akışı; daha sonra bir küçük enemy/salvage parçası.

**İlk prototipte gerek olmayanlar:**

- Onlarca model gemi veya tüm E–SSS grade içerik kataloğu.
- 5–7 Mother Ship, tam oda yerleşimi ve mürettebat AI'ı.
- Prosedürel koca galaksi, büyük faction ilişkileri ve flotilla komut sistemi.
- Büyük questline, kompleks ekonomi, ticaret simülasyonu.
- Hardcore survival, kalıcı tüm eşya kaybı.
- Ultra gerçekçi fizik, voxel asteroid tahribatı ve yoğun production animation sistemi.

**Kural:** İçeriği küçült, sistemin **büyütülebilir mimarisini** küçültme. P0'dan itibaren yeni içerik veriyle eklenebilir olmalı.


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
