# PROJECT SPACE / SPACE MINER — GAME PLAN

> **Sürüm:** v0.1 — Birleştirilmiş oyun tasarım ve uygulama planı  
> **Tarih:** 21 Ekim 2026  
> **Durum:** Ön üretim / ilk oynanabilir prototip hazırlığı  
> **Platform:** Öncelikle PC, tek oyunculu  
> **Tür:** 2.5D top-down uzay aksiyonu, madencilik, salvage, hafif sandbox/life-sim ve gemi geliştirme  
> **Görsel hedef:** Cozy / cute / chill, okunaklı, düşük poligonlu, kontrollü efektli, renkli uzay

## 0. Bu belgenin kullanım kuralları

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

---

## 1. Oyun vizyonu ve oyuncu fantezisi

**[KESİN]** Oyuncu kendi gemisiyle geniş ve yaşanabilir hissi veren uzayda özgürce dolaşır; savaş alanlarını, enkazları, asteroid kümelerini ve ilginç bölgeleri keşfeder. Kaynak çıkarır, bulduğu parçaları kurtarır, ganimet toplar, gemisini geliştirir, gerektiğinde savaşır, daha uzak bölgelere erişir ve zamanla etkileyici bir **Mother Ship** sahibi olabilir.

Oyunun kimliği üç eksende şekillenir:

1. **Gemi kullanmak başlı başına eğlenceli olmalı:** hareket, dönüş, hızlanma, drift, boost, isabetli ateş, dar alanlarda manevra.
2. **Bulduğun şeyin değeri ve kullanım alanı olmalı:** maden, hurdadan sökülen motor, nadir modül, yakıt, tarif, gövde parçaları veya ticari malzeme.
3. **Gelişimin görünür olmalı:** başlangıç gemisinden daha yetenekli veya farklı eğilimli gemilere, modüllere, gemi üstü donanıma ve sonunda modeline özgü iç mekânı olan Mother Ship'e geçiş.

**Oyunu bir fabrika simülasyonuna dönüştürme.** Madencilik, salvage, savaş, gemi toplama ve modüler kişiselleştirme merkezde; otomasyon/üretim ve mürettebat bunları destekler.

### Oyunun tonu

- **[KESİN]** Top-down'a yakın **2.5D**, 3D low-poly modeller; sevimli, sıcak, sade formlar.
- **[KESİN]** Genel akış **cozy / tatlı / chill** olmalı. Savaş ve tehlike mümkün ama atmosfer aşırı sert, kirli, karanlık veya hipergerçekçi olmamalı.
- **[HEDEF]** İster kısa bir madencilik turu, ister enkaz arama, ister riskli çatışma yapılabilsin.
- **[HEDEF]** Ekran görüntüsündeki nesneler az poligonla, mesafeden hemen anlaşılabilsin. Detay yerine silüet, renk ve iyi animasyon önceliklidir.

### Kapsam dışı kimlikler

- **[İPTAL]** Eski solarpunk farm/factory oyun konsepti.
- **[İPTAL]** İlk önerilerdeki sabit shop → colony → hub ana döngüsü.
- **[ERTELENDİ]** Büyük filoları mikro yönetmek, devasa zorunlu mürettebat simülasyonu, tam fabrika otomasyonu ve ağır survival bürokrasisi.
- **[KESİN]** Gemi eğilimleri sert meslek/sınıf kilitleri **değildir**.

---

## 2. Tasarım önceliği ve ana oynanış döngüleri

### 2.1 Kısa oturum döngüsü

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

### 2.2 Paralel oyun tarzları

| Yaklaşım | Oyuncunun yaptığı | Temel ödül |
|---|---|---|
| Madenci | Asteroid tarar, damar/çekirdek bulur, Laser/Bomb/Drill seçer | Katı/sıvı/gaz kaynak, nadir maden |
| Salvager | Terk edilmiş gemi/enkaz bulur, parça söker ve taşır | Kullanılabilir modül, hurda, bileşen |
| Savaşçı | Korsan, drone veya tehlikeli hedefle çatışır | Ganimet, kredi, hasarlı teknoloji |
| Explorer | Yeni bölgeler, sinyaller, anormallikler ve kaynak kümeleri keşfeder | Keşif verisi, erişim, özel loot |
| Karma | Her birinden bir miktar yapar | Esnek, oyuncuya özgü ilerleme |

**[KESİN]** Hiçbir tarz bir gemiye kapatılmaz. Geminin mevcut parçaları, donanımı, grade'i ve sınırları o tarzda ne kadar başarılı olduğunu belirler.

### 2.3 Tasarımın kalite sırası

1. Kontrol hissi / kamera / okunabilirlik.
2. Tek gemiyle tatmin edici uçuş, kısa çatışma ve loot.
3. Madencilik araçlarının hissedilir farkı.
4. Enkaz ve parça sökme.
5. Grade, ekipman, ekonomi, daha iyi gemi hedefi.
6. Bölgesel keşif, görevler ve Mother Ship genişlemesi.

**Üretim ilkesi:** Daha fazla özellik, kötü hissedilen bir uçuş sistemini kurtaramaz.

---

## 3. Kamera, fizik ve kontroller

### 3.1 Perspektif

- **[KESİN]** Yukarıdan görünen, hafif açı hissi taşıyan **2.5D top-down** dünya.
- **[HEDEF]** Gemiler gerçek 3D hacimli modellere sahip olur; oynanış konumu ve hedefleme bir ana düzlemde anlaşılır.
- **[HEDEF]** Kamerada gerektiğinde hafif takip/zoom; asteroid ve gemi silüetleri UI'yı kapatmaz.
- **[ÖNERİ]** Ortografik veya düşük perspektif bozulmalı kamera. Nihai kamera açısı oynanabilir prototiple seçilecek.

