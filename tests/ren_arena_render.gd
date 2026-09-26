extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.set_process(false)
	arena.start_match(true)
	arena.muted = true
	arena.state = "fight"
	for frame in range(160):
		Input.action_release("p1_right")
		Input.action_release("p1_left")
		if frame < 65:
			Input.action_press("p1_right")
		elif frame < 130:
			Input.action_press("p1_left")
		arena._physics_process(1.0 / 60.0)
		arena.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		if frame in [44, 114, 159]:
			root.get_texture().get_image().save_png("res://artifacts/ren-rig-arena-%s.png" % frame)
	Input.action_release("p1_right")
	Input.action_release("p1_left")
	arena.free()
	print("REN ARENA RENDER: PASS")
	quit()
