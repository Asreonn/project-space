# Space Miner — Modelleme Ajanı için Görsel Referans Paketi

## Kaynak önceliği
1. `03_Source/spacegamev1.pdf` (kullanıcının özgün, iki sayfalık mekanik notları): oyun kuralları için esas kaynak.
2. Bu README: kullanıcının son görsel yönlendirmesi ve PDF'deki kuralların uygulanabilir özeti.
3. `01_Modeling_Atlases/`: görsel referans; içindeki yazılar/öğe isimleri kesin mekanik değildir.
4. `02_Gameplay_Mood/`: renk, kamera, atmosfer, ışık, düşük poligon hedefi; bu eski sahnelerdeki alt envanter barını uygulama.

## Sabit görsel hedef
- Sevimli / cozy / chill, basit ve okunabilir **low-poly 2.5D**, hafif pastel-neon uzay; gereksiz yüksek detay yok.
- Kamera gerçek oynanışta **neredeyse tam üstten (top-down)**. Konsept renderlardaki eğik sinematik açıları zorunlu kabul etme.
- Başlangıç gemisi: küçük, açık kırık-beyaz gövde, yumuşak turuncu detaylar, mavi motor izi; köşeler hafif yuvarlak ama az poligonlu.
- Kayalar basit facet yüzeyli. Kaynaklar uzaktan seçilebilecek renk ve silüette. Karmaşık materyal ve ağır efektlerden kaçın.

## GEMİ / STAT / GRADE — PDF Sayfa 1
- Fighter, Explorer, Miner, Salvager: **sabit ve birbirini dışlayan sınıflar DEĞİL**, geminin aynı anda farklı oranlarda sahip olabileceği **eğilim / skorlar**.
- Değiştirilebilir ana parça-slot şeması:
  - Head → **Damage** (saldırı ve madencilik)
  - Engine → **Flying Speed**
  - Wings → **Maneuver Speed**
  - Body → **Carry Capacity** (hacim)
- Grade arttıkça ana parçaların **görünüşü/geometrisi de değişir**. Basit başlangıç parçasından daha gelişmiş fakat aynı tasarım ailesine ait varyantlar üret.
- PDF'deki diğer gemi istatistikleri: Fuel Capacity; Fuel Rate; Energy Capacity (pasif skill limiti); Module Capacity (silah/madencilik aletleri); Radar Range (görsel menzile de etki eder).
- PDF'de Fuel Capacity ve Fuel Rate herhangi bir belirli görünür parçaya bağlanmıyor (notta 'None'); bu nedenle bunları zorunlu 'Fuel Tank' parça slotuna eşitleme. Görsellerde öyle bir öğe görünmesi konsept önerisidir, kural değildir.
- Aynı temel hull üzerinde farklı head/engine/wings/body kombinasyonlarının değiştirilebilir olmasına odaklan; 'fighter gemisi ayrı sınıftır' gibi katı bir model ağacı kurma.

## MADENCİLİK ARAÇLARI — PDF Sayfa 1
- **Laser:** Uzaktan ısıtarak/eriterek, küçük alana etki; orta verim. Uygun toplama kapasitesi varsa çıkan kaynak envantere aktarılabilir.
- **Bomb:** Uzaktan fırlatılan, çarpınca veya istendiğinde patlayabilen, mühimmat kullanan araç; geniş alana etki, düşük verim. Kaynakların etrafa yayılması ve sonra yaklaşılarak toplanması beklenir.
- **Drill:** Yakından kayaya girerek çalışır; küçük alana etki, yüksek verim, sınırsız kullanım; uygun toplama kapasitesinde kaynak otomatik aktarılabilir.
- Modelleme karşılığı: üç farklı ve üstten bakışta hemen ayırt edilen uç parça. Laser: ince ısı başlığı; Bomb: yuvarlak küçük lançer; Drill: kısa konik matkap.

