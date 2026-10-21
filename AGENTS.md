# AGENTS.md — Project Space

Bu dosya repoda çalışan **tüm ajanlar (ve insanlar)** için bağlayıcı kurallardır. Önce bunu, sonra kendi brief'ini oku.

- Tasarım kaynağı: [`docs/GAME_PLAN.md`](docs/GAME_PLAN.md) (bağlayıcı). Kararlar ve güncellemeler: [`docs/DECISIONS.md`](docs/DECISIONS.md).
- Yol haritası: [`docs/ROADMAP.md`](docs/ROADMAP.md) — şu an hedef **M1 Vertical Slice**.
- Rol brief'leri: [`docs/briefs/`](docs/briefs/).
- Araçlar / MCP / açık kaynak VFX kaynakları: [`docs/TOOLS.md`](docs/TOOLS.md).
- Motor: **Godot 4.7.x stable, Forward+, GDScript** (C# yok). Proje kökü = repo kökü.

## 1. Ekip ve roller

| Rol | Brief | Sorumluluk (kısa) |
|---|---|---|
| **Game Designer (lead)** | [game-designer.md](docs/briefs/game-designer.md) | Vizyon, kapsam, `[KESİN]` kararların koruyucusu, roadmap/milestone kabulü, tasarım çakışmalarında son söz (kullanıcıdan sonra). |
| **Gameplay Designer** | [gameplay.md](docs/briefs/gameplay.md) | Uçuş hissi, madencilik/loot döngüsü, düşman davranışı, tuning verisi (`data/`), oynanış kodu. |
| **3D Modeler** | [modeling.md](docs/briefs/modeling.md) | Blender'da low-poly cute/cozy modeller, modüler gemi parçaları, .glb export. |
| **UI Designer** | [ui.md](docs/briefs/ui.md) | HUD, menüler, ikonlar, Theme, font. |
| **VFX Engineer** | [vfx.md](docs/briefs/vfx.md) | Shader, partikül, post-process, ortam (nebula/yıldız), materyal look-dev. |
| **Godot Engineer** | [engineering.md](docs/briefs/engineering.md) | Mimari, `project.godot`, çekirdek sistemler, veri şeması, test/CI, **PR review + merge**. |

## 2. Dosya sahipliği (çakışmayı önlemek için)

Sahibi olmadığın yolda değişiklik gerekiyorsa: küçükse PR'da açıkça belirt ve sahibini reviewer yap; büyükse önce sahibine iş iste (issue / PR açıklaması).

| Yol | Sahip | Not |
|---|---|---|
| `project.godot`, `export_presets.cfg`, `.gitignore`, `.gitattributes` | Godot Engineer | Input map, layer'lar, autoload'lar dahil. Diğerleri istek yazar. |
| `addons/**` | Godot Engineer | Yeni addon = PR + `docs/TOOLS.md` kaydı + lisans kontrolü. |
| `scripts/core/**`, `scripts/data/**`, `scripts/debug/**` | Godot Engineer | Autoload'lar, event bus, veri şeması (`Resource` sınıfları), debug overlay. |
| `scenes/main/**` | Godot Engineer | Ana sahne kompozisyonu. |
| `tests/**`, `.github/**` | Godot Engineer | Herkes kendi sistemine test ekleyebilir (PR ile). |
| `scripts/ship/**`, `scripts/mining/**`, `scripts/combat/**`, `scripts/loot/**` | Gameplay Designer | Mimari sözleşmeye (Engineer) uyar. |
| `scenes/ship/**`, `scenes/world/**`, `scenes/enemies/**`, `scenes/pickups/**` | Gameplay Designer | Model örnekleri Modeler'dan, efekt düğümleri VFX'ten gelir. |
| `data/**` | Gameplay Designer | Tuning değerleri; şema değişikliği Engineer'dan. |
| `assets/models/**`, `assets/textures/**`, `art/**` | 3D Modeler | `.blend` kaynakları `art/blender/`, export `.glb` `assets/models/`. |
| `assets/ui/**`, `assets/fonts/**`, `scenes/ui/**`, `scripts/ui/**` | UI Designer | |
| `assets/shaders/**`, `assets/materials/**`, `assets/vfx/**`, `scenes/vfx/**`, `scripts/vfx/**` | VFX Engineer | `WorldEnvironment`/post-process ayarları dahil (`scenes/vfx/environment_*.tres`). |
| `assets/audio/**` | Game Designer (geçici) | Lisanslı/CC0 + `CREDITS.md`. |
| `docs/**` | Game Designer | `docs/TOOLS.md` → Godot Engineer; her rol kendi brief'ine "Notlar/Öğrenilenler" ekleyebilir. |
| `README.md`, `AGENTS.md`, `CREDITS.md`, `PROGRESS.md` | Game Designer + Godot Engineer | `PROGRESS.md`: herkes kendi satırını günceller, bitmeyeni bitti yazma. |

**Sahne sahipliği kuralı:** Bir `.tscn` dosyasını aynı anda iki branch değiştirmesin. Başkasının sahnesine eklemek için kendi alt sahneni (`scenes/<senin klasörün>/x.tscn`) oluştur, sahibinden instance etmesini iste.

## 3. Branch / PR akışı

- `main` her zaman açılabilir ve smoke testi geçer. **`main`'e doğrudan commit yok** (bootstrap commit'i hariç).
- Branch adı: `<rol>/<kısa-konu>` — roller: `design`, `gameplay`, `model`, `ui`, `vfx`, `eng`.
  Örnek: `model/starter-ship-blockout`, `vfx/laser-beam`, `gameplay/flight-feel`, `ui/hud-m1`.
