extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	arena.muted = true
	arena.set_process(false)
	arena.set_physics_process(false)
	arena.weather_rng.seed = 90817
	var rainy := 0
	var dry := 0
	for i in range(50):
		arena.start_match(true)
		var selected: bool = arena.rain.enabled
		if selected: rainy += 1
		else: dry += 1
		check(arena.wet_clothing.levels[0] == 0 and arena.ren_visual.wetness == 0, "New matches begin with dry clothing")
		arena.wet_clothing.levels[0] = 0.6
		var state: int = arena.weather_rng.state
		arena.start_round()
		check(arena.rain.enabled == selected and arena.weather_rng.state == state, "Rounds preserve weather without rerolling")
		check(arena.wet_clothing.levels[0] == 0.6, "Rounds preserve accumulated moisture")
	check(rainy > 0 and dry > 0, "Seeded match sequence includes both weather states")
	check(rainy < dry, "Rain is less common than dry weather")
	arena.rain.enabled = false
	arena.wet_clothing.levels[0] = 0
	arena.wet_clothing.contact_age[0] = 100
	for i in range(600): arena._process(1.0 / 60.0)
	check(arena.wet_clothing.levels[0] == 0 and arena.rain.body_contacts.is_empty(), "Dry weather cannot wet clothing")
	var state: int = arena.weather_rng.state
	arena.paused = true
	arena._process(1.0 / 60.0)
	check(arena.weather_rng.state == state and not arena.rain.enabled, "Pause cannot reroll weather")
	print("WEATHER TESTS: ", failures, " failures; rainy=", rainy, " dry=", dry)
	arena.free()
	quit(failures)