### 3.2 Gemi sürüşü

- Hızlanma/yavaşlama ve dönme hissi.
- **Flying Speed** ile **Maneuver Speed** birbirinden ayrılır.
- Boost ve kısa süreli drift / inertia hissi; arcade okunabilirliği korunur.
- Büyük kargo, ağır donanım ve farklı motorların manevra/hız/yakıt etkileri.
- Düşman ateşinden kaçma ve asteroidden sıyrılma becerisi.
- **[AÇIK]** WASD + fare yönlendirme mi, ikiz analog hissi mi, alternatif sürüş modları mı; kontrol şeması playtest ile kilitlenmeli.

### 3.3 Performans hedefi

- Gemiler ve asteroidler düşük poligonlu, tekrardan kullanılabilir modüler varlıklar.
- Yoğun nebula ve parçacıklar görsel referanstır; ekranda binlerce pahalı şeffaf efekt zorunlu değildir.
- Nesne havuzu (projectile, loot, debris), görünürlük/LOD ve yükleme bütçeleri baştan düşünülür.
- **[AÇIK]** Oyun motoru kesinleşmiş değil; Godot/Unity seçimi bu belge tarafından zorlanmamalı.

---

## 4. Gemiler: katalog, eğilimler ve bütünleşik statlar

### 4.1 Gemi arketipleri

**[PDF][KESİN]** Dört ad **class kilidi değil, eğilim etiketidir**:

- **Fighter:** Savaş, dayanıklılık, silah ve refleks çatışması eğilimi.
- **Explorer:** Hız/menzil, radar, keşif ve hareketlilik eğilimi.
- **Miner:** Maden donanımı, enerji, kargo ve kazı verimliliği eğilimi.
- **Salvager:** Enkaz tarama, sökme, çekme, hasarlı parçaları taşıma eğilimi.

Bir gemi hem Fighter hem Explorer, hatta Miner/Salvager yeteneklerini taşıyabilir. Geminin tasarımı ve fabrika çıkış değerleri **başlangıç yönünü** belirler, neyi yapabileceğini kesin biçimde yasaklamaz.

**[KESİN]** Oyuncu gemilerinin çok sayıda farklı modeli/silüeti olmalı; hepsinin gövde biçimi, kapasitesi, hareket hissi, doğal limitleri ve geliştirme potansiyeli aynı şablonun kopyası olmamalı. Tam katalog miktarı kesinleşmiş değil.

### 4.2 Temel gemi statları

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

### 4.3 Modüler ana anatomisi

**[PDF][KESİN]** Gemi parça tasarımında en az dört ana görsel/işlevsel katman:

1. **Head:** burun/ön modül, saldırı ve madencilik eğilimi.
2. **Engine:** motor ve itki grubu; uçuş karakteristiği.
3. **Wings:** kanat/manevra kontrol bileşenleri.
4. **Body:** ana gövde, hacim, kargo ve iç sistem taşıma.

- Her parçanın kendine ait formu, grade'i, yükseltilebilir değerleri ve takıldığı gemi üzerindeki uyumluluğu olabilir.
- **[PDF]** Grade'e bağlı parça görünümü değişir; düşükten yükseğe yalnızca sayısal değil görsel kalite de hissedilmeli.
- **[KESİN]** Gemiler aynı hazır modelin yalnızca rengini değiştirerek çoğaltılmamalı.
- **[ÖNERİ]** Her ana parça için açık local anchor/pivot ve standart bağlantı arabirimi kur; hangi kombinasyonların clipping'e neden olacağı test edilmeli.

### 4.4 Universal hardpoint politikası

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

### 4.5 Silah ve araç davranışları

- Hibrit yaklaşım: sabit yönlü silahlar ile bağımsız dönebilen turret/araçlar birlikte mümkün.
- Oyuncunun yön değiştirmesi, kaçınması ve atışı manuel kontrol etmesi önemli.
- **[HEDEF]** Her silah/araç kendi ses, geri tepme, açılma, enerji ve etki görseline sahip.
- **[ÖNERİ]** Turret dönüş hızı / firing arc / projectile speed veriye dayalı olsun; tam açı ve sınırlama sayıları test edilmeden kilitlenmesin.

---

## 5. Grade / kalite / yükseltme ekonomisi

### 5.1 Tek kalite dili

**[KESİN]** Tüm önemli geliştirilebilir/elde edilebilir varlıklar ortak kalite ölçeğini kullanır:

`E → D → C → B → A → S → SS → SSS`

Kapsam: **oyuncu gemisi, Mother Ship, silah, madencilik aracı, modül, gemi parçası, materyal, loot, üretim tarifi, Mother Ship odası ve mürettebat** (mürettebatın oyuna eklendiği fazda).

Bu ölçek **öğe kalitesi** içindir; oyuncu karakterinin geleneksel bir RPG seviyesi ile karıştırılmamalıdır.

### 5.2 Grade ile upgrade aynı şey değildir

- **[KESİN]** Bir parçanın/geminin **doğuştan/native grade'i sabittir**.
- Upgrade onu **aynı grade içindeki doğal tavanına** yaklaştırır.
- D-grade gövdeyi sonsuza kadar yükselterek S/SSS-grade gövde yapamazsın.
- Daha yüksek grade kazanmak için daha yüksek grade parça, modül, gemi veya Mother Ship edinmen gerekir.
- Grade arttıkça doğal maksimumlar, bütçeler, potansiyel bağlantılar/kapasiteler ve görsel dil anlamlı biçimde ayrışmalı.

