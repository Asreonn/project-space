# Brief — UI Designer

**Sahip olduğun yollar:** `assets/ui/**` (icons/, theme/), `assets/fonts/**`, `scenes/ui/**`, `scripts/ui/**`.
**Branch öneki:** `ui/` · **Review:** Godot Engineer (+ Game Designer HUD uyumu).

## Rolün

Oynanışı kapatmayan, tek bakışta okunan, cozy HUD ve menüler. Gerçek oyun çözünürlüğünde okunabilirlik konsept estetiğinden önce gelir (§13.3).

## [KESİN] kararlar (§13.1 — 21 Ekim kararı)

- **Sol üst:** Hull/HP + Fuel çubukları.
- **Sol kenar:** takılı aktif item/modül/skill için küçük ikonlu dikey hızlı seçim barı (1–4).
- **Sol alt:** minimal, **dairesel** minimap/radar.
- **Ekran altında envanter/loot hotbar YOK.**
- Energy/heat/ammo/uyarılar yalnız gerektiğinde, bağlamsal.
- Büyük görev paneli / alışveriş popup'ı ekrana yapışık durmaz.
- Referanslardaki eski HUD'lar (alt envanter, sağ minimap) **nihai değil**.
- Grade etiketi dili: `E D C B A S SS SSS` (§5.1).

## Stil (§13.3)

Yuvarlatılmış paneller, koyu lacivert/hafif transparan yüzey, pastel turuncu-mavi-mor-şeftali vurgular, ölçülü glow; küçük ama açık ikonlar, az metin, iyi tooltip.

## Teknik

- Godot `Control` + tek proje `Theme` (`assets/ui/theme/ps_theme.tres`). 1920×1080 tasarla, `canvas_items` stretch (project.godot) ile 1280×720'de de test et.
- HUD sahnesi `scenes/ui/hud.tscn` (`CanvasLayer`); veri sinyallerle gelir (Engineer'ın event bus'ı) — HUD oyun mantığı tutmaz.
- Minimap: `SubViewport` + üstten ortografik kamera (render layer `minimap`) veya ikon tabanlı radar (çizim) — ikisini de değerlendir; performans ucuz olanı.
- İkonlar SVG/PNG, 64 px taban, `assets/ui/icons/icon_<ad>.svg`. Font: OFL lisanslı yuvarlak sans (ör. Nunito, Fredoka, Baloo 2) + CREDITS.md.

## M1 görevlerin

1. HUD wireframe → ekran görüntüsü PR'ı (Game Designer onayı).
2. Hull + Fuel barları (animasyonlu azalma, düşükte nabız).
3. Sol aktif slot barı: 4 slot, seçili vurgusu, cooldown/ısı halkası; M1'de slot 1 = Laser, diğerleri boş/kilitli.
4. Dairesel minimap: oyuncu, asteroid, düşman, pickup işaretleri.
5. Bağlamsal göstergeler: laser ısı (geminin yakınında küçük yay/halka), "Kargo dolu" toast'u, solid/liquid/gas kapasite simgeleri (kısa süreli).
6. İkon seti: laser, bomb, drill, skill, solid, liquid, gas, hull, fuel, heat.
7. Basit duraklatma menüsü + ölüm/respawn ekranı (minimal).

## Kabul

HUD §13.1 şemasına birebir uyuyor; altta envanter yok; 1280×720'de okunuyor; ekranın ≤ %12'sini kaplıyor (öneri).

## Referans görseller

- **En yakın final HUD:** `docs/references/01_Modeling_Atlases/04_TopDown_HUD_Ships_Items_Enemies.png` → sol üst "GAMEPLAY & UI (Top-Down)" paneli (sol üst barlar, sol slotlar, sol alt yuvarlak minimap).
- Renk/ikon dili: `01_Modeling_Atlases/03_Gameplay_Resources_Modules.png`, `01_Overall_Art_Direction.png`.
- `02_Gameplay_Mood/05_Mining_HUD.png`, `01_Starter_Mining.png`: renk/his için — **alt envanter barı ve sağ minimap'i kopyalama**.


---

## Ek — GAME_PLAN.md'den ilgili bölümler (birebir)

> Aşağıdaki metin `docs/GAME_PLAN.md` v0.1'den kopyalandı; çelişkide GAME_PLAN + `docs/DECISIONS.md` geçerlidir. **Motor artık Godot 4** (D-001) — §3.3/§20'deki "motor açık" ifadeleri kapandı.


### 5. Grade / kalite / yükseltme ekonomisi

#### 5.1 Tek kalite dili

**[KESİN]** Tüm önemli geliştirilebilir/elde edilebilir varlıklar ortak kalite ölçeğini kullanır:

`E → D → C → B → A → S → SS → SSS`

Kapsam: **oyuncu gemisi, Mother Ship, silah, madencilik aracı, modül, gemi parçası, materyal, loot, üretim tarifi, Mother Ship odası ve mürettebat** (mürettebatın oyuna eklendiği fazda).