## KAYNAK TİPLERİ — PDF Sayfa 2
- Kaynaklar **katı, sıvı, gaz** olarak ayrılır; **her birine özel kapasite** gerekir.
- Görsel öneri (PDF'de nesne isimleri kesinleşmemiştir): Katı için kaya/cevher kristalleri ve kasalar; sıvı için damla simgesi ve sızdırmaz kapsül; gaz için bulut/sis ve basınç tüpü.
- Cevher renkleri, örnek mineral adları, nadirlik seviyeleri ve özel bölgeler atlaslarda tasarım örneğidir; kaynak PDF tarafından kesinleştirilmiş değildir.

## HUD — Kullanıcının son görsel kararı
- Sol üst: **CAN ve FUEL** barları. Gerekirse enerji daha sonra ayrıca değerlendirilir.
- Ekranın **sol kenarında** küçük dikey aktif skill/takılı ekipman barı.
- **Sol alt köşede yuvarlak minimap**.
- Normal oynanışta **envanter ızgarası / alt yatay eşya barı görünmesin**. Eski referanslardaki envanter çubuğunu kopyalama.
- UI minimal, ince hatlı, yumuşak köşeli; oyun alanını kaplamayacak.

## BAĞIMSIZ REFERANS TASARIMLARI (PDF dışındaki kullanıcı isteği)
- Düşman gemileri: kullanıcı modelleme referansı istiyor. Scout, korsan avcı, ağır yağmacı ve büyük düşman gibi varyasyonlar **öneri**. Bunların kesin oyun içi sınıf/stat kuralları PDF'de yazmıyor.
- Çevre: normal asteroid kuşağı, kristal yatağı, soğuk alan, gaz bulutu, hurdalık gibi düşük detaylı bölgeler **öneri**; ana kaynak ayrımı katı/sıvı/gaz.
- Mothership / istasyon: önceki oyun sohbetlerinden bir hedef; küçük geminin yanaşabildiği büyük ama modüler bir yapı. PDF'deki iki sayfada ayrıntılı bir mimarisi yok.

## İlk üretilecek minimum asset seti
1. 1 ortak starter ship hull + ayrı Head/Engine/Wings/Body slot meshleri.
2. 4 ana parça için en az iki basit grade görsel varyasyonu (grade sayısı geçici; kesin kademe sayısı verilmedi).
3. Laser, Bomb, Drill: üç modül modeli ve küçük HUD ikonu.
4. 3 küçük asteroid tipi: sıradan, metalik/cevherli, kristalli.
5. Katı/sıvı/gaz için 3 ayrı pickup ve üç kapasite simgesi.
6. 2 basit düşman silüeti: küçük hızlı ve iri yavaş.
7. 1 yıldızlı/nebula arka plan, çok düşük yoğunluklu çok katmanlı parallax.
8. HUD: can/fuel, soldaki 3 aktif ekipman yuvası, sol alttaki minimap.

## Referans paftaları nasıl kullanılmalı?
- `01_Modeling_Atlases`: bütün elementleri tanımak için; _ayrı bir 3D mesh / icon_ oluştururken silüete bak.
- `02_Gameplay_Mood`: ana renkler, ortam ölçüsü, okunabilirlik ve hissiyat için.
- GÖRSELDEKİ 'Fighter/Explorer/Miner/Salvager' başlıkları UI kategorisi / örnek build; oyun mekaniğinde kilitli class seçimine dönüştürülmeyecek.
- GÖRSELDEKİ yakıt tankı, enerji çekirdeği, çeşitli rarity ve yeni gezegen/düşman adları varsayılan sistem kuralları değildir.

## Ajanın ilk görevi
Starter gemiyi ortografik üstten görünüşle blokout et; dört değişebilir ana parçayı ayrı objeler yap; aynı gemide hem mining hem combat ekipmanı takılıyken silüeti okunabilir tut. Ardından tek bir meteor, üç madencilik ekipmanı, kaynak pickup'ları ve üç öğeli sol skill barıyla mini oynanış sahnesi kur.
