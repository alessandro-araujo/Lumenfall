extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	arena.muted = true
	arena.start_match(true)
	arena.rain.enabled = true # This test exercises the rainy weather variant.
	arena.state = "fight"
	arena.set_physics_process(false)
	arena.set_process(false)
	var hits := [0, 0]
	for frame in range(2401):
		if frame > 0:
			arena._process(1.0 / 60.0)
			for i in range(2): hits[i] += arena.rain.body_contacts.get(i, 0)
		if frame in [0, 300, 600, 1200, 2400]:
			print("NATURAL RAIN seconds=", frame / 60, " hits=", hits, " wetness=", arena.wet_clothing.levels)
			arena.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/natural-wet-%s.png" % (frame / 60))
	arena.free()
	quit()
