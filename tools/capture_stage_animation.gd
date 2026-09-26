extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1280, 720)
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	arena.set_process(false)
	arena.set_physics_process(false)
	arena.muted = true
	arena.start_match(false)
	arena.state = "fight"
	arena.p1.pos.x = 480.0
	arena.p2.pos.x = 760.0
	DirAccess.make_dir_recursive_absolute("res://artifacts/stage-animation-frames")
	for frame in range(120):
		arena.clock = frame / 15.0
		arena.animated_stage.set_time(arena.clock)
		arena.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png("res://artifacts/stage-animation-frames/frame-%03d.png" % frame)
	print("Captured 120 frames at 15 FPS (8 seconds)")
	arena.queue_free()
	await process_frame
	quit()