### 5.3 Grade'in dengeye katkısı

Grade, **tek başına mutlak güç yerine büyüme tavanı ve potansiyel** vermeli:

- Bir düşük grade gemi iyi geliştirilmişse kısa süreli olarak yeni yüksek grade bir geminin bazı işlerini karşılayabilir.
- Ancak aynı bütçeler ve tam yükseltmeler altında yüksek grade'in kalıcı avantajı vardır.
- Her grade her statı eşit artırmaz: tasarım modeli ve rol eğilimi de belirleyicidir.
- Oyuncu sadece DPS yükseltmesin; hız, kargo, menzil, yakıt, radar, pasif kapasite ve recovery arasında tercih yapsın.

### 5.4 Rarity / loot box ayrımı

- **[KESİN]** Loot ve itemler çok çeşitli, dereceli ve bulması tatmin edici olmalı.
- **[AÇIK]** Hurda kutusu/salvage crate gibi rastgele içerik üretimi olabilir; kesin drop tabloları ve dağılım henüz karara bağlanmadı.
- **[HEDEF]** Gerçek para içeren gacha veya monetizasyon sistemi bu tasarımın zorunlu parçası **değildir**; “gacha hissi” öncelikle kaliteli rastgele ganimet ve sürpriz ödül heyecanını ifade eder.
- **[ÖNERİ]** Drop tabloları region, risk, enemy, grade ve item pool ile veri tabanlı oluşturulsun; canlı servis koşulu aranmasın.

---

## 6. Madencilik: üç zorunlu yöntem

Bu bölümün mekanik çekirdeği **doğrudan `spacegamev1.pdf` sayfa 1** kaynağına dayanır.

| Yöntem | Menzil | Verim | Alan | Tüketim / gereksinim | Toplama davranışı |
|---|---|---|---|---|---|
| **Laser** | Uzak | Orta | Küçük | Enerji, ısı üretimi | Uygun kapasite varsa çıkarılan malzeme doğrudan kargoya aktarılabilir |
| **Bomb** | Uzak | Düşük | Büyük | Cephane; temasla veya isteğe bağlı patlama | Parçalar çevreye saçılır; yaklaşarak toplama gerekir |
| **Drill** | Yakın | Yüksek | Küçük | Yaklaşma/temas ve çalışma bütçesi | Uygun kapasite varsa malzeme doğrudan kargoya aktarılabilir |

**Laser:** Uzaktan ışın gönderir; hedefi ısı/erime mantığı ile kazır. Özellikle kontrollü damar çıkarma için kullanılır.

**Bomb:** Atılan bomba çarpmayla veya seçilen tetikleme koşuluyla patlar; büyük alan açar fakat ekonomik verim düşüktür. Kaynak saçılımı oyuncuya fiziksel toplama işi yaratır. Sınırlı cephane kullanır.

**Drill:** Yakından uygulanır ve yüksek verimlidir. PDF tasarımında sınırsız/cephanesiz çalışma yönü bulunur; fakat risk, yakıt, ısınma, süre ve yakınlık hâlâ oynanış maliyetleri olabilir. Bu maliyetlerin tam sayısı açık.

### 6.1 Asteroid çıkarma modeli

**[HEDEF]** Sınırsız, serbest voxel/mesh kesimi şart değil. Üretim dostu yapı:

1. **Surface layer:** yüzeyden parça çıkarma; Laser için belirgin geri bildirim.
2. **Vein/precision nodes:** konsantre maden damarı / zayıf bölge; araç tercihini ödüllendirir.
3. **Core/fracture nodes:** kontrollü kırılma/patlatma; Bomb ve Drill'e taktiksel kullanım.
4. **Debris / loot release:** kontrollü fiziksel parçalar, toplama akışı.

Bu katmanlar eski geniş tasarımdaki teknik öneridir; **güncel PDF'deki Laser/Bomb/Drill kurallarını değiştiremez**.

### 6.2 Madenciliğin hissi

- Lazer temasında sıcak iz / ışıma ve ufak parçacıklar.
- Drill çalışırken gemi burnunda titreşim, küçük kopmalar ve ritmik ilerleme.
- Bomb'da büyük fakat düşük detaylı parçalanma; kaynak küreleri kolay seçilmeli.
- Taşıma kapasitesi dolunca üretim/loot toplama net biçimde durur veya erişilebilir artık parçalar dünyada kalır.
- **[HEDEF]** Cazip madenleri bulmak, çıkarmak ve güvenle geri getirmek tek başına eğlenceli bir kısa görev olmalı.

---

## 7. Kaynak türleri, envanter ve taşıma

### 7.1 Fiziksel kaynak sınıfları

**[PDF — sayfa 2]** Uzayda toplanan temel kaynaklar **katı, sıvı ve gaz** olarak ayrılır. **Her tip için uygun özel kapasite** gerekir.

- **Solid / Katı:** cevher, metal, kristal, fiziksel hurda.
- **Liquid / Sıvı:** ayrı depolama türünü kullanan sıvılar (**madde isimleri henüz kilitli değil**).
- **Gas / Gaz:** ayrı depolama türünü kullanan gazlar (**gaz türleri henüz kilitli değil**).

Yalnızca “toplam kargo 100” yaklaşımı doğru değil; örneğin katı deposu boş olsa bile uygun tank yoksa gaz toplanamaz.

### 7.2 Kargo ve kapasite

