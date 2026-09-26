extends SceneTree
const Rain = preload("res://scripts/rain_effect.gd")
const Fighter = preload("res://scripts/fighter.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1

func _initialize() -> void:
	var rain := Rain.new()
	var fighter := Fighter.new()
	fighter.reset(400, 1)
	var bodies := [rain.body_polygon(fighter)]
	var hit := rain.trace_drop(Vector2(400, 100), Vector2(400, 630), 1, 562, bodies)
	check(hit.get("kind") == "body" and hit.pos.y < 400, "Swept drop hits body before floor")
	hit = rain.trace_drop(Vector2(600, 500), Vector2(600, 630), 1, 562, bodies)
	check(hit.get("kind") == "ground" and hit.pos.y == 562, "Ground collision has exact contact point")
	hit = rain.trace_drop(Vector2(1100, 30), Vector2(1100, 600), 0, 480, [])
	check(hit.get("kind") == "roof", "Distant drops collide with temple roof")
	hit = rain.trace_drop(Vector2(1100, 30), Vector2(1100, 600), 1, 562, [])
	check(hit.get("kind") == "ground", "Background roof cannot shelter foreground arena")
	hit = rain.trace_drop(Vector2(400, 100), Vector2(400, 650), 2, 615, bodies)
	check(hit.get("kind") == "ground", "Foreground drops pass in front of body")
	fighter.crouching = true
	hit = rain.trace_drop(Vector2(400, 340), Vector2(400, 380), 1, 562, [rain.body_polygon(fighter)])
	check(hit.is_empty(), "Crouching lowers the collision shape")
	fighter.crouching = false
	fighter.pos.y = 440
	hit = rain.trace_drop(Vector2(400, 180), Vector2(400, 350), 1, 562, [rain.body_polygon(fighter)])
	check(hit.get("kind") == "body" and hit.pos.y < 300, "Collision follows airborne fighter")
	fighter.reset(400, 1)
	var contact := Rain.new()
	contact.drops.clear()
	contact.drops.append({"pos": Vector2(400, 340), "layer": 1, "ground": 562.0, "speed": 1000.0})
	contact.update(0.05, [fighter])
	check(contact.splashes.size() == 1 and contact.splashes[0].kind == "body", "Body contact produces a splash")
	check(contact.drops[0].pos.y < 0, "Hit drop respawns instead of crossing the body")
	for drop in rain.drops:
		if drop.layer == 2:
			check(drop.ground <= 590, "Near rain lands on the paving, not the platform wall")
	var start := Time.get_ticks_usec()
	for i in range(600):
		rain.update(1.0 / 60.0, [fighter])
	print("RAIN CPU update average: ", (Time.get_ticks_usec() - start) / 600.0 / 1000.0, " ms")
	check(rain.drops.size() == Rain.DROP_COUNT and rain.splashes.size() <= Rain.MAX_SPLASHES, "Particle storage stays bounded")
	check(fighter.health == 100 and fighter.pos == Vector2(400, 562), "Weather cannot alter combat state")
	var drops := rain.drops.duplicate(true)
	var splashes := rain.splashes.duplicate(true)
	var time := rain.elapsed
	var state := rain.rng.state
	rain.update(0.5, [fighter], true)
	check(rain.drops == drops and rain.splashes == splashes and rain.elapsed == time and rain.rng.state == state, "Pause freezes drops, impacts and RNG")
	rain.update(1.0 / 60.0, [fighter])
	check(rain.elapsed > time, "Rain resumes after pause")
	print("RAIN TESTS: ", failures, " failures")
	quit(failures)
