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
	arena.p1.pos.x = 480
	arena.p2.pos.x = 760
	for i in range(180):
		arena.rain.update(1.0 / 60.0, [arena.p1, arena.p2])
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/rain-game.png")
	arena.paused = true
	await process_frame
	var drops: Array = arena.rain.drops.duplicate(true)
	await create_timer(0.25).timeout
	if drops != arena.rain.drops or not arena.animated_stage.playback.paused:
		push_error("Arena pause must freeze both rain and stage")
		quit(1)
		return
	arena.paused = false
	await create_timer(0.15).timeout
	if drops == arena.rain.drops:
		push_error("Arena resume must restart rain")
		quit(1)
		return
	arena.queue_free()
	await process_frame
	print("RAIN RENDER AND ARENA PAUSE: PASS")
	quit()