- **Body** genel hacim kapasitesinin ana girdisi.
- Solid, liquid, gas için ayrı kapasiteler / konteynerler.
- Modül ve enkaz parçaları da kütle/hacim oluşturabilir.
- Kapasite aşımına UI'da erken ve açık uyarı verilir.
- Taşınan yük uçuş üzerinde ölçülü etki yaratır.
- **[AÇIK]** Eski sohbetlerde bir gemi için **6×7 slot inventory** gündeme geldi; envanterin nihai grid boyutu veya tüm gemiler için aynı olması kesin karar değil.

### 7.3 Toplama ilkeleri

- Bazı malzeme çıktıları otomatik çekim/ışın aktarımı ile kargoya girebilir.
- Bomb ile saçılan kaynaklar, enkaz parçaları ve büyük loot için yaklaşma/tractor/hakimiyet gerektiren toplama anları korunur.
- Materyal miktarı, grade, hasar/condition ve saklama koşulu veri modelinde ayrı tutulur.
- Kargo ekranı açıldığında filtreleme (katı/sıvı/gaz/modül/hurda) ve hızlı aktarma düşünülmeli; **oynanış HUD'ında sürekli envanter barı yoktur**.

---

## 8. Salvage ve enkaz toplama

**[KESİN]** Salvage oyun çekirdeğidir; madenciliğin ufak bir varyasyonu olarak görülmemeli.

### 8.1 Salvage deneyimi

1. Eski savaş bölgesi veya terk edilmiş gemi bul.
2. Radar/sensör ile tarayarak sökülebilir alanları belirle.
3. Parçanın türünü/grade'ini/hasar durumunu öğren.
4. Yaklaş, cutter/tractor/uygun araçla parçayı ayır.
5. Kargoya al veya çekerek transfer et.
6. Ana gemide, istasyonda veya Mother Ship'te karar ver: **tak / onar / sök / işle / araştır / sat / sakla**.

### 8.2 Salvage çeşitleri

- Kullanılabilir silah ve modüller.
- Hasarlı fakat onarılabilir motor/gövde/kanat bileşenleri.
- Metal/hurda ve işleme girdileri.
- Nadir teknoloji / blueprint / veri.
- Daha büyük, çekilmesi gereken parçalar.

### 8.3 Risk ve değer

- Kullanılabilir modüllerin condition/damage durumu.
- Çevresel tehlike, kalan enerji, tuzak/reaktör veya yakın düşman tehdidi gibi fırsatlar **[ÖNERİ]** olarak değerlendirilebilir.
- Gereksiz karmaşıklıktan kaçın: fiziksel bir enkazı anlamlandırmak, teknik mini-game sayısını artırmaktan daha önemlidir.
- **[HEDEF]** “Loot is Build”: oyuncu enkazdan bulduğu modülü gerçekten gemisine takabilsin.

---

## 9. Savaş, düşmanlar ve hayatta kalma

### 9.1 Savaş yönü

- **[KESİN]** 2.5D top-down refleks/konum alma çatışması.
- Sabit silah + turret hibriti.
- Menzil, hareket, dönüş, projectile hızı, ısınma, enerji ve silah grade'i farklı oyun tarzları yaratır.
- Oyuncu gemisi silahlanırken madencilik ekipmanlarını tamamen bırakmak zorunda değildir; hardpoint özgürlüğü esastır.
- **[HEDEF]** Rastgele kurşun cehennemi değil, okunabilir ve keyifli uzay karşılaşmaları.

### 9.2 Düşman aileleri

Aşağıdakiler **görsel referans ve ilk tasarım önerileri**; son düşman kataloğu değildir:

| Aile | İşlev | İlk prototip? |
|---|---|---|
| Küçük pirate/scout | Kovalar, tek veya kısa seri ateş eder | Evet, bir örnek |
| Miner-raider | Kaynak bölgesinde taciz/loot riski | Daha sonra |
| Drone | Hafif çevik hedef | Daha sonra |
| Guard/turret | Alan tutma / sabit savunma | Daha sonra |
| Elite/boss | Özel saldırı paterni, nadir loot | Genişleme |

**[KESİN]** Korsan baskınları ve tehlike duygusu dünyada bulunabilir; ama erken oyunda devasa faction/filo sistemi kurmak zorunlu değil.

### 9.3 Kaybetme ve recovery

**[KESİN]** Gemi imhasında **sigorta/kurtarma (insurance/recovery)** yaklaşımı olmalı. Tüm emeği cezalandıran koşulsuz kalıcı kayıp temel tasarım değil.

- Kurtarmanın maliyeti, hangi ekipmanın korunacağı ve kargonun ne kadarının risk altında olduğu **[AÇIK]**.
- **[ÖNERİ]** Prototipte maliyetsiz/kolay respawn; sistem olgunlaşınca önceden anlaşılır recovery bedeli.

---

## 10. Keşif, uzay bölgeleri ve dünya yapısı

**[KESİN]** Oyuncu aynı küçük asteroid odasında sonsuza dek kalmaz; farklı uzay alanlarına ve zamanla güneş sistemlerine ulaşmayı hedefler.

### 10.1 Bölge örnekleri

- Sakin başlangıç asteroid alanı.
- Yoğun metal/cevher asteroidi bölgesi.
- Buz/kristal kümeleri.
- Gemi enkazı/savaş alanı.
- Gaz bulutu / özel kaynak sahası.
- Tehlikeli korsan bölgesi.
- Nadir anomali / özel keşif alanı.

**Bunlar içerik adaylarıdır**; “buz/volkanik/uranium” gibi konsept paftalarındaki her isim kesin lore veya gameplay olarak onaylanmış değildir.

