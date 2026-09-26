extends Node2D
## Isolated review room: compare the original silhouette and the live rig.
const Fighter = preload("res://scripts/fighter.gd")
const Visual = preload("res://scripts/ren_visual.gd")
var model = Fighter.new()
var visual := Visual.new()
var elapsed := 0.0
var stopped := false
var snapshot_mode := false
var captures := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	model.reset(900, 1)
	visual.reset(model)
	snapshot_mode = "--capture-rig" in OS.get_cmdline_user_args()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.keycode == KEY_SPACE:
		stopped = not stopped
	if event.keycode == KEY_RIGHT or event.keycode == KEY_LEFT:
		stopped = true
		visual.walk_rig.weight = 1.0
		visual.walk_rig.phase = fposmod(visual.walk_rig.phase + (1.0 if event.keycode == KEY_RIGHT else -1.0) / 12.0, 1.0)
	if event.keycode == KEY_ESCAPE:
		get_tree().quit()

func _process(dt: float) -> void:
	if not stopped:
		elapsed += dt
		var section := int(elapsed / 2.5) % 3
		var move := 1.0 if section == 0 else (-0.55 if section == 1 else 0.0)
		model.walking = move != 0.0
		model.velocity.x = move * 230.0
		model.pos.x += model.velocity.x * dt
		visual.update(model, dt)
	queue_redraw()
	if snapshot_mode:
		captures += 1
		if captures == 4:
			visual.walk_rig.weight = 1.0
			visual.walk_rig.phase = 0.18
			queue_redraw()
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://artifacts/ren-rig-comparison.png")
			get_tree().quit()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("14232f"))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(45, 55), "REN / ESTUDO DE MOVIMENTO", HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("e8d7b0"))
	draw_string(font, Vector2(140, 130), "ARTE ORIGINAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	draw_string(font, Vector2(765, 130), "MESMA ARTE / PERNAS ANIMADAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	for x in [330, 945]:
		draw_line(Vector2(x - 240, 590), Vector2(x + 245, 590), Color("bcaa7d"))
	# Enlarged equally for inspection. Torso movement is a rigid vertical translation.
	draw_set_transform(Vector2(330, 590), 0, Vector2.ONE * 1.7)
	Visual.draw_frame(self, "idle", Visual.PIVOTS.idle, Vector2.ZERO)
	draw_set_transform(Vector2(945, 590), 0, Vector2.ONE * 1.7)
	visual.walk_rig.draw(self, Visual.SHEET, Color.WHITE)
	draw_set_transform(Vector2.ZERO)
	var status := "AVANCAR" if int(elapsed / 2.5) % 3 == 0 else ("RECUAR" if int(elapsed / 2.5) % 3 == 1 else "PARAR / ASSENTAR")
	status += " / PAUSADO" if stopped else ""
	draw_string(font, Vector2(50, 655), status + "   |   ESPACO: PAUSA   SETAS: 12 POSES   ESC: SAIR", HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	draw_string(font, Vector2(50, 685), "Base 2D original. Sem trocar o corpo por sprites gerados. Interpolacao continua entre 12 poses.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("a6b9c6"))
