# TOOLS — Araç zinciri, MCP sunucuları, açık kaynak kaynaklar

> Sahip: Godot Engineer. Kurulum/sürüm değişince güncelle. Son güncelleme: 2026-10-21.

## 1. Kurulu araçlar

### Box (ajanların paylaştığı Linux makine, Debian 13)

| Araç | Sürüm | Yol / komut | Doğrulama |
|---|---|---|---|
| Godot (editör + headless) | **4.7.2-stable official** | `/usr/local/bin/godot` → `/opt/tools/godot-4.7.2` | `godot --version`, smoke test geçti |
| Godot export templates | 4.7.2.stable (Linux/Windows/macOS/Web/Android/iOS) | `~/.local/share/godot/export_templates/4.7.2.stable/` | — |
| Blender | **5.2.2 LTS** | `/usr/local/bin/blender` → `/opt/tools/blender-5.2.2-linux-x64/` | `blender -b` ile .glb export test edildi |
| Blender MCP addon | mcp-for-blender (addon etkin) | `~/.config/blender/5.2/scripts/addons/blender_mcp.py` | `addon_utils.check` → etkin |
| Godot MCP (Coding-Solo) | `@coding-solo/godot-mcp` 0.1.1 (npm global) | `/home/box/.local/lib/node_modules/@coding-solo/godot-mcp/build/index.js` | kuruldu; istemciye eklenmedi |
| Material Maker | **1.7** | `/usr/local/bin/material-maker` → `/opt/tools/material_maker_1_7_linux/` | GUI; `DISPLAY` gerekli |
| Git LFS | 3.6.1 | `git lfs` | `git lfs install --skip-repo` yapıldı |
| Python + Pillow | Python 3 + Pillow 12.3.0 | `python3` | — |
| uv / uvx, Node + npx | uv 0.13.0 | `/usr/local/bin/uvx`, `/usr/bin/npx` | — |

Box'ta GUI uygulamaları (Godot editör, Blender, Material Maker) ajanın kendi masaüstünde (`DISPLAY`) açılır. Box'ta **GitHub kimliği yok** → push yok (AGENTS.md §3 "Push nereden?").

### PC (asreonsDev, Arch)

Godot 4.7.2 (`/usr/bin/godot`), Blender 5.2.2 LTS (`~/.local/bin/blender`), git-lfs 3.8, `gh` (Asreonn olarak giriş yapılı), uvx, Node 24. Repo klonu: `~/uwu/Scripts/games/godot/project-space`.

### Sık komutlar

```bash
godot --headless --path . --import                              # import
godot --headless --path . --script res://tests/smoke_test.gd    # smoke test
godot --headless --path . --export-release "Linux" build/ps.x86_64   # (preset eklenince)
blender -b art/blender/ships/starter_shuttle_01.blend --python-expr \
  "import bpy; bpy.ops.export_scene.gltf(filepath='assets/models/ships/starter_shuttle_01.glb', export_yup=True, export_apply=True)"
```

## 2. MCP sunucuları (ajanlara kullanıcı ekler — burada yalnız komutlar)

### 2.1 Blender MCP — `ahujasid/blender-mcp` (artık "MCP for Blender")

- Repo: https://github.com/ahujasid/blender-mcp (→ `ahujasid/mcp-for-blender`). PyPI paketi **`blender-mcp` → `mcp-for-blender`** olarak yeniden adlandırıldı; eski `uvx blender-mcp` hâlâ çalışıyor.
- Mimari: Blender içinde addon (socket server, varsayılan `localhost:9876`) + `uvx mcp-for-blender` MCP sunucusu (stdio).
- **Addon kurulumu** (box'ta yapıldı; PC'de gerekirse): `uvx mcp-for-blender install-addon` → Blender: Edit → Preferences → Add-ons → "Interface: MCP for Blender" etkinleştir. Addon, Blender GUI açılınca sunucuyu otomatik başlatır (N paneli → "MCP for Blender" → Start MCP Server). `blender -b` (background) modunda **çalışmaz**.
- **MCP istemci konfigürasyonu:**