### 10.2 Seyahat ve sensör

- Radar menzili ile uzaktaki objelerin görsel/sensör tespiti arasında ilişki.
- Keşif menzili, yakıt gideri, gemi kargo ihtiyacı ve geri dönüş kararı.
- **[HEDEF]** Bir üst bölgeye çıkmak için yalnızca seviye kapısı yerine daha iyi gemi/ekipman/yakıt hazırlığı önem kazansın.
- **[AÇIK]** Galaxy haritası, sistem sayısı, jump teknolojisi, warp/gate kuralları ve prosedürel dağılım algoritması belirlenmedi.

### 10.3 Üretim dostu dünya düzeni

- Prototipte **tek okunaklı sektör**.
- Sonra birbirine geçiş yapan 2–3 sektör ve farklı risk/kaynak profilleri.
- Sonra yıldız sistemleri, düzenli keşif ve içerik ölçeklemesi.
- Procedural generation yararlı olabilir; fakat her bölgenin rastgele parçalardan oluşması zorunlu değil.

---

## 11. Ekonomi, ilerleme ve hizmet noktaları

### 11.1 Edinim yolları

- Madencilikten kaynak.
- Salvage'dan parça/hurda.
- Düşmandan loot.
- Satış veya görevden kredi.
- Daha iyi gemi/araç satın alma, tamir, yükseltme ve saklama.

### 11.2 İstasyon ve ticaret

**[HEDEF]** İstasyonlarda kargo boşaltma, onarım, ekipman ve gemi alımı, ticaret gibi **hizmetler** bulunabilir.

**Önemli ayrım:** Eski **shop → colony → hub** zorunlu başlangıç oyun döngüsü **iptal edildi**. İstasyon, menü veya pazarın varlığı eski konseptin yeniden etkinleştirildiği anlamına gelmez.

### 11.3 Görevler

**[ÖNERİ]** İlk kapsamlı sürümde keşif, basit taşıma, kargo teslimi, bounty ve salvage sözleşmeleri olabilir. Oyunu bir görev işaretçisi takip simülasyonuna dönüştürmeyin; serbest oyun döngüsü bağımsız çalışmalıdır.

### 11.4 Üretim ve işleme

- Bulunan hurdadan temel bileşen çıkarma / kaynak işleme.
- Bulunan modülü doğrudan kullanma, onarma veya parçalarına ayırma.
- İşleme ve craft işinin oyuncuya **yeni donanım** kazandırması.
- **[HEDEF]** Büyük otomasyon ağaçları, kat kat konveyör/fabrika yapısı ve mecburi mikro yönetim yok.
- Üretim tarifinin grade'i olabilir; nihai reçete listesi açık.

---

## 12. Mother Ship — ikinci büyük ilerleme kolu

**[KESİN]** Mother Ship, oyuncu gemisinin sadece daha büyük versiyonu değil, **heybetli, sahiplenilebilir, yükseltilebilir ikinci ana varlığıdır**.

### 12.1 Model çeşitliliği

- Farklı Mother Ship modelleri satın alınabilir/edinilebilir.
- Her modelin dış **silüeti, hangar şekli, iç yerleşimi, alan kapasitesi, doğal istatistikleri ve grade'i** farklı olmalı.
- Satın alındığında göze çarpan, tamamlanmış bir **gemi** hissi vermeli; sıfırdan çerçeve inşa edilen boş iskelet olmak zorunda değil.
- **[KESİN]** Daha düşük grade Mother Ship, yükseltilse bile yüksek grade modelin doğal tavanına ulaşamaz.
- **[HEDEF]** Oyunun tam sürümünde erişilebilir alt grade Mother Ship'ler ve ileri aşama üst grade seçenekler bulunmalı. Bir Mother Ship sahibi olmayı yalnızca oyunun bitiş ödülüne bağlama.
- **[AÇIK]** İlk satın alım zamanı, ilk fiyatlar ve tam model sayısı kilitli değil. Önceki kapsam önerisinde P8'de 5–7 model hedefi geçti; bu üretim hedefidir, onaylı nihai içerik adedi değil.

### 12.2 İç mekân ve odalar

- Modelden modele farklı **cozy iç mekân** ve anlamlı oda/hangar planları.
- İşlevsel oda örnekleri: storage, küçük refinery, salvage workshop, repair, upgrade, hangar, crew/habitat.
- Oda seviyeleri/grade ile işlem kapasitesi, hız, destek sınırı ve kullanılabilirlik farklılaşabilir.
- Odaların makine/üretim faaliyeti bir miktar görsel olarak gözlemlenebilmeli.
- **[KESİN]** Oyuncuya tam kapsamlı insan yönetimi veya zorunlu first-person iç mekân simülasyonu dayatılmamalı.
- **[AÇIK]** İç mekânda mürettebatın hareketini canlı gösterme fikri var; animasyon/AI kapsamı henüz kesin değil.

### 12.3 Diğer gemilerle ilişki

- Küçük/orta gemiler uygun hangarlara girebilir; çok büyük taşıyıcılar dış docking sistemi kullanabilir (**önceki mimari yön**).
- Mother Ship'te birden fazla gemi saklamak ve kargo aktarmak ilerleyen aşamanın parçası olabilir.
- Diğer gemilerin mürettebat tarafından görevlerde kullanılması **[ERTELENDİ]**; başlangıç odağı tek pilot/tek aktif gemi.

### 12.4 Mürettebat