Bu ölçek **öğe kalitesi** içindir; oyuncu karakterinin geleneksel bir RPG seviyesi ile karıştırılmamalıdır.

#### 5.2 Grade ile upgrade aynı şey değildir

- **[KESİN]** Bir parçanın/geminin **doğuştan/native grade'i sabittir**.
- Upgrade onu **aynı grade içindeki doğal tavanına** yaklaştırır.
- D-grade gövdeyi sonsuza kadar yükselterek S/SSS-grade gövde yapamazsın.
- Daha yüksek grade kazanmak için daha yüksek grade parça, modül, gemi veya Mother Ship edinmen gerekir.
- Grade arttıkça doğal maksimumlar, bütçeler, potansiyel bağlantılar/kapasiteler ve görsel dil anlamlı biçimde ayrışmalı.

#### 5.3 Grade'in dengeye katkısı

Grade, **tek başına mutlak güç yerine büyüme tavanı ve potansiyel** vermeli:

- Bir düşük grade gemi iyi geliştirilmişse kısa süreli olarak yeni yüksek grade bir geminin bazı işlerini karşılayabilir.
- Ancak aynı bütçeler ve tam yükseltmeler altında yüksek grade'in kalıcı avantajı vardır.
- Her grade her statı eşit artırmaz: tasarım modeli ve rol eğilimi de belirleyicidir.
- Oyuncu sadece DPS yükseltmesin; hız, kargo, menzil, yakıt, radar, pasif kapasite ve recovery arasında tercih yapsın.

#### 5.4 Rarity / loot box ayrımı

- **[KESİN]** Loot ve itemler çok çeşitli, dereceli ve bulması tatmin edici olmalı.
- **[AÇIK]** Hurda kutusu/salvage crate gibi rastgele içerik üretimi olabilir; kesin drop tabloları ve dağılım henüz karara bağlanmadı.
- **[HEDEF]** Gerçek para içeren gacha veya monetizasyon sistemi bu tasarımın zorunlu parçası **değildir**; “gacha hissi” öncelikle kaliteli rastgele ganimet ve sürpriz ödül heyecanını ifade eder.
- **[ÖNERİ]** Drop tabloları region, risk, enemy, grade ve item pool ile veri tabanlı oluşturulsun; canlı servis koşulu aranmasın.


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


### 13. UI / HUD / oyuncu etkileşimi

#### 13.1 Son onaylı ana HUD

**[KESİN — 21 Ekim görsel görüşmesi]** İlk beğenilen low-poly uzay madenciliği sahnesinin sade tasarım dili devam eder; **daha gerçek top-down açı** kullanılır.

```text
┌────────────────────────────────────────────────────────────┐
│  ♥  HULL/HP   ━━━━━━━━━━                                  │
│  ⛽ FUEL      ━━━━━━━                                     │
│                                                            │
│  [1] Aktif Laser          Gemi + asteroid / düşman         │
│  [2] Aktif Bomb                                           │
│  [3] Aktif Drill                                          │
│  [4] Skill / ekipman                                      │
│                                                            │
│                                                            │
│   ◉ MINIMAP                                                │
└────────────────────────────────────────────────────────────┘
```

- **Üst sol:** Can/hull + Fuel çubukları.
- **Sol kenar:** Takılı **aktif item/modül/skill** için küçük ikonlu hızlı seçim barı.
- **Sol alt:** Minimal, dairesel minimap / radar.
- **[KESİN]** Ekran altında açık kargo/loot **inventory hotbar görünmez**.
- Energy/heat/ammo/uyarılar gerektiğinde, ana görüntüyü boğmadan **bağlamsal** gösterilir.
- Büyük görev paneli veya alışveriş popup'ları devamlı ekrana yapışık durmaz.

> **Dikkat:** Görsel referans paftalarında eski alternatif HUD, sağ minimap veya altta envanter görülebilir. Bunlar **nihai HUD kararı değildir**; yukarıdaki şema üstündür.

#### 13.2 Ayrı açılan ekranlar

**[HEDEF]**

1. Gemi detayları ve stat karşılaştırması.
2. Head / Engine / Wings / Body parça değiştirme.
3. Universal hardpoint / aktif ekipman yönetimi.
4. Electronics / passive modül yönetimi.
5. Envanter ve üç kaynak tipine göre kapasite.
6. Harita/radar ve ilgi noktaları.
7. Salvage loot kararları / enkaz inceleme.
8. Ticaret, tamir ve Mother Ship yönetimi (fazı geldiğinde).

#### 13.3 Genel UI dili

- Yuvarlatılmış panel, koyu lacivert / hafif transparan yüzey.
- Pastel turuncu, mavi, mor, şeftali tonları; ölçülü glow.
- Minik ama açık ikonlar, az metin, iyi tooltip, tek bakışta okunabilir grade/hasar/range.
- Gerçek gameplay çözünürlüğünde okunabilirlik, konsept resim estetiğinden öncelikli.
- Çatışma ve madencilikte fare hedefi, kablo/bağlantı çizgisi veya maden damarı vurgusu yığını değil **net geri bildirim** olmalı.
