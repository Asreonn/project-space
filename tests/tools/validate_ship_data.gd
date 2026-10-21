extends SceneTree
## Headless data check: loads every ShipHullDefinition in res://data/ships/*.tres
## (other resources there are skipped), runs
## ShipDataValidator and ShipStatsResolver, exits 0 on pass, 1 on failure.
##
##   godot --headless --path . -s res://tests/tools/validate_ship_data.gd [-- --mode=mvp|contract --no-assets]
## Defaults: mode mvp (D-011: credits-only L2/L3) and models required.

const SHIPS_DIR := "res://data/ships"


func _init() -> void:
	var mode := ShipDataValidator.Mode.MVP
	var require_assets := true
	for arg in OS.get_cmdline_user_args():
		if arg == "--mode=contract":
			mode = ShipDataValidator.Mode.CONTRACT
		elif arg == "--no-assets":
			require_assets = false

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

	print("Validating %d hull(s), mode %s, require assets %s" % [hulls.size(), ShipDataValidator.Mode.keys()[mode], require_assets])
	var result := ShipDataValidator.validate_catalog(hulls, mode, require_assets)
	if not str(result).is_empty():
		print(str(result))
	for hull in hulls:
		for n in range(1, hull.authored_up_to_level + 1):
			print("Resolved stats %s (grade %s, all parts L%d):" % [hull.id, Grade.to_label(hull.native_grade), n])
			var stats := ShipStatsResolver.resolve(hull, ShipInstanceState.create_for(hull, n))
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