- **[HEDEF]** Mürettebat odalara/makine işlevine destek verebilir, yaşam hissini artırabilir ve hafif pasif bonuslar sağlayabilir.
- **[KESİN]** Sürekli maaş/uyku/yemek/moral mikro yönetimi ilk tasarımın gereği değildir.
- **[AÇIK]** Crew grade etkileri, ödeme dengesi, çevrimdışı üretim ve oda bonusları belirlenmedi.

---

## 13. UI / HUD / oyuncu etkileşimi

### 13.1 Son onaylı ana HUD

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

### 13.2 Ayrı açılan ekranlar

**[HEDEF]**

1. Gemi detayları ve stat karşılaştırması.
2. Head / Engine / Wings / Body parça değiştirme.
3. Universal hardpoint / aktif ekipman yönetimi.
4. Electronics / passive modül yönetimi.
5. Envanter ve üç kaynak tipine göre kapasite.
6. Harita/radar ve ilgi noktaları.
7. Salvage loot kararları / enkaz inceleme.
8. Ticaret, tamir ve Mother Ship yönetimi (fazı geldiğinde).

### 13.3 Genel UI dili

- Yuvarlatılmış panel, koyu lacivert / hafif transparan yüzey.
- Pastel turuncu, mavi, mor, şeftali tonları; ölçülü glow.
- Minik ama açık ikonlar, az metin, iyi tooltip, tek bakışta okunabilir grade/hasar/range.
- Gerçek gameplay çözünürlüğünde okunabilirlik, konsept resim estetiğinden öncelikli.
- Çatışma ve madencilikte fare hedefi, kablo/bağlantı çizgisi veya maden damarı vurgusu yığını değil **net geri bildirim** olmalı.

---

## 14. Görsel tasarım / 3D modelleme rehberi

### 14.1 Art direction

**[KESİN]**

- 2.5D top-down, low-poly, cute/cozy/chill.
- Silüet odaklı, okunabilir gemi ve asteroid biçimleri.
- Küçük beyaz/kremsi başlangıç gemisi, seçilebilir kontrast renk vurgusu.
- Asteroid: basit fasetli büyük kaya, seçilebilir maden çıkıntıları.
- Ortam: koyu boşluk + düşük yoğunluklu renkli nebula, yıldızlar, uzaktaki büyük gezegenler.
- VFX: yumuşak motor izi, kısa laser çizgisi, küçük loot parçacıkları.
- Foto-gerçekçi malzeme, aşırı kompleks model, kalabalık HUD, ağır partikül sistemi hedef değil.

### 14.2 Gemi modelleme sistemi

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

### 14.3 İlk oluşturulacak referans paketleri

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

### 14.4 Okunabilir ölçek bütçesi

- Normal gameplay zoom'unda başlangıç gemisi, asteroid, düşman ve loot ayırt edilebilmeli.
- Çok küçük fiziksel detayı UI ya da parlayan outline ile sürekli telafi etme.
- Grade yükseldikçe **şekil** çeşitlenir fakat kamera yakınlaştırılması zorunlu olmaz.
- **[AÇIK]** Mutlak poligon sayısı, texture çözünürlüğü ve performans bütçesi motor/cihaz testinden sonra sabitlenir.

---

## 15. Sistem mimarisi — motor bağımsız teslimat

**[HEDEF]** İçerik ile oyun kodu ayrılmalı; gemi ve item katalogları genişlediğinde onlarca özel kod bloğu oluşmamalı.

### 15.1 Önerilen veri varlıkları

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

### 15.2 Ayrıştırılacak çalışma sistemleri

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

### 15.3 Veri kontratı örneği (nihai JSON şeması değil)

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

### 15.4 Teknik ilkeler

- Save dosyası native grade, item grade, upgrade level, condition ve loadout'u ayrı saklar.
- Prototipte bile aynı item/ship tanımı tek veri kaynağı olmalı.
- Asteroid/maden/salvage iş akışında item duplikasyonu ve kapasite bypass'ı engellenmeli.
- Büyük miktarda asteroid/loot için object pooling.
- Ortam/konum üretimi seed tabanlı ve debug edilebilir olabilir (**[ÖNERİ]**).
- Klasör isimleri ve veri formatı seçilen oyun motorunun kurallarına göre uyarlanabilir; yukarıdaki mantıksal sınırlar korunur.

---

## 16. Aşamalı geliştirme yol haritası

> **Strateji:** Devasa içerik kataloğu ile başlamayın. Önce fiziksel his + kısa tamamlanabilir oyun döngüsü, sonra sistem genişliği.

### P0 — Playable Flight & Visual Baseline

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

### P1 — Mining Vertical Loop

- [ ] Katı kaynak taşıyan iki asteroid prototipi.
- [ ] **Laser**: ranged, heat, orta verim, küçük alan, kargoya kontrollü aktarım.
- [ ] **Bomb**: ammo, geniş alan, düşük verim, yerde saçılan collectable parçalar.
- [ ] **Drill**: close, yüksek verim, küçük alan, cephanesiz temel kullanım.
- [ ] Asteroid damar/çekirdek/zayıf bölge prototipi.
- [ ] Cargo türleri **solid/liquid/gas**, ayrı limitlerin teknik desteği.
- [ ] Toplama/capacity dolu geri bildirimi.
- [ ] Kısa tur: madeni bul → çıkar → topla → transfer noktasına getir.

**Kabul:** Üç araç aynı işi farklı oynanışla yapıyor ve katı/sıvı/gaz sınıfları veri düzeyinde birbirine karışmıyor.

### P2 — Basic Combat