- Küçük, odaklı PR'lar (ideal < 400 satır kod; asset PR'ları ayrı). PR açıklaması: ne, neden, nasıl test edildi, ekran görüntüsü/GIF (görsel değişiklikte zorunlu), dokunulan "başkasının" yolları.
- **Godot Engineer review eder ve merge eder** (squash merge). Tasarım kararını etkileyen PR'larda Game Designer onayı da gerekir.
- Merge öncesi: `main`'den rebase/merge et, smoke test geçsin, editörde import hatası olmasın.
- Force-push yalnızca kendi feature branch'ine. `main`'de force-push, history rewrite, tag silme **yasak**.

### Push nereden?

- **Box** (`/workspace/project-space`, ajanların paylaştığı Linux makine): repo public olduğu için `clone`/`fetch`/`pull` çalışır, ama box'ta GitHub kimlik bilgisi **yok** → `git push` çalışmaz. Token arama/kopyalama **yapma**.
  Box'ta çalışırken: branch'inde commit at, sonra
  1. `git bundle create /workspace/out/<branch>.bundle main..<branch>` (veya `git format-patch main --stdout > x.patch`),
  2. dosyayı PC'ye aktar (ana ajan `CopyFromBox` ile),
  3. PC'deki klonda: `git fetch /path/<branch>.bundle <branch>:<branch> && git push -u origin <branch> && gh pr create --fill`.
- **PC** (`~/uwu/Scripts/games/godot/project-space`): `gh` ile giriş yapılı; push ve `gh pr create` buradan yapılır.

## 4. Commit kuralları

- Yazar: kullanıcının normal git kimliği (`Asreonn <asrinylmz2@gmail.com>`). Box'ta: `git config user.name Asreonn && git config user.email asrinylmz2@gmail.com` (repo-local).
- Format: `type(scope): kısa özet` — type: `feat`, `fix`, `art`, `vfx`, `ui`, `data`, `docs`, `refactor`, `test`, `chore`. Örnek: `art(ships): starter shuttle blockout (E grade)`.
- **YASAK:** `Co-authored-by:`, `Generated with ...`, `🤖`, "AI", model/araç adı içeren trailer veya imza. Commit mesajı yalnızca değişikliği anlatır.
- Büyük binary'yi LFS'siz ekleme (bkz. §6). `.env`, token, anahtar commit etme.

