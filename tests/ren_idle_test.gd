extends SceneTree
const Idle = preload("res://scripts/ren_idle_rig.gd")
const Visual = preload("res://scripts/ren_visual.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	for t in range(120):
		for p in [Vector2(45, 483), Vector2(307, 483)]:
			check(Idle.animate_point(p, float(t) / 120.0).is_equal_approx(p), "Soles remain anchored")
	for p in [Vector2(150, 220), Vector2(205, 305), Vector2(350, 190)]:
		check(Idle.animate_point(p, 0.0).distance_to(Idle.animate_point(p, 0.999999)) < 0.001, "Idle loop closes seamlessly")
	call_deferred("arena_checks")

func arena_checks() -> void:
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	arena.set_process(false)
	arena.set_physics_process(false)
	arena.start_match(true)
	arena.state = "fight"
	arena._process(0.5)
	check(is_equal_approx(arena.ren_visual.idle_time, 0.5), "Idle clock advances")
	arena.paused = true
	arena._process(0.5)
	check(is_equal_approx(arena.ren_visual.idle_time, 0.5), "Pause freezes idle")
	arena.paused = false
	arena.hitstop = 0.1
	arena._process(0.05)
	check(is_equal_approx(arena.ren_visual.idle_time, 0.5), "Hitstop freezes idle")
	arena.hitstop = 0
	arena.p1.start_attack("heavy")
	arena._process(0.05)
	check(arena.ren_visual.idle_amount == 0 and Visual.pose(arena.p1, 0) == "windup", "Attack overrides idle")
	arena.p1.attack = ""
	arena.p1.guarding = true
	arena._process(0.05)
	check(Visual.pose(arena.p1, 0) == "guard", "Defense overrides idle")
	arena.p1.guarding = false
	arena._process(0.08)
	check(arena.ren_visual.idle_amount > 0 and arena.ren_visual.idle_amount < 1, "Return to idle fades in")
	arena.start_round()
	check(arena.ren_visual.idle_time == 0, "Round reset clears clock")
	arena.state = "fight"
	arena._process(1.44)
	if "--capture-idle" in OS.get_cmdline_user_args():
		arena.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/ren-idle-integrated.png")
	arena.free()
	print("REN IDLE TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
