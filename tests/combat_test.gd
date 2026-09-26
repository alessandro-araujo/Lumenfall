extends SceneTree

const Fighter = preload("res://scripts/fighter.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _initialize() -> void:
	var a = Fighter.new()
	var b = Fighter.new()
	a.reset(400, 1)
	b.reset(520, -1)
	check(a.start_attack("heavy"), "Heavy starts from idle")
	check(not a.can_hit(b), "Startup does not damage")
	a.tick(0.31, {}, b)
	check(a.can_hit(b), "Heavy connects during active window")
	check(not a.start_attack("light"), "Cannot cancel heavy into light")
	b.guarding = true
	check(b.receive_hit(24, 1, true), "Frontal guard blocks")
	check(is_equal_approx(b.health, 98.08), "Guard reduces damage to chip")
	b.stun = 0
	b.guarding = false
	b.receive_hit(24, 1, true)
	check(is_equal_approx(b.health, 74.08), "Unblocked heavy deals full damage")
	check(b.rage > 0, "Taking damage charges rage")
	a.reset(400, 1)
	check(not a.start_attack("special"), "Special requires full rage")
	a.rage = 100
	check(a.start_attack("special") and a.rage == 0, "Special consumes rage")
	a.tick(1.1, {}, b)
	check(a.attack.is_empty(), "Recovery finishes")
	a.reset(400, 1)
	a.tick(1.0 / 60.0, {"jump": true}, b)
	check(not a.grounded(), "Jump leaves floor")
	for i in range(90):
		a.tick(1.0 / 60.0, {}, b)
	check(a.grounded(), "Gravity returns fighter to floor")
	a.reset(400, 1)
	b.reset(900, -1)
	a.start_attack("light")
	a.tick(0.11, {}, b)
	check(not a.can_hit(b), "Out-of-range attack misses")
	a.tick(0.5, {}, b)
	check(not a.active_hit(), "Expired attack cannot damage")
	b.health = 1
	b.receive_hit(24, 1, true)
	check(b.health == 0, "KO clamps health to zero")
	check(not b.start_attack("light"), "KO fighter cannot attack")
	print("COMBAT TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	call_deferred("_arena_tests")

func _arena_tests() -> void:
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.set_process(false)
	arena.start_match(false)
	check(arena.state == "intro", "Match starts with round intro")
	arena._physics_process(2.1)
	check(arena.state == "fight", "Intro advances to fight")
	arena.p2.health = 0
	arena._physics_process(0.016)
	check(arena.state == "round_end" and arena.p1.wins == 1, "KO awards one round")
	arena._physics_process(3.0)
	check(arena.round_no == 2 and arena.p2.health == 100, "Next round restores health")
	arena.state = "fight"
	arena.p2.health = 0
	arena._physics_process(0.016)
	arena._physics_process(3.0)
	check(arena.state == "match_end" and arena.p1.wins == 2, "Two wins end match")
	arena.start_match(true)
	check(arena.local_mode and arena.p1.wins == 0, "Rematch resets score and selects local mode")
	arena.state = "fight"
	arena.remaining = 0.01
	arena.p1.health = 80
	arena.p2.health = 50
	arena._physics_process(0.02)
	check(arena.p1.wins == 1, "Timeout awards higher health")
	arena.start_match(false)
	arena.state = "fight"
	arena.remaining = 0.01
	arena._physics_process(0.02)
	check(arena.banner == "EMPATE" and arena.p1.wins == 0 and arena.p2.wins == 0, "Draw awards no wins")
	arena.start_match(false)
	arena.state = "fight"
	arena.paused = true
	arena._physics_process(1.0)
	check(arena.remaining == 60.0, "Pause freezes clock")
	var toggle := InputEventKey.new()
	toggle.keycode = KEY_T
	toggle.pressed = true
	arena._unhandled_key_input(toggle)
	check(arena.training_mode and not arena.paused, "Pause menu T enters training")
	arena.state = "fight"
	var target: Vector2 = arena.p2.pos
	for i in range(120):
		arena._physics_process(1.0 / 60.0)
	check(arena.p2.pos == target and arena.p2.attack.is_empty(), "Training CPU stays idle")
	check(arena.remaining == 60.0, "Training has no time limit")
	arena.start_match(true, true)
	arena.state = "fight"
	Input.action_press("p2_left")
	Input.action_press("p2_heavy")
	arena._physics_process(0.016)
	Input.action_release("p2_left")
	Input.action_release("p2_heavy")
	check(arena.p2.pos == target and arena.p2.attack.is_empty(), "Training ignores player two input")
	arena._resolve_hit(arena.p1, arena.p2, "heavy")
	check(arena.p2.health == 76, "Training target takes damage")
	arena.hitstop = 0
	arena._physics_process(0.016)
	check(arena.p2.pos == target, "Training target remains fixed after impact")
	arena.p1.pos.x = target.x - 40
	arena._physics_process(0.016)
	check(arena.p2.pos == target and absf(arena.p2.pos.x - arena.p1.pos.x) >= 76, "Body collision keeps dummy fixed")
	arena.p2.health = 0
	arena._physics_process(0.016)
	arena._physics_process(1.3)
	check(arena.p2.health == 100 and arena.p1.wins == 0 and arena.round_no == 1, "Training restores target after KO without score")
	var restart := InputEventKey.new()
	restart.keycode = KEY_R
	restart.pressed = true
	arena._unhandled_key_input(restart)
	check(arena.training_mode, "Restart preserves training mode")
	arena.paused = true
	arena._unhandled_key_input(toggle)
	check(not arena.training_mode and arena.local_mode, "Leaving training restores previous match type")
	print("ARENA TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " total failures)")
	arena.free()
	quit(0 if failures == 0 else 1)
