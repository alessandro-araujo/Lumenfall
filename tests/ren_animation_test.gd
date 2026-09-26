extends SceneTree

const Fighter = preload("res://scripts/fighter.gd")
const Rig = preload("res://scripts/ren_walk_rig.gd")
const Visual = preload("res://scripts/ren_visual.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var rig := Rig.new()
	var body_ok := true
	var soles_ok := true
	var triangles_ok := true
	for sample in range(120):
		var points := rig.vertices(float(sample) / 120.0, 1.0)
		var torso_dy := points[0].y - (rig.rest[0].y - Rig.PIVOT.y) * Rig.SCALE
		for i in range(points.size()):
			var rest: Vector2 = (rig.rest[i] - Rig.PIVOT) * Rig.SCALE
			if rig.rest[i].y <= 338.0:
				body_ok = body_ok and absf(points[i].x - rest.x) < 0.0001 and absf(points[i].y - rest.y - torso_dy) < 0.0001
			if rig.rest[i].y >= 450.0:
				soles_ok = soles_ok and points[i].y <= rest.y + 0.0001
		for i in range(0, rig.indices.size(), 3):
			var a := points[rig.indices[i]]
			var b := points[rig.indices[i + 1]]
			var c := points[rig.indices[i + 2]]
			triangles_ok = triangles_ok and (b - a).cross(c - a) > 0.0
	check(body_ok, "All torso/head/arm vertices keep exact dimensions through cycle")
	check(soles_ok, "Soles never sink through the floor")
	check(triangles_ok, "No folded or inverted mesh triangles")
	var seam_a := rig.vertices(0.000001, 1.0)
	var seam_b := rig.vertices(0.999999, 1.0)
	var seam_ok := true
	for i in range(seam_a.size()):
		seam_ok = seam_ok and seam_a[i].distance_to(seam_b[i]) < 0.01
	check(seam_ok, "Cycle closes without a position pop")
	for fps in [30, 60, 144]:
		var f = Fighter.new()
		f.reset(400, 1)
		f.walking = true
		rig.reset(f.pos.x)
		for i in range(fps):
			f.pos.x += 64.0 / fps
			rig.update(f, 1.0 / fps)
		check(absf(rig.phase - 0.5) < 0.0001, "Distance-based phase independent of update frequency")
	var f = Fighter.new()
	f.reset(400, 1)
	f.walking = true
	rig.reset(f.pos.x)
	f.pos.x += 32
	rig.update(f, 0.1)
	check(is_equal_approx(rig.phase, 0.25), "Advance moves cycle forward")
	f.guarding = true
	f.pos.x -= 16
	rig.update(f, 0.1)
	check(is_equal_approx(rig.phase, 0.125), "Retreat reverses cycle")
	check(Visual.pose(f, 0) == "idle", "Retreat selects the rig source")
	var held_phase := rig.phase
	rig.update(f, 0.016)
	check(rig.phase == held_phase, "Blocked movement does not walk in place")
	for i in range(12):
		rig.update(f, 0.016)
	check(rig.weight == 0, "Stop settles to exact original artwork")
	f.start_attack("heavy")
	rig.update(f, 0.016)
	check(rig.weight == 0 and Visual.pose(f, 0) == "windup", "Attack immediately takes visual priority")
	f.reset(400, -1)
	f.walking = true
	rig.reset(f.pos.x)
	f.pos.x -= 32
	rig.update(f, 0.1)
	check(is_equal_approx(rig.phase, 0.25), "Mirrored advance keeps same gait")
	f.pos.y -= 10
	rig.update(f, 0.016)
	check(rig.weight == 0 and Visual.pose(f, 0) == "jump", "Airborne movement disables grounded rig")
	call_deferred("arena_checks")

func arena_checks() -> void:
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.set_process(false)
	arena.start_match(true)
	arena.state = "fight"
	Input.action_press("p1_right")
	for i in range(15):
		arena._physics_process(1.0 / 60.0)
	check(arena.ren_visual.walk_rig.weight > 0.99, "Live arena advances animation")
	var phase: float = arena.ren_visual.walk_rig.phase
	arena.paused = true
	arena._physics_process(0.1)
	check(arena.ren_visual.walk_rig.phase == phase, "Pause freezes gait")
	arena.paused = false
	arena.hitstop = 0.1
	arena._physics_process(0.016)
	check(arena.ren_visual.walk_rig.phase == phase, "Hitstop freezes gait")
	Input.action_release("p1_right")
	arena.start_round()
	check(arena.ren_visual.walk_rig.phase == 0 and arena.ren_visual.walk_rig.weight == 0, "Round reset clears gait")
	arena.free()
	print("REN ANIMATION TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
