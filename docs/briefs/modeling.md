# Brief — 3D Modeler (Blender)

**Sahip olduğun yollar:** `art/**` (`.blend` kaynakları, LFS), `assets/models/**` (`.glb`, LFS), `assets/textures/**`.
**Branch öneki:** `model/` · **Review:** Godot Engineer (+ Game Designer stil onayı). Asset PR'larında üstten + 3/4 ekran görüntüsü zorunlu.
**Ayrıca oku:** [`docs/README_Modelleme_Ajani_TR.md`](../README_Modelleme_Ajani_TR.md) (referans paketinin kendi modelleme README'si; yollar artık `docs/references/` altında).

## Rolün

Referans görselden (2D konsept) **low-poly, cute/cozy** 3D modeller çıkarırsın — Blender 5.2 LTS (box'ta `blender` CLI + Blender MCP). Detay yerine silüet, renk ve okunabilirlik (§1, §14.1).

## [KESİN] kararlar

- Low-poly, sevimli, yumuşak formlu; foto-gerçekçi materyal ve aşırı kompleks model yok (§14.1).
- Starter gemi: küçük, kırık-beyaz/kremsi gövde, yumuşak turuncu detaylar, mavi motor izi (README_Modelleme).
- Gemi **4 ayrı parça**: `Head_*`, `Body_*`, `Engine_*`, `Wings_*` + `Hardpoint_*` boşları (§4.3, §14.2).
- Grade varyantı yalnız renk değişimi **değil**; ek parça/oran/silüet farkı (§4.3, §14.2.4).
- Aynı modeli renk değiştirerek çoğaltma yok (§4.3).
- Maden, düşman ve oyuncu gemileri birbirine karışmamalı (§14.2.5).
- Referanslar tasarım yönüdür, stat/lore değil (§14.2.6). Yakıt tankı parçası zorunlu slot değil (README).

## Teknik sözleşme (AGENTS.md §5)

- Blender Z-up; **burun +Y** (Top view'da yukarı). glTF export: `+Y Up` açık, Apply Modifiers açık → Godot'ta burun −Z.
- 1 birim = 1 m. Starter gemi ~3 m boy (öneri). Pivot = kütle merkezi, Z=0 düzlemi.
- Obje adları: `Head_starter_01`, `Body_starter_01`, `Engine_starter_01`, `Wings_starter_01`; boşlar `Hardpoint_L`, `Hardpoint_R`, `Hardpoint_Nose`, `FX_EngineTrail_0`.
- Dosyalar: `art/blender/ships/starter_shuttle_01.blend` → `assets/models/ships/starter_shuttle_01.glb`. Parçaları ayrı swap için ayrıca `head_starter_01.glb` vb. de export edilebilir (Engineer ile karar).
- Materyal: flat/low-poly; 1 adet küçük palet texture (ör. 64×64 renk paleti) veya vertex color. Emissive bölgeler ayrı materyal slotu (VFX glow için). Materyal adı `M_<ad>`.
- Poligon bütçesi [ÖNERİ — §14.4 AÇIK]: starter gemi ≤ 2–3k tri, asteroid 150–800 tri, pickup ≤ 200 tri, düşman ≤ 2k tri.
- Her asset için: üstten (ortografik) + 3/4 render PNG'si PR'a ekle; gameplay ölçeğinde (kamera ~30 m yükseklik) silüet testi.
- `.blend1` commit etme (gitignore'da).

## M1 görevlerin (öncelik sırası)

1. **Starter ship blockout** (P0, Paket A/B): 4 parça + 3 hardpoint + motor izi noktası; üstten okunaklı.
2. **Laser modülü** (`MiningLaser_mk1`): ince ısı başlığı, hardpoint'e oturur (README: Laser ince ısı başlığı; Bomb yuvarlak lançer; Drill kısa konik matkap — Bomb/Drill M2).
3. **3 asteroid**: sıradan, metalik/cevherli, kristalli — fasetli büyük kaya + seçilebilir maden çıkıntıları (ayrı mesh, laser hedefi). 2–3 LOD gerekmez.
4. **3 pickup**: solid (cevher parçası/kristal), liquid (damla kapsül), gas (basınç tüpü) — M1'de solid kullanılır.
5. **1 düşman** (drone/scout — D-004 kararına göre): oyuncudan silüet ve renkle ayrışan (kırmızı/koyu aksan).
6. (Opsiyonel) uzak gezegen / halka — VFX ile birlikte arka plan.
7. Starter ship final + E/D grade için Head'in iki varyantı (morfolojik fark).

## Kabul

- Godot'ta import edildiğinde ölçek/yön/pivot doğru (Engineer kontrol eder), hardpoint boşları Node3D olarak geliyor.
- Normal zoom'da gemi, asteroid, düşman, pickup ayırt ediliyor.

## Referans görseller

- **Ana:** `docs/references/01_Modeling_Atlases/02_Ships_Grades_Environments.png` (gemi tipleri + grade varyasyonları), `04_TopDown_HUD_Ships_Items_Enemies.png` (üstten gemiler, madenler, item'lar, düşmanlar, istasyon), `03_Gameplay_Resources_Modules.png` (modüller/kaynaklar), `01_Overall_Art_Direction.png`.
- **Ölçek/his:** `02_Gameplay_Mood/01_Starter_Mining.png` (starter gemi + asteroid), `04_Blue_Crystal_Mining.png`, `10_Crystal_Exploration.png` (kristaller), `08_Salvage_Debris.png` (enkaz — M4).
- Atlaslardaki "Tier 1/2/3", Fighter/Explorer/Miner/Salvager başlıkları **örnek build**; sınıf ağacı kurma.


---

## Ek — GAME_PLAN.md'den ilgili bölümler (birebir)

> Aşağıdaki metin `docs/GAME_PLAN.md` v0.1'den kopyalandı; çelişkide GAME_PLAN + `docs/DECISIONS.md` geçerlidir. **Motor artık Godot 4** (D-001) — §3.3/§20'deki "motor açık" ifadeleri kapandı.


### 1. Oyun vizyonu ve oyuncu fantezisi

**[KESİN]** Oyuncu kendi gemisiyle geniş ve yaşanabilir hissi veren uzayda özgürce dolaşır; savaş alanlarını, enkazları, asteroid kümelerini ve ilginç bölgeleri keşfeder. Kaynak çıkarır, bulduğu parçaları kurtarır, ganimet toplar, gemisini geliştirir, gerektiğinde savaşır, daha uzak bölgelere erişir ve zamanla etkileyici bir **Mother Ship** sahibi olabilir.

Oyunun kimliği üç eksende şekillenir:

1. **Gemi kullanmak başlı başına eğlenceli olmalı:** hareket, dönüş, hızlanma, drift, boost, isabetli ateş, dar alanlarda manevra.
2. **Bulduğun şeyin değeri ve kullanım alanı olmalı:** maden, hurdadan sökülen motor, nadir modül, yakıt, tarif, gövde parçaları veya ticari malzeme.
3. **Gelişimin görünür olmalı:** başlangıç gemisinden daha yetenekli veya farklı eğilimli gemilere, modüllere, gemi üstü donanıma ve sonunda modeline özgü iç mekânı olan Mother Ship'e geçiş.

**Oyunu bir fabrika simülasyonuna dönüştürme.** Madencilik, salvage, savaş, gemi toplama ve modüler kişiselleştirme merkezde; otomasyon/üretim ve mürettebat bunları destekler.

#### Oyunun tonu

- **[KESİN]** Top-down'a yakın **2.5D**, 3D low-poly modeller; sevimli, sıcak, sade formlar.
- **[KESİN]** Genel akış **cozy / tatlı / chill** olmalı. Savaş ve tehlike mümkün ama atmosfer aşırı sert, kirli, karanlık veya hipergerçekçi olmamalı.
- **[HEDEF]** İster kısa bir madencilik turu, ister enkaz arama, ister riskli çatışma yapılabilsin.
- **[HEDEF]** Ekran görüntüsündeki nesneler az poligonla, mesafeden hemen anlaşılabilsin. Detay yerine silüet, renk ve iyi animasyon önceliklidir.

#### Kapsam dışı kimlikler

- **[İPTAL]** Eski solarpunk farm/factory oyun konsepti.
- **[İPTAL]** İlk önerilerdeki sabit shop → colony → hub ana döngüsü.
- **[ERTELENDİ]** Büyük filoları mikro yönetmek, devasa zorunlu mürettebat simülasyonu, tam fabrika otomasyonu ve ağır survival bürokrasisi.
- **[KESİN]** Gemi eğilimleri sert meslek/sınıf kilitleri **değildir**.


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


### 14. Görsel tasarım / 3D modelleme rehberi

#### 14.1 Art direction

**[KESİN]**

- 2.5D top-down, low-poly, cute/cozy/chill.
- Silüet odaklı, okunabilir gemi ve asteroid biçimleri.
- Küçük beyaz/kremsi başlangıç gemisi, seçilebilir kontrast renk vurgusu.
- Asteroid: basit fasetli büyük kaya, seçilebilir maden çıkıntıları.
- Ortam: koyu boşluk + düşük yoğunluklu renkli nebula, yıldızlar, uzaktaki büyük gezegenler.
- VFX: yumuşak motor izi, kısa laser çizgisi, küçük loot parçacıkları.
- Foto-gerçekçi malzeme, aşırı kompleks model, kalabalık HUD, ağır partikül sistemi hedef değil.

#### 14.2 Gemi modelleme sistemi

İlk gemi için ayrı model bileşenleri:

- `Head_*` — ön burun, saldırı/madencilik eğilimi.
- `Body_*` — merkez gövde, kargo kapasitesi karakteri.
- `Engine_*` — arkada itki geometrisi.
- `Wings_*` — iki yanda dönüş/manevra karakteri.
- `Hardpoint_*` — takılabilir evrensel cihaz pozisyonları.
- `Weapon_*`, `MiningLaser_*`, `MiningBomb_*`, `MiningDrill_*` — bağımsız aktif donanım modelleri.

**Modelleme ajanı için bağlayıcı gereksinimler:**

1. Her parçayı diğerinden ayrılabilir sahne/asset haline getir.
2. Gemi merkezi, ileri yön, pivot ve hardpoint anchor'larını standartlaştır.
3. Üstten görünüş, kabaca 3/4 yakın açı ve gameplay ölçeğinde silüet kontrolü yap.
4. Grade varyantlarını sadece materyal rengi değişikliği olarak geçiştirme; ek parça/proporsiyon/silüet dili kullan.
5. Sahnedeki maden, düşman ve oyuncu gemileri birbirine karışmasın.
6. Referans panoları **tasarım yönüdür**, doğrudan uygulanacak stat tabloları/lore kataloğu değildir.

#### 14.3 İlk oluşturulacak referans paketleri

| Paket | İçerik | Öncelik |
|---|---|---|
| A — Starter Gameplay | 1 başlangıç gemisi, 2 asteroid, laser, HUD, arka plan | P0 |
| B — Ship Modular Kit | Head, Body, Engine, Wings, hardpoint ve 2 görünüş | P0 |
| C — Mining Kit | Laser/Bomb/Drill, üç kaynak sınıfı ve loot gösterimi | P1 |
| D — Salvage Kit | Hasarlı gemi/enkaz, sökülen parça, tractor/cutter | P3 |
| E — Enemy Kit | Basit pirate/scout, atış ve hasar tepkileri | P2 |
| F — Grade Variants | E/D/C... için morfolojik örnekler | P4 |
| G — Mother Ship | Farklı silüet, hangar, oda ve interior modülleri | P8 |

Görsel üretim sırasında oluşturulan `SpaceMiner_Visual_References.zip` ve `SpaceMiner_Reference_Overview.png` **sanat yönü girdisi** olarak kullanılabilir; karar kaynağı el yazısı PDF ve bu belgedir.

#### 14.4 Okunabilir ölçek bütçesi

- Normal gameplay zoom'unda başlangıç gemisi, asteroid, düşman ve loot ayırt edilebilmeli.
- Çok küçük fiziksel detayı UI ya da parlayan outline ile sürekli telafi etme.
- Grade yükseldikçe **şekil** çeşitlenir fakat kamera yakınlaştırılması zorunlu olmaz.
- **[AÇIK]** Mutlak poligon sayısı, texture çözünürlüğü ve performans bütçesi motor/cihaz testinden sonra sabitlenir.
