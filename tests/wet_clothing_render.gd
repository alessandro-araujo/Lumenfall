extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280, 720)
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	arena.muted = true
	arena.start_match(true)
	arena.rain.enabled = true # This test exercises the rainy weather variant.
	arena.state = "fight"
	arena.set_physics_process(false)
	arena.set_process(false)
	arena.p1.pos.x = 480
	arena.p2.pos.x = 760
	arena.animated_stage.playback.paused = true
	arena.rain.drops.clear()
	arena.rain.drops.append({"pos": Vector2(480, 340), "layer": 1, "ground": 562.0, "speed": 1000.0})
	arena._process(0.05)
	if arena.wet_clothing.levels[0] <= 0 or arena.ren_visual.wetness <= 0 or arena.wet_clothing.levels[1] != 0:
		push_error("Real rain contact must wet only the hit fighter through the arena")
		quit(1)
		return
	var before_pause: float = arena.wet_clothing.levels[0]
	arena.paused = true
	arena._process(0.05)
	if arena.wet_clothing.levels[0] != before_pause:
		push_error("Arena pause must freeze clothing moisture")
		quit(1)
		return
	arena.paused = false
	arena.rain.enabled = false
	for level in [0.0, 1.0]:
		arena.ren_visual.wetness = level
		arena.wet_clothing.levels[0] = level
		arena.wet_clothing.levels[1] = level
		arena.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/clothing-%s.png" % int(level))
	# All atlas poses plus the idle and walking mesh must accept the same UV overlay.
	for mode in ["walk", "jump", "crouch", "guard", "attack", "hurt"]:
		arena.p1.reset(480, 1)
		arena.p1.walking = mode == "walk"
		arena.ren_visual.walk_rig.weight = 1.0 if mode == "walk" else 0.0
		arena.p1.crouching = mode == "crouch"
		arena.p1.guarding = mode == "guard"
		if mode == "jump": arena.p1.pos.y -= 100
		if mode == "attack": arena.p1.start_attack("heavy")
		if mode == "hurt": arena.p1.stun = 0.3
		arena.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/clothing-%s.png" % mode)
	arena.free()
	print("WET CLOTHING RENDER: PASS")
	quit()
