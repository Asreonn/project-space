# tests/

**Sahip / Owner:** Godot Engineer

Headless testler (box/CI). Önce bir kez `godot --headless --path . --import`.

| Komut | Ne yapar |
|---|---|
| `godot --headless --path . --script res://tests/smoke_test.gd` | Ana sahneyi yükler, birkaç frame çalıştırır |
| `godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json` | GUT birim testleri (`tests/unit/`) |
| `godot --headless --path . -s res://tests/tools/validate_ship_data.gd` | `data/ships/*.tres` için ShipDataValidator + ShipStatsResolver (M1: L1 dolu, eksik model = uyarı). Final içerik: `-- --authored-level=3 --require-assets` |
| `tests/tools/lint_strict.sh` | Tip/unsafe uyarılarını hata sayarak tüm scriptleri parse eder |

- `tests/unit/`: GUT testleri (`test_*.gd`, `extends GutTest`).
- `tests/helpers/`: testlerde kullanılan veri kurucuları (`TestShips`).
- `tests/tools/`: headless araçlar.

Kurallar için kökteki [AGENTS.md](../AGENTS.md) dosyasına bak.
