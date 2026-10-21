extends SceneTree
## Headless data check: loads every ShipHullDefinition in res://data/ships/*.tres
## (other resources there are skipped), runs
## ShipDataValidator and ShipStatsResolver, exits 0 on pass, 1 on failure.
##
##   godot --headless --path . -s res://tests/tools/validate_ship_data.gd [-- --authored-level=N --require-assets]
## Defaults are the M1 settings: authored level 1, missing models = warnings.

const SHIPS_DIR := "res://data/ships"


func _init() -> void:
	var authored := 1
	var require_assets := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--authored-level="):
			authored = int(arg.get_slice("=", 1))
		elif arg == "--require-assets":
			require_assets = true

	var hulls: Array[ShipHullDefinition] = []
	for file in DirAccess.get_files_at(SHIPS_DIR):
		if not file.ends_with(".tres"):
			continue
		var path := "%s/%s" % [SHIPS_DIR, file]
		var hull := load(path) as ShipHullDefinition
		if hull == null:
			print("skip: %s is not a ShipHullDefinition" % path)
			continue
		hulls.append(hull)

	print("Validating %d hull(s), authored level %d, require assets %s" % [hulls.size(), authored, require_assets])
	var result := ShipDataValidator.validate_catalog(hulls, authored, require_assets)
	if not str(result).is_empty():
		print(str(result))
	for hull in hulls:
		print("Resolved stats %s (grade %s, all parts L1):" % [hull.id, Grade.to_label(hull.native_grade)])
		var stats := ShipStatsResolver.resolve(hull, ShipInstanceState.create_for(hull))
		for stat: StringName in stats.keys():
			var cap := " (cap %s)" % hull.upgrade_caps[stat] if hull.upgrade_caps.has(stat) else ""
			print("  %-20s %8.2f%s" % [stat, stats[stat], cap])
	if hulls.is_empty():
		printerr("FAIL: no hulls found")
		quit(1)
	elif result.is_ok():
		print("PASS: %d error(s), %d warning(s)" % [result.errors.size(), result.warnings.size()])
		quit(0)
	else:
		printerr("FAIL: %d error(s)" % result.errors.size())
		quit(1)
