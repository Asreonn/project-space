# DECISIONS — GAME_PLAN sonrası kararlar

GAME_PLAN.md v0.1 (21 Ekim 2026) değiştirilmeden tutulur. Sonradan alınan kararlar burada; çakışmada **buradaki daha yeni karar geçerlidir** (GAME_PLAN §0 öncelik kuralı).

| # | Tarih | Karar | Etkilenen bölüm | Durum |
|---|---|---|---|---|
| D-001 | 2026-10-21 | **Oyun motoru: Godot 4 (4.7.x stable), Forward+ renderer, GDScript.** GAME_PLAN'daki "motor açık / Godot-Unity seçimi zorlanmasın" ifadesi bununla kapandı. Gerekçe: açık kaynak, hafif, 3D low-poly + güçlü post-process/shader için yeterli, kullanıcının mevcut Godot projeleri. | §3.3, §15, §20 "Oyun motoru" | [KESİN] |
| D-002 | 2026-10-21 | Repo: `github.com/Asreonn/project-space` (public), MIT lisans (kod). | — | [KESİN] |
| D-003 | 2026-10-21 | İlk hedef M1 Vertical Slice (bkz. ROADMAP.md). M1 kapsamı GAME_PLAN P0 + P1'in Laser kısmı + P2'den tek düşman. | §16, §17 | [HEDEF] |
| D-004 | 2026-10-21 | M1 düşmanı "drone" olarak istendi; GAME_PLAN §9.2 ilk prototip düşmanı olarak "küçük pirate/scout" öneriyor (drone = daha sonra). M1'de tek basit düşman yapılır; adı/silüeti Game Designer + kullanıcı onayıyla kilitlenir. | §9.2 | [AÇIK] |
| D-005 | 2026-10-21 | Dünya sözleşmesi: 1 birim = 1 m, oynanış düzlemi XZ (Y=0), gemi ileri = −Z (Blender'da +Y). | §14.2, §15 | [KESİN] (teknik) |