- [ ] İlk pirate/scout düşman gemisi.
- [ ] Sabit yönlü temel silah + turret mantığı için taban.
- [ ] Projectile, HP/damage, hasar tepkisi, basit ölüm/scrap üretimi.
- [ ] Düşmanın basit yaklaş, saldır, geri çekil davranışı.
- [ ] Oyuncu silah ve mining ekipmanını aynı gemide taşıyabilir.
- [ ] Loot üretimi; geçici kurtarma/respawn.

**Kabul:** Oyuncu kısa bir çatışmayı bilinçli manevra ve atışla bitirebilir; oyun görsel olarak hâlâ okunaklıdır.

### P3 — Salvage & Ship Customization

- [ ] Enkaz nesnesi, tarama ve sökülebilir hedef.
- [ ] Tractor/cutter veya uygun araçla ilk parça sökme akışı.
- [ ] Hasarlı modül condition / salvage kararı.
- [ ] Kargo/loot ekranı; altta sürekli HUD inventory olmadan çalışır.
- [ ] Head / Engine / Wings / Body swap için işleyen modüler veri modeli.
- [ ] Universal hardpoint tak-çıkar.
- [ ] Ayrı passive electronics bütçesi.

**Kabul:** Düşmandan/enkazdan kazanılan modül gerçekten oyuncu gemisine takılabilir veya kaynak için parçalanabilir.

### P4 — Grade & Second Hull

- [ ] `E → ... → SSS` genel kalite şeması.
- [ ] Native grade sabitliği ve grade içi upgrade limitleri.
- [ ] İlk iki farklı gemi gövdesi arasında anlamlı stat/silüet farkı.
- [ ] Her dört ana gemi parçası için görsel upgrade ayrımı.
- [ ] Grade nedeniyle doğal tavanları farklı olan parçalar.
- [ ] Heat/energy/mass/fuel/maneuver trade-off'larını test et.

**Kabul:** Upgrade yapılmış düşük grade model ile üst grade model arasında **kalıcı** ilerleme farkı var; iki gemi yalnızca farklı renkte değil.

### P5 — Region & Service Loop

- [ ] Farklı kaynak/risk dağılımına sahip en az iki sektör.
- [ ] Radar keşfi, işaretli enkaz, asteroid, tehlike ikonları.
- [ ] Basit istasyon hizmeti: tamir, kargo boşaltma, ekipman/gemi erişimi.
- [ ] Basit kredi ve satış; temel upgrade/maliyet geri bildirimi.
- [ ] Fuel menzil/geri dönüş kararına anlamlı etki eder.

**Kabul:** Oyuncu yalnızca madencilik sahnesini değil, **uç → bul → çıkar/savaş/sök → dön → geliştir** akışını baştan sona oynayabiliyor.

### P6 — Prototip kapanış / vertical slice

- [ ] 2 oynanabilir farklı gemi, birkaç aktif ekipman, en az bir düşman ve birkaç asteroid/loot türü.
- [ ] Mining + combat + salvage + upgrade tek kayıtta birbiriyle uyumlu.
- [ ] Basit save/load, veri doğrulama, çökme/duplikasyon önleme.
- [ ] FPS/VRAM/CPU profili; başlangıç görsel stilinin oyun içi doğrulaması.
- [ ] Kullanıcı testi: ilk 10–20 dakikada yön bulma, araç öğrenme, ödül hissi.
- [ ] Kaybolan item, kapasite/grade istismarı, softlock kontrolleri.

**Kabul:** Tek başına oynanabilen kısa ama başı ve sonu olan demoda temel ürün kalitesi hissediliyor.

### P7 — Discovery & Content Expansion

- [ ] Yeni sektör/gezegen çevresi/asteroid biyomları.
- [ ] Ek gemi modelleri ve daha fazla grade varyasyonu.
- [ ] Bounty/keşif/salvage sözleşmeleri (oyuncuyu tek yola zorlamadan).
- [ ] Düşman varyasyonu ve risk/loot farkları.
- [ ] Sıvı/gaz çıkarma içeriğini görsel ve mekanik olarak derinleştirme.

### P8 — Mother Ship Branch

- [ ] İlk Mother Ship modeli, özgün dış silüet ve iç yerleşim.
- [ ] Uygun hangar/bağlantı alanı; oyuncu gemisinin doklanması.
- [ ] Oda slotları ve ilk işlevsel odalar: storage, repair, salvage/refinery.
- [ ] Grade/native cap, room upgrades, farklı modellerin ayrı planları.
- [ ] Oyuncunun erken/orta oyunda uygun alt grade modeli hedefleyebilmesini destekleyen ekonomi.
- [ ] Daha sonraki içerik hedefi olarak farklı Mother Ship silüetlerine genişleme.

### P9+ — İleri sistemler / karara bağlı

- [ ] Crew/habitat görselleştirme ve hafif işlevler.
- [ ] Birden fazla gemi saklama ve sınırlı görev atama.
- [ ] Daha büyük galaksi, farklı sistemler ve ileri seyahat.
- [ ] Gelişmiş düşmanlar, boss, nadir teknoloji.
- [ ] Hafif oda bazlı otomasyon ve görsel üretim/işleme.
- [ ] Modüler içerik araçları ve genişletilmiş oyunsal varyasyon.

---

## 17. İlk demo için net içerik sınırı

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

---

## 18. Test planı ve kabul kriterleri

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

---

## 19. Riskler ve nasıl yönetilecekleri

