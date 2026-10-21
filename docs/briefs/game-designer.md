# Brief — Game Designer (lead)

**Sahip olduğun yollar:** `docs/**` (TOOLS.md hariç), `assets/audio/**` (geçici), `PROGRESS.md`/`README.md`/`AGENTS.md` (Engineer ile ortak).
**Branch öneki:** `design/` · **Review:** tasarımı etkileyen her PR'da onayın gerekir; merge'i Godot Engineer yapar.

## Rolün

Ekibin lideri ve GAME_PLAN'ın koruyucususun. Kapsamı küçük, sistemi büyütülebilir tutarsın (§17 kuralı). Ajanlar arası tasarım çakışmalarını çözersin; `[AÇIK]` bir konu kesinleşmeden önce **kullanıcıya (Asrın) sorarsın** ve kararı `docs/DECISIONS.md`'ye yazarsın.

## Uyman/korumanız gereken [KESİN] kararlar

- 2.5D top-down, low-poly, cute/cozy/chill; sert/kirli/hipergerçekçi değil (§1, §14.1).
- Fighter/Explorer/Miner/Salvager **eğilim etiketi**, sınıf kilidi değil (§4.1, §2.2).
- Universal hardpoint; bedel mass/energy/heat/fuel/recoil/speed/Module Capacity bütçelerinden (§4.4). Pasif bonuslar ayrı Electronics bütçesi.
- Grade ölçeği `E → D → C → B → A → S → SS → SSS`; native grade sabit, upgrade yalnızca grade içi tavana (§5).
- Madencilik: Laser / Bomb / Drill — PDF kuralları değişmez (§6).
- Kaynaklar solid / liquid / gas, her biri ayrı kapasite (§7.1).
- Salvage çekirdek (§8). Ölümde insurance/recovery (§9.3).
- HUD: sol üst Hull+Fuel, sol aktif slot barı, sol alt minimap, **alt envanter barı yok** (§13.1).
- Mother Ship ikinci büyük ilerleme kolu (§12) — ama M8+.
- İptaller: solarpunk farm/factory, shop→colony→hub döngüsü (§1).
- **Yeni:** motor = Godot 4 (DECISIONS D-001).

## M1 görevlerin

1. M1 kapsamını ROADMAP'e göre kilitle; kapsam kaymasını reddet (Bomb/Drill/salvage M2+).
2. **D-004:** kapandı (2026-10-22): MVP'de düşman yok, M1'e ertelendi; M1'de GAME_PLAN §9.2 uyarınca küçük pirate/scout. Şimdiki hedef [mvp.md](mvp.md).
3. Kontrol şeması (§3.2 [AÇIK]): Gameplay ile 2 varyant (WASD+fare yönlendirme vs. tank-tarzı) playtest planı.
4. Kamera açısı (§20): perspektif düşük-FOV vs ortografik karşılaştırma kriterleri.
5. `docs/PLAYTEST_M1.md`: 10 dakikalık test senaryosu + his anketi (uçuş, okunabilirlik, laser tatmini, loot hissi).
6. Haftalık: PROGRESS.md'yi gerçekçi tut, M1 kabul kriterlerini işaretle.
7. Ses: CC0 placeholder SFX seti (Kenney audio) → `assets/audio/` + CREDITS.md.

## Kabul / bitmiş sayılma

ROADMAP M1 kabul kriterlerinin tamamı işaretli ve kullanıcı oynayıp onayladı.

## Referans görseller