```json
{
  "mcpServers": {
    "blender": {
      "command": "uvx",
      "args": ["mcp-for-blender"],
      "env": { "DISABLE_TELEMETRY": "true", "BLENDER_HOST": "localhost", "BLENDER_PORT": "9876" }
    }
  }
}
```

  - Claude Code: `claude mcp add blender -e DISABLE_TELEMETRY=true -- uvx mcp-for-blender`
  - Codex: `codex mcp add blender -- uvx mcp-for-blender`
  - Tek satır kurulum (istemcileri otomatik yapılandırır, isteğe bağlı): `curl -LsSf https://www.mcp-for-blender.com/install.sh | sh`
- Notlar: Aynı Blender için tek MCP sunucu örneği çalıştır. Box paylaşımlı olduğundan iki ajan aynı anda Blender MCP kullanacaksa ikinci Blender'da N panelinden portu değiştir (ör. 9877) ve o ajanın `BLENDER_PORT`'unu eşle. Telemetri varsayılan olarak anonim kullanım kaydı gönderir → `DISABLE_TELEMETRY=true`. Addon'un Poly Haven / Sketchfab / Hyper3D / Hunyuan3D entegrasyonları opsiyonel; dış API anahtarı isteyenleri kullanma (lisans/kota).

### 2.2 Godot MCP — `Coding-Solo/godot-mcp` (önerilen)

- Repo: https://github.com/Coding-Solo/godot-mcp (MIT, ~6.2k★). npm: `@coding-solo/godot-mcp`. Gereksinim: Node ≥ 18, Godot.
- Yetenekler: editörü açma, projeyi debug modda çalıştırma, **debug çıktısı/hata yakalama**, çalıştırmayı durdurma, sürüm/proje bilgisi, sahne oluşturma/düğüm ekleme/kaydetme, MeshLibrary export, UID yönetimi (4.4+). Editör eklentisi gerektirmez (CLI tabanlı).
- Konfigürasyon:

```json
{
  "mcpServers": {
    "godot": {
      "command": "npx",
      "args": ["@coding-solo/godot-mcp"],
      "env": { "GODOT_PATH": "/usr/local/bin/godot", "DEBUG": "false" }
    }
  }
}
```

  - Claude Code: `claude mcp add godot -e GODOT_PATH=/usr/local/bin/godot -- npx @coding-solo/godot-mcp`
  - Box'ta global kurulu: `"command": "node", "args": ["/home/box/.local/lib/node_modules/@coding-solo/godot-mcp/build/index.js"]`.
  - PC'de `GODOT_PATH=/usr/bin/godot`.

### 2.3 Alternatif — `ee0pdt/Godot-MCP`

- Repo: https://github.com/ee0pdt/Godot-MCP (MIT, ~620★, son push Mart 2025 → 4.7 uyumluluğu doğrulanmadı).
- Editör eklentisi (`addons/godot_mcp`, WebSocket) + Node sunucusu: canlı editörde node/script/sahne okuma-yazma. Kurulum: repo'yu klonla → `cd server && npm install && npm run build` → `addons/godot_mcp`'yi projeye kopyala ve Project Settings → Plugins'ten etkinleştir → istemci: `"command": "node", "args": ["<repo>/server/dist/index.js"], "env": {"MCP_TRANSPORT": "stdio"}`.
- Repo'ya addon eklemek Engineer kararıdır; şimdilik **eklenmedi**.

## 3. VFX / shader kaynakları (Godot 4)

