# Brief — VFX Engineer

**Sahip olduğun yollar:** `assets/shaders/**`, `assets/materials/**`, `assets/vfx/**`, `scenes/vfx/**`, `scripts/vfx/**` (+ `WorldEnvironment`/post-process kaynakları `scenes/vfx/environment_*.tres`).
**Branch öneki:** `vfx/` · **Review:** Godot Engineer (+ Game Designer stil). Görsel PR'larda önce/sonra ekran görüntüsü veya GIF zorunlu.
**Kaynaklar:** [docs/TOOLS.md](../TOOLS.md) → "VFX / shader kaynakları" (godotshaders.com, GDQuest, Effekseer, Material Maker, Kenney particle pack…). Lisansı kontrol et, CREDITS.md'ye yaz.

## Rolün

"Cozy ama tavan" görünüm: zengin ama ölçülü renk, yumuşak glow, okunaklı efektler. Godot 4 Forward+ (glow, SSAO/SSIL, volumetric fog, SDFGI opsiyonel) + `GPUParticles3D` + spatial/canvas shaderlar.

## [KESİN] kararlar

- VFX: yumuşak motor izi, kısa laser çizgisi, küçük loot parçacıkları (§14.1).
- Ortam: koyu boşluk + düşük yoğunluklu renkli nebula, yıldızlar, uzak büyük gezegenler (§14.1).
- Foto-gerçekçi materyal, ağır partikül sistemi hedef değil (§14.1). Binlerce pahalı şeffaf efekt zorunlu değil (§3.3).
- Madencilik hissi (§6.2): laser temasında sıcak iz/ışıma + ufak parçacık; drill'de titreşim/kopma; bomb'da büyük ama düşük detaylı parçalanma, kaynak küreleri kolay seçilir.
- Efektler okunabilirliği bozmamalı; UI/outline ile sürekli telafi yok (§14.4).

## Teknik

- Post-process zinciri: `WorldEnvironment` → tonemap (AgX/Filmic), glow (HDR threshold ~1.0–1.2, emissive'ler > 1), hafif color correction (LUT / adjustments), vignette + çok hafif chromatic aberration (screen shader, `scenes/vfx/post_fx.tscn`), opsiyonel film grain ≤ çok düşük.
- Arka plan: nebula shader (fbm noise, 2–3 katman parallax) — sky veya büyük quad; yıldızlar GPU particles veya shader. Uzak gezegen: basit mesh + fresnel atmosfer shader.
- Low-poly materyal: `assets/materials/m_lowpoly_base.tres` (flat shading/toon ramp, rim light), emissive varyant.
- Performans: efekt başına parçacık bütçesi, `GPUParticles3D` pooling (Engineer'ın pool'u), şeffaflık katmanı sınırlı. 1080p'de orta GPU'da 60 FPS hedefi.
- Effekseer (opsiyonel): `EffekseerForGodot4` addon'u ancak Engineer onayıyla `addons/`'a eklenir; aksi halde native GPUParticles3D.

## M1 görevlerin

1. `environment_space.tres` + post-process zinciri (önce/sonra karşılaştırma).
2. Nebula + yıldız + uzak gezegen arka planı (parallax hissi top-down kamerada).
3. Motor izi (trail mesh/ribbon veya particles), boost'ta yoğunlaşma.
4. Laser ışını shader'ı (scroll eden çekirdek + glow), temas noktasında ısıma decal/emissive + kıvılcım.
5. Asteroid: maden damarı hafif emissive/rim; hasar alınca kızarma.
6. Pickup: parıltı + toplanınca küçük "pop".
7. Hasar flaşı, kalkan/hull vuruşu, düşman patlaması (debris + flash + smoke puff, cozy renkler).
8. Hafif screen shake / hit-stop önerisini Gameplay'e sun (parametreli).

## Kabul

M1 sahnesi `02_Gameplay_Mood/01_Starter_Mining.png` atmosferine yakın; tüm efektler açıkken 60 FPS; efektler gemi/asteroid/düşman/pickup okunabilirliğini bozmuyor.

## Referans görseller

- Atmosfer/renk: `docs/references/02_Gameplay_Mood/01_Starter_Mining.png`, `04_Blue_Crystal_Mining.png`, `07_Golden_Mining.png`, `10_Crystal_Exploration.png`, `06_Cargo_Run.png`.
- Ortam/biyomlar: `01_Modeling_Atlases/02_Ships_Grades_Environments.png`, `04_TopDown_HUD_Ships_Items_Enemies.png` (bölüm 6 "Çevre & Biyomlar").
- Çatışma ışığı: `00_Visual_Overview.png` (atlas 1 "savaş" paneli) — renkleri cozy tut.


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

---

## Notlar/Öğrenilenler (VFX Engineer)

- 2026-10-22: Entegrasyon rehberi ve partikül bütçeleri `scenes/vfx/README.md`'de. MVP'de tek giriş noktası `vfx_director.tscn` (EventBus dinler), motor izi `engine_trail.tscn` + `set_thrust()`.
- Top-down kamerada sky görünmüyor; arka plan kameraya bağlı tek quad (120 m altta) + shader içi parallax. Ortografik kamerada da çalışır.
- GLSL'de `smoothstep(a, b, x)` için a > b tanımsız; llvmpipe'ta NaN/siyah çizgi üretti. Ters kenar yerine `1.0 - smoothstep(b, a, x)` kullan.
- Box'ta GPU yok (Vulkan llvmpipe). Frame süreleri yazılım render'ı; gerçek orta seviye GPU ölçümü PC'de yapılmalı (`vfx_lookdev.tscn` capture modu `perf.txt` yazar).