- Genel: `docs/references/00_Visual_Overview.png`, `01_Modeling_Atlases/01_Overall_Art_Direction.png`.
- M1 hedef his: `02_Gameplay_Mood/01_Starter_Mining.png` (açı daha top-down olacak), HUD için `01_Modeling_Atlases/04_TopDown_HUD_Ships_Items_Enemies.png` sol üst panel (final HUD'a en yakın).
- Uzun vade: `02_Gameplay_Mood/03_Space_Station_Dock.png`, `09_Dock_Closeup.png`, `08_Salvage_Debris.png`.
- El yazısı kaynak: `docs/references/03_Source/spacegamev1.pdf`.
- Uyarı: referanslardaki alt envanter barı, sağ minimap, isimler/stat'lar kural değildir (§13.1, §19.7).


---

## Ek — GAME_PLAN.md'den ilgili bölümler (birebir)

> Aşağıdaki metin `docs/GAME_PLAN.md` v0.1'den kopyalandı; çelişkide GAME_PLAN + `docs/DECISIONS.md` geçerlidir. **Motor artık Godot 4** (D-001) — §3.3/§20'deki "motor açık" ifadeleri kapandı.


### 0. Bu belgenin kullanım kuralları

Bu belge, geçmiş Space Miner konuşmalarını, 21 Ekim 2026 tarihinde paylaşılan **`spacegamev1.pdf`** adlı iki sayfalık el yazısı notu ve son görsel kararları tek bir kaynakta birleştirir. **Kod, mekanik ve modelleme ajanları bu belgeyi referans almalı; burada yalnızca örnek olarak verilen içerikleri kesinleşmiş oyun kuralı saymamalıdır.**

Karar işaretleri:

- **[KESİN]** Kullanıcının doğrudan tarif ettiği veya sonradan açıkça onayladığı tasarım kararı.
- **[PDF]** Doğrudan el yazısı tasarım notundan alınan kural.
- **[HEDEF]** Ürünün tasarım yönünü tarif eder; tam sayısal denge henüz kesinleşmedi.
- **[ÖNERİ]** Uygulamayı mümkün kılmak için sunulan seçenek; onay verilmeden zorunlu mekanik haline getirilmez.
- **[AÇIK]** Daha önce konuşulmuş fakat nihai kararı verilmemiş konu.
- **[ERTELENDİ]** İlk sürüm/prototip kapsamına girmeyecek fikir.
- **[İPTAL]** Önceden konuşulmuş ancak terk edilmiş oyun döngüsü/tasarım yönü.

**Öncelik kuralı:** Daha yeni ve açık kullanıcı kararı daha eski tasarım önerisinin önüne geçer. Çakışan noktalar sessizce yeniden yorumlanmaz; ilgili bölümde ayrıca belirtilir.


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


### 10. Keşif, uzay bölgeleri ve dünya yapısı

**[KESİN]** Oyuncu aynı küçük asteroid odasında sonsuza dek kalmaz; farklı uzay alanlarına ve zamanla güneş sistemlerine ulaşmayı hedefler.

#### 10.1 Bölge örnekleri

- Sakin başlangıç asteroid alanı.
- Yoğun metal/cevher asteroidi bölgesi.
- Buz/kristal kümeleri.
- Gemi enkazı/savaş alanı.
- Gaz bulutu / özel kaynak sahası.
- Tehlikeli korsan bölgesi.
- Nadir anomali / özel keşif alanı.

**Bunlar içerik adaylarıdır**; “buz/volkanik/uranium” gibi konsept paftalarındaki her isim kesin lore veya gameplay olarak onaylanmış değildir.

#### 10.2 Seyahat ve sensör

- Radar menzili ile uzaktaki objelerin görsel/sensör tespiti arasında ilişki.
- Keşif menzili, yakıt gideri, gemi kargo ihtiyacı ve geri dönüş kararı.
- **[HEDEF]** Bir üst bölgeye çıkmak için yalnızca seviye kapısı yerine daha iyi gemi/ekipman/yakıt hazırlığı önem kazansın.
- **[AÇIK]** Galaxy haritası, sistem sayısı, jump teknolojisi, warp/gate kuralları ve prosedürel dağılım algoritması belirlenmedi.

#### 10.3 Üretim dostu dünya düzeni

- Prototipte **tek okunaklı sektör**.
- Sonra birbirine geçiş yapan 2–3 sektör ve farklı risk/kaynak profilleri.
- Sonra yıldız sistemleri, düzenli keşif ve içerik ölçeklemesi.
- Procedural generation yararlı olabilir; fakat her bölgenin rastgele parçalardan oluşması zorunlu değil.


### 11. Ekonomi, ilerleme ve hizmet noktaları

#### 11.1 Edinim yolları

- Madencilikten kaynak.
- Salvage'dan parça/hurda.
- Düşmandan loot.
- Satış veya görevden kredi.
- Daha iyi gemi/araç satın alma, tamir, yükseltme ve saklama.

#### 11.2 İstasyon ve ticaret

**[HEDEF]** İstasyonlarda kargo boşaltma, onarım, ekipman ve gemi alımı, ticaret gibi **hizmetler** bulunabilir.

**Önemli ayrım:** Eski **shop → colony → hub** zorunlu başlangıç oyun döngüsü **iptal edildi**. İstasyon, menü veya pazarın varlığı eski konseptin yeniden etkinleştirildiği anlamına gelmez.

#### 11.3 Görevler

**[ÖNERİ]** İlk kapsamlı sürümde keşif, basit taşıma, kargo teslimi, bounty ve salvage sözleşmeleri olabilir. Oyunu bir görev işaretçisi takip simülasyonuna dönüştürmeyin; serbest oyun döngüsü bağımsız çalışmalıdır.

#### 11.4 Üretim ve işleme

- Bulunan hurdadan temel bileşen çıkarma / kaynak işleme.
- Bulunan modülü doğrudan kullanma, onarma veya parçalarına ayırma.
- İşleme ve craft işinin oyuncuya **yeni donanım** kazandırması.
- **[HEDEF]** Büyük otomasyon ağaçları, kat kat konveyör/fabrika yapısı ve mecburi mikro yönetim yok.
- Üretim tarifinin grade'i olabilir; nihai reçete listesi açık.


### 12. Mother Ship — ikinci büyük ilerleme kolu

**[KESİN]** Mother Ship, oyuncu gemisinin sadece daha büyük versiyonu değil, **heybetli, sahiplenilebilir, yükseltilebilir ikinci ana varlığıdır**.

#### 12.1 Model çeşitliliği

- Farklı Mother Ship modelleri satın alınabilir/edinilebilir.
- Her modelin dış **silüeti, hangar şekli, iç yerleşimi, alan kapasitesi, doğal istatistikleri ve grade'i** farklı olmalı.
- Satın alındığında göze çarpan, tamamlanmış bir **gemi** hissi vermeli; sıfırdan çerçeve inşa edilen boş iskelet olmak zorunda değil.
- **[KESİN]** Daha düşük grade Mother Ship, yükseltilse bile yüksek grade modelin doğal tavanına ulaşamaz.
- **[HEDEF]** Oyunun tam sürümünde erişilebilir alt grade Mother Ship'ler ve ileri aşama üst grade seçenekler bulunmalı. Bir Mother Ship sahibi olmayı yalnızca oyunun bitiş ödülüne bağlama.
- **[AÇIK]** İlk satın alım zamanı, ilk fiyatlar ve tam model sayısı kilitli değil. Önceki kapsam önerisinde P8'de 5–7 model hedefi geçti; bu üretim hedefidir, onaylı nihai içerik adedi değil.

#### 12.2 İç mekân ve odalar

- Modelden modele farklı **cozy iç mekân** ve anlamlı oda/hangar planları.
- İşlevsel oda örnekleri: storage, küçük refinery, salvage workshop, repair, upgrade, hangar, crew/habitat.
- Oda seviyeleri/grade ile işlem kapasitesi, hız, destek sınırı ve kullanılabilirlik farklılaşabilir.
- Odaların makine/üretim faaliyeti bir miktar görsel olarak gözlemlenebilmeli.
- **[KESİN]** Oyuncuya tam kapsamlı insan yönetimi veya zorunlu first-person iç mekân simülasyonu dayatılmamalı.
- **[AÇIK]** İç mekânda mürettebatın hareketini canlı gösterme fikri var; animasyon/AI kapsamı henüz kesin değil.

#### 12.3 Diğer gemilerle ilişki

- Küçük/orta gemiler uygun hangarlara girebilir; çok büyük taşıyıcılar dış docking sistemi kullanabilir (**önceki mimari yön**).
- Mother Ship'te birden fazla gemi saklamak ve kargo aktarmak ilerleyen aşamanın parçası olabilir.
- Diğer gemilerin mürettebat tarafından görevlerde kullanılması **[ERTELENDİ]**; başlangıç odağı tek pilot/tek aktif gemi.

#### 12.4 Mürettebat

- **[HEDEF]** Mürettebat odalara/makine işlevine destek verebilir, yaşam hissini artırabilir ve hafif pasif bonuslar sağlayabilir.
- **[KESİN]** Sürekli maaş/uyku/yemek/moral mikro yönetimi ilk tasarımın gereği değildir.
- **[AÇIK]** Crew grade etkileri, ödeme dengesi, çevrimdışı üretim ve oda bonusları belirlenmedi.


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


### 19. Riskler ve nasıl yönetilecekleri

1. **Aşırı kapsam:** Büyük galaksi + Mother Ship + life sim + otomasyon + tüm grade sistemi birlikte geliştirilirse oynanabilir demo gecikir. **Önlem:** P0–P6 vertical slice; büyük dalları ertele.
2. **Genel factory oyununa kaymak:** Üretim alt sistemi ana döngüyü yutabilir. **Önlem:** Önceliği tek gemi hareketi, salvage ve loot'a ver.
3. **Dört sahte class oluşması:** Fighter/Miner/Explorer/Salvager etiketleri hardlock hâline gelebilir. **Önlem:** Uyumlu her aktif ekipman her universal hardpoint'e gider; denge bütçelerden.
4. **Grade'i sadece rarity rengine indirgemek:** Tier değer taşımaz. **Önlem:** Native cap ve görsel/kapasite farkı, değiştirilemeyen grade.
5. **Aşırı gerçekçi asteroid parçalanması:** Voxel/mesh kesimi teknik yükü gereksiz büyütebilir. **Önlem:** Surface/vein/fracture node mimarisi.
6. **HUD karmaşası:** Çok fazla bar veya envanter görüntüyü kapatabilir. **Önlem:** Kullanıcının son HUD kararı bağlayıcı.
7. **Referans görseli oyun tasarımı sanmak:** AI görsellerindeki drop isimleri, gövde sınıfları ve market sistemleri kararlaştırılmamış olabilir. **Önlem:** Görsel asset yalnızca stil/silüet içindir.
8. **Mother Ship'in ucuz menüye dönüşmesi:** İkinci ana varlık hissini yitirir. **Önlem:** Model özgünlüğü, hangar ve oda işlevleri, mekânsal görünürlük.
9. **Aşırı cezalandırıcı ölüm:** Cozy döngü kesilir. **Önlem:** Insurance/recovery ilkesi ve anlaşılır risk.


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


### 22. Karar geçmişi ve kaynak ayrımı

#### Kaynak A — `spacegamev1.pdf`, 2 sayfa, 21 Ekim 2026

**Sayfa 1:** Fighter/Explorer/Miner/Salvager yalnızca eğilim. `Head → Damage (attack/mining)`, `Engine → Flying Speed`, `Wings → Maneuver Speed`, `Body → Carry Capacity`; Fuel Capacity ve Fuel Rate hiçbir tek parçaya zorunlu bağlanmamış; Energy Capacity, Module Capacity ve Radar/Visual Range listelenmiş; grade değiştikçe parçaların görünümü değişir. Mining araçları: **Laser** (uzak, orta verim, küçük alan, heat/ışın), **Bomb** (uzak, düşük verim, büyük alan, cephane ve saçılan loot), **Drill** (yakın, yüksek verim, küçük alan).

**Sayfa 2:** Uzay kaynakları **solid/liquid/gas** olarak ayrılır; her tipin kendine özgü depolama kapasitesi gerekir.

#### Kaynak B — Önceki Space Miner konuşmaları (Ekim 2026)

- Tek gemi/oyuncu merkezli mining + salvage + combat + loot ve geri dönüş döngüsü.
- Mothership: birçok model, farklı dış silüet ve iç yerleşim, odalar, grade tavanları, crew opsiyonu.
- Tüm önemli varlıklar için `E–SSS` grade; grade yükseltme ile değişmez.
- Evrensel hardpoint, class dışı equip özgürlüğü; mass/heat/energy/fuel/manoeuvre dengesi.
- Fixed weapon/turret hibriti, ayrı passive electronics capacity, insurance/recovery.
- Büyük fleet/faction/mürettebat simülasyonu erken kapsamda yok.

#### Kaynak C — 21 Ekim görsel yön konuşması

- İlk pastel low-poly asteroid madenciliği görüntüsünün tarzı beğenildi.
- Daha tepeden/top-down görünüş.
- Solda Hull/Fuel ve aktif skill/item barı; sol altta minimap.
- Oynanış HUD'ından sürekli envanterin kaldırılması.
- Farklı grade/çevre/maden/gemi/düşman için modelleme referansları.

#### Kaynak D — Bu belgedeki uygulama önerileri

P0–P9 yol haritasının bölüm sıralaması, data entity adları, ilk teslim kriterleri, teknik nodal madencilik yaklaşımı ve örnek düşman/bölge isimleri **uygulanabilir proje planı oluşturmak için hazırlanmış önerilerdir**. Kullanıcının doğrudan kilitlediği ek oyun içeriği gibi sunulmamalıdır.


### 23. Kısa tasarım manifestosu

**Gemiyi sürmek keyifli; bulduğumuz eşya işe yarar; ilerleme görünür; dünya sevimli ama boş değildir.**

Oyuncunun dört farklı gemi sınıfından birini seçip diğerlerini kaybettiği oyun değil; istediği yönde kişiselleştirdiği, doğal sınırları olan farklı gemilere geçtiği bir uzay macerası. Madencilik üç farklı araçla anlamlı seçim yaratır, salvage doğrudan donanım progresyonuna bağlanır ve Mother Ship ikinci büyük kişisel ilerleme hattını oluşturur. Basit, okunaklı ve güzel görünen bir **ilk 10 dakika**, büyük ama tamamlanmamış bir evrenden daha değerlidir.
