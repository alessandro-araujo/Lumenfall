extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.set_process(false)
	arena.muted = true
	arena.start_match(true)
	arena.p2.guarding = true
	arena._resolve_hit(arena.p1, arena.p2, "heavy")
	check(arena.blood.drops.is_empty() and arena.particles.size() == 18, "Guard emits sparks without blood")
	for direction in [-1.0, 1.0]:
		for kind in ["light", "heavy", "special"]:
			arena.start_round()
			arena.p1.facing = direction
			arena.p2.crouching = true
			arena._resolve_hit(arena.p1, arena.p2, kind)
			check(not arena.blood.drops.is_empty() and arena.particles.is_empty(), "Sword hit emits blood")
			for drop in arena.blood.drops:
				check(drop.vel.x * direction > 0.0, "Spray follows attack direction")
				check(absf(drop.pos.y - (arena.p2.pos.y - 66)) <= 9, "Crouched impact follows torso")
			var before: Vector2 = arena.blood.drops[0].pos
			arena.paused = true
			arena._physics_process(0.1)
			check(arena.blood.drops[0].pos == before, "Pause freezes blood")
			arena.paused = false
			arena.blood.update(1.0)
			check(arena.blood.drops.is_empty(), "Blood expires")
	for i in range(20):
		arena.blood.emit(Vector2(500, 450), 1.0, "special")
	check(arena.blood.drops.size() <= arena.blood.MAX_DROPS, "Burst count remains bounded")
	arena.start_round()
	check(arena.blood.drops.is_empty(), "Round reset clears blood")
	print("BLOOD TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	if "--blood-preview" in OS.get_cmdline_user_args():
		arena.state = "fight"
		arena.p1.pos.x = 550
		arena.p2.pos.x = 695
		arena.p1.start_attack("heavy")
		arena.p1.attack_time = 0.38
		arena.blood.rng.seed = 12
		arena._resolve_hit(arena.p1, arena.p2, "heavy")
		arena.blood.update(0.13)
		arena.shake = 0
		arena.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/blood-preview.png")
	arena.free()
	quit(0 if failures == 0 else 1)