1. **Aşırı kapsam:** Büyük galaksi + Mother Ship + life sim + otomasyon + tüm grade sistemi birlikte geliştirilirse oynanabilir demo gecikir. **Önlem:** P0–P6 vertical slice; büyük dalları ertele.
2. **Genel factory oyununa kaymak:** Üretim alt sistemi ana döngüyü yutabilir. **Önlem:** Önceliği tek gemi hareketi, salvage ve loot'a ver.
3. **Dört sahte class oluşması:** Fighter/Miner/Explorer/Salvager etiketleri hardlock hâline gelebilir. **Önlem:** Uyumlu her aktif ekipman her universal hardpoint'e gider; denge bütçelerden.
4. **Grade'i sadece rarity rengine indirgemek:** Tier değer taşımaz. **Önlem:** Native cap ve görsel/kapasite farkı, değiştirilemeyen grade.
5. **Aşırı gerçekçi asteroid parçalanması:** Voxel/mesh kesimi teknik yükü gereksiz büyütebilir. **Önlem:** Surface/vein/fracture node mimarisi.
6. **HUD karmaşası:** Çok fazla bar veya envanter görüntüyü kapatabilir. **Önlem:** Kullanıcının son HUD kararı bağlayıcı.
7. **Referans görseli oyun tasarımı sanmak:** AI görsellerindeki drop isimleri, gövde sınıfları ve market sistemleri kararlaştırılmamış olabilir. **Önlem:** Görsel asset yalnızca stil/silüet içindir.
8. **Mother Ship'in ucuz menüye dönüşmesi:** İkinci ana varlık hissini yitirir. **Önlem:** Model özgünlüğü, hangar ve oda işlevleri, mekânsal görünürlük.
9. **Aşırı cezalandırıcı ölüm:** Cozy döngü kesilir. **Önlem:** Insurance/recovery ilkesi ve anlaşılır risk.

---

## 20. Hâlâ açık kararlar / ajanın kendi kendine kesinleştirmemesi gerekenler

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

---

## 21. Modelleme ve kodlama ajanına başlangıç görevi

> **HEDEF:** Bu tasarımı tam oyuna çevirmeye kalkma. Önce küçük, yüksek kaliteli, test edilebilir **P0/P1** ürettir.

### İlk uygulama emri

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

### Bitmiş sayılma koşulu

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

---

## 22. Karar geçmişi ve kaynak ayrımı

### Kaynak A — `spacegamev1.pdf`, 2 sayfa, 21 Ekim 2026

**Sayfa 1:** Fighter/Explorer/Miner/Salvager yalnızca eğilim. `Head → Damage (attack/mining)`, `Engine → Flying Speed`, `Wings → Maneuver Speed`, `Body → Carry Capacity`; Fuel Capacity ve Fuel Rate hiçbir tek parçaya zorunlu bağlanmamış; Energy Capacity, Module Capacity ve Radar/Visual Range listelenmiş; grade değiştikçe parçaların görünümü değişir. Mining araçları: **Laser** (uzak, orta verim, küçük alan, heat/ışın), **Bomb** (uzak, düşük verim, büyük alan, cephane ve saçılan loot), **Drill** (yakın, yüksek verim, küçük alan).

**Sayfa 2:** Uzay kaynakları **solid/liquid/gas** olarak ayrılır; her tipin kendine özgü depolama kapasitesi gerekir.

### Kaynak B — Önceki Space Miner konuşmaları (Ekim 2026)

- Tek gemi/oyuncu merkezli mining + salvage + combat + loot ve geri dönüş döngüsü.
- Mothership: birçok model, farklı dış silüet ve iç yerleşim, odalar, grade tavanları, crew opsiyonu.
- Tüm önemli varlıklar için `E–SSS` grade; grade yükseltme ile değişmez.
- Evrensel hardpoint, class dışı equip özgürlüğü; mass/heat/energy/fuel/manoeuvre dengesi.
- Fixed weapon/turret hibriti, ayrı passive electronics capacity, insurance/recovery.
- Büyük fleet/faction/mürettebat simülasyonu erken kapsamda yok.

### Kaynak C — 21 Ekim görsel yön konuşması

- İlk pastel low-poly asteroid madenciliği görüntüsünün tarzı beğenildi.
- Daha tepeden/top-down görünüş.
- Solda Hull/Fuel ve aktif skill/item barı; sol altta minimap.
- Oynanış HUD'ından sürekli envanterin kaldırılması.
- Farklı grade/çevre/maden/gemi/düşman için modelleme referansları.

### Kaynak D — Bu belgedeki uygulama önerileri

P0–P9 yol haritasının bölüm sıralaması, data entity adları, ilk teslim kriterleri, teknik nodal madencilik yaklaşımı ve örnek düşman/bölge isimleri **uygulanabilir proje planı oluşturmak için hazırlanmış önerilerdir**. Kullanıcının doğrudan kilitlediği ek oyun içeriği gibi sunulmamalıdır.

---

## 23. Kısa tasarım manifestosu

**Gemiyi sürmek keyifli; bulduğumuz eşya işe yarar; ilerleme görünür; dünya sevimli ama boş değildir.**

Oyuncunun dört farklı gemi sınıfından birini seçip diğerlerini kaybettiği oyun değil; istediği yönde kişiselleştirdiği, doğal sınırları olan farklı gemilere geçtiği bir uzay macerası. Madencilik üç farklı araçla anlamlı seçim yaratır, salvage doğrudan donanım progresyonuna bağlanır ve Mother Ship ikinci büyük kişisel ilerleme hattını oluşturur. Basit, okunaklı ve güzel görünen bir **ilk 10 dakika**, büyük ama tamamlanmamış bir evrenden daha değerlidir.