## 5. İsimlendirme

- **Dosyalar:** `snake_case` — `starter_shuttle_01.glb`, `ship_controller.gd`, `hud_main.tscn`, `laser_beam.gdshader`.
- **GDScript:** `class_name PascalCase`, fonksiyon/değişken `snake_case`, sabit `UPPER_SNAKE`, sinyal geçmiş zaman (`cargo_full`, `asteroid_depleted`). Statik tip kullan (`var speed: float`). [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).
- **Node'lar:** `PascalCase` (`ShipRoot`, `HardpointLeft`).
- **Veri id'leri:** `snake_case` + numara: `starter_shuttle_01`, `head_starter_shuttle_01`, `laser_mk1`. Grade ayrı alandır (`native_grade = "E"`), id'ye gömülmez; görsel grade varyantında dosya soneki `_e`, `_d` … kullanılır.
- **Blender objeleri (GAME_PLAN §14.2):** `Head_<id>`, `Body_<id>`, `Engine_<id>`, `Wings_<id>`, boş obje `Hardpoint_<konum>` (`Hardpoint_L`, `Hardpoint_R`, `Hardpoint_Nose`), aktif donanım `Weapon_*`, `MiningLaser_*`, `MiningBomb_*`, `MiningDrill_*`, motor izi çıkış noktası `FX_EngineTrail_<n>`.
- **Branch:** `<rol>/<konu>` (bkz. §3).

### Dünya / ölçek sözleşmesi

- 1 birim = 1 m. Oynanış düzlemi **XZ, Y = 0** (2.5D top-down). Yukarı = +Y.
- Gemi burnu Godot'ta **−Z** (Node3D ileri yönü). Blender'da (Z-up) burun **+Y**'ye bakar; glTF export "+Y Up" açık → Godot'ta −Z olur. Blender Top view'da (Numpad 7) burun ekranın üstüne bakar.
- Pivot: geminin kütle merkezi, Y=0 düzleminde. Starter gemi ~3 m boy (öneri).
- Fizik katmanları `project.godot`'ta adlandırıldı: player, enemy, asteroid, pickup, player_projectile, enemy_projectile, world.

## 6. Git LFS

LFS'e giden uzantılar `.gitattributes`'ta: `blend glb fbx obj psd kra exr hdr wav ptex efkefc`. Klonladıktan sonra `git lfs install` (bir kez). Referans PNG/PDF'ler (~33 MB) ve küçük oyun texture'ları normal git'te — public repoda LFS bant genişliği kotası klonlarda tükenmesin diye. Tek dosya > 10 MB ise PR'da belirt.

## 7. Çalıştırma / test

```bash
godot -e --path .                                              # editör
godot --path .                                                 # oyunu çalıştır
godot --headless --path . --import                            # ilk import (CI/box)
godot --headless --path . --script res://tests/smoke_test.gd  # smoke test (exit 0 = OK)
```

## 8. Tasarım disiplini (GAME_PLAN §0, §20)

- `[KESİN]` ve `[PDF]` kararlarını bozma. `[ÖNERİ]`/`[AÇIK]` olanı kendi başına kesinleştirme; geçici değer kullan ve `balance_prototype` / `# TBD` diye işaretle.
- Referans görseller **stil/silüet** içindir; içlerindeki isimler, stat tabloları, alt envanter barı, sağdaki minimap gibi şeyler kural değildir.
- Sınıf kilidi yok: Fighter/Explorer/Miner/Salvager yalnız eğilim. Universal hardpoint.
- HUD: sol üst Hull+Fuel, sol kenarda aktif slot barı, sol altta yuvarlak minimap, **altta envanter barı yok**.
- Bitmeyen işi bitti diye yazma; sonuçları `PROGRESS.md`'ye gerçekçi yaz.