| Kaynak | URL | Lisans | Kullanım |
|---|---|---|---|
| Godot Shaders | https://godotshaders.com | Shader başına (çoğu **CC0**, bazıları MIT/CC-BY) — sayfadaki lisansı kontrol et | Nebula, starfield, dissolve, toon, outline, force field, laser beam, screen-space post FX (vignette, CA, CRT). Godot 4 filtresini kullan. |
| GDQuest — Godot Shaders | https://github.com/gdquest-demos/godot-shaders | Kod/shader/sahne **MIT**; texture & modeller **CC-BY-NC-SA 4.0** (ticari değil → **asset'lerini kopyalama**, sadece kodu/shader'ı al) | Shader örnek kütüphanesi (`main` = Godot 4). |
| GDQuest — Visual Effects | https://github.com/gdquest-demos/godot-visual-effects | Aynı: kod MIT, art **CC-BY-NC-SA 4.0** | Partikül/VFX demoları (çoğu Godot 3 döneminden; `master` dalını kontrol et, porting gerekebilir). |
| GDQuest — Godot 4 VFX assets | https://github.com/gdquest-demos/godot-4-VFX-assets | Aynı: kod MIT, art **CC-BY-NC-SA 4.0** | Godot 4 hazır VFX örnekleri — shader/sahne kodunu al, texture'ları kendin üret veya CC0 (Kenney) ile değiştir. |
| Godot demo projects | https://github.com/godotengine/godot-demo-projects | MIT | `3d/particles`, `3d/volumetric_fog`, `3d/graphics_settings`, `misc/compositor_effects` (post-process örnekleri). |
| Effekseer for Godot 4 | https://github.com/effekseer/EffekseerForGodot4 (son sürüm 1.80.5.1, Temmuz 2026) · editör: https://effekseer.github.io | MIT | Node tabanlı partikül editörü + Godot runtime GDExtension. Sadece Engineer onayıyla `addons/`'a. `.efkefc` LFS'te. |
| Material Maker | https://github.com/RodZill4/material-maker (1.7, box'ta kurulu) | MIT (araç); üretilen dokular senin | Prosedürel PBR/stylized doku, Godot materyal export. |
| Kenney (CC0) | https://kenney.nl/assets — öne çıkanlar: **Space Kit**, **Particle Pack**, **Smoke Particles**, **UI Pack (Sci-Fi)**, **Sci-Fi Sounds**, **Impact Sounds** | **CC0** | Placeholder modeller, partikül texture'ları, UI, SFX. |
| Poly Haven (CC0) | https://polyhaven.com (HDRI, texture, model) | **CC0** | Look-dev HDRI, gerekirse doku. Low-poly stile dikkat. |
| Quaternius (CC0) | https://quaternius.com — **Ultimate Space Kit**, Spaceships packs | **CC0** | Low-poly gemi/asteroid/istasyon placeholder & referans. |
| Phantom Camera | https://github.com/ramokz/phantom-camera | MIT | Kamera takip/zoom/shake addon'u (opsiyonel, Engineer kararı). |
| gdUnit4 | https://github.com/godot-gdunit-labs/gdUnit4 | MIT | Birim test framework'ü (opsiyonel). |
| Godot debug menu | https://github.com/godot-extended-libraries/godot-debug-menu | MIT | FPS/frametime overlay (opsiyonel). |

**Kural:** Üçüncü parti her şey `CREDITS.md`'ye (ad, yazar, URL, lisans, yol). CC-BY ise atıf zorunlu. Lisansı belirsiz şey ekleme. Referans görsellerdeki (AI konsept) öğeler oyun asset'i olarak kullanılmaz.

## 4. Godot 4 VFX/post-process hızlı notlar

- Glow: `Environment.glow_enabled`, emissive enerji > 1, `glow_hdr_threshold` ~1.0–1.2; bloom düşük.
- Tonemap: AgX (4.4+) cozy pastellerde daha doğal; Filmic alternatif.
- Ekran efektleri: `CanvasLayer` + `ColorRect` + `canvas_item` shader (vignette/CA/grain) veya `CompositorEffect` (4.3+).
- Partiküller: `GPUParticles3D` + `ParticleProcessMaterial`; trail için `trail_enabled` veya ribbon mesh.
- Volumetric fog nebula hissi için denenebilir ama top-down kamerada pahalı olabilir; önce shader/quad katmanları.
