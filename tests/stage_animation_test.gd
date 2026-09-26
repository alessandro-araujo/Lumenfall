extends SceneTree

const Stage = preload("res://scripts/animated_stage.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	var stage := Stage.new()
	root.add_child(stage)
	stage.set_time(0.0)
	await create_timer(0.6).timeout
	check(stage.playback.is_playing(), "Background video must start")
	check(stage.playback.stream_position > 0.2, "Decoder must advance")
	await RenderingServer.frame_post_draw
	var first := root.get_texture().get_image()
	check(first.get_size() == Vector2i(1280, 720), "Background dimensions")
	first.save_png("res://artifacts/stage-render-start.png")
	stage.set_time(0.0)
	await create_timer(0.15).timeout
	var paused_at := stage.playback.stream_position
	await RenderingServer.frame_post_draw
	var frozen := root.get_texture().get_image()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	check(absf(stage.playback.stream_position - paused_at) < 0.025, "Pause must freeze playback")
	check(root.get_texture().get_image().get_data() == frozen.get_data(), "Paused pixels must stay fixed")
	stage.set_time(1.0)
	await create_timer(2.0).timeout
	check(stage.playback.stream_position > paused_at + 1.0, "Resume must continue playback")
	await RenderingServer.frame_post_draw
	var animated := root.get_texture().get_image()
	check(animated.get_data() != first.get_data(), "Rendered animation must change")
	animated.save_png("res://artifacts/stage-render-lightning.png")
	var previous := stage.playback.stream_position
	var looped := false
	for i in range(150):
		await create_timer(0.1).timeout
		var current := stage.playback.stream_position
		if current + 1.0 < previous:
			looped = true
			break
		previous = current
	check(looped and stage.playback.is_playing(), "Video must loop beyond twelve seconds")
	stage.queue_free()
	await process_frame
	print("STAGE RENDER: ", failures, " failures")
	quit(failures)
