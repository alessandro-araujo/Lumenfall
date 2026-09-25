extends Node2D

const Fighter = preload("res://scripts/fighter.gd")
const RenVisual = preload("res://scripts/ren_visual.gd")
const BloodEffect = preload("res://scripts/blood_effect.gd")
const STAGE_BACKGROUND = preload("res://assets/arenas/templo-ao-luar/background.png")
const INK := Color("101c2c")
const PAPER := Color("efe4c9")
const GOLD := Color("d6af68")
const RED := Color("db6658")
const TEAL := Color("69c6bc")
var p1 = Fighter.new()
var p2 = Fighter.new()
var font: Font = ThemeDB.fallback_font
var clock := 0.0
var remaining := 60.0
var state := "menu"
var local_mode := false
var round_no := 1
var phase_time := 0.0
var hitstop := 0.0
var shake := 0.0
var paused := false
var muted := false
var banner := ""
var particles: Array[Dictionary] = []
var blood := BloodEffect.new()
var sound_bank: Dictionary = {}
var sound_players: Array[AudioStreamPlayer] = []
var sound_index := 0
var preview_frames := 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_setup_inputs()
	p1.reset(390.0, 1.0)
	p2.reset(890.0, -1.0)
	_make_audio()
	if "--preview" in OS.get_cmdline_user_args():
		start_match(false)
		state = "fight"
		p1.pos.x = 480.0
		p2.pos.x = 760.0
		p1.rage = 78.0
		p2.health = 73.0
		set_physics_process(false)

func _setup_inputs() -> void:
	var bindings := {
		"p1_left": KEY_A, "p1_right": KEY_D, "p1_jump": KEY_W,
		"p1_crouch": KEY_S, "p1_light": KEY_J, "p1_heavy": KEY_K,
		"p1_guard": KEY_L, "p1_special": KEY_U,
		"p2_left": KEY_LEFT, "p2_right": KEY_RIGHT, "p2_jump": KEY_UP,
		"p2_crouch": KEY_DOWN, "p2_light": KEY_KP_1, "p2_heavy": KEY_KP_2,
		"p2_guard": KEY_KP_3, "p2_special": KEY_KP_0
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = bindings[action]
		InputMap.action_add_event(action, event)
	# Alternatives for keyboards without a numeric keypad.
	for pair in [["p2_light", KEY_B], ["p2_heavy", KEY_N], ["p2_guard", KEY_M], ["p2_special", KEY_H]]:
		var event := InputEventKey.new()
		event.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], event)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.keycode == KEY_F1:
		muted = not muted
	if event.keycode == KEY_ESCAPE:
		if state != "menu":
			paused = not paused
	if state == "menu":
		if event.keycode == KEY_ENTER or event.keycode == KEY_1:
			start_match(false)
		elif event.keycode == KEY_2:
			start_match(true)
	elif event.keycode == KEY_R:
		start_match(local_mode)
	elif paused and event.keycode == KEY_Q:
		state = "menu"
		paused = false
	elif state == "match_end" and event.keycode == KEY_ENTER:
		start_match(local_mode)

func start_match(two_players: bool) -> void:
	local_mode = two_players
	p1.wins = 0
	p2.wins = 0
	round_no = 1
	paused = false
	start_round()

func start_round() -> void:
	p1.reset(390.0, 1.0)
	p2.reset(890.0, -1.0)
	remaining = 60.0
	state = "intro"
	phase_time = 2.0
	hitstop = 0.0
	shake = 0.0
	particles.clear()
	blood.clear()
	_play_sound("gong")

func _process(dt: float) -> void:
	if not paused:
		clock += dt
	queue_redraw()
	if "--preview" in OS.get_cmdline_user_args():
		preview_frames += 1
		if preview_frames == 4:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://artifacts/arena-preview.png")
			get_tree().quit()

func _physics_process(dt: float) -> void:
	if paused or state == "menu":
		return
	shake = maxf(0.0, shake - dt * 24.0)
	blood.update(dt)
	for i in range(particles.size() - 1, -1, -1):
		particles[i].life -= dt
		particles[i].pos += particles[i].vel * dt
		particles[i].vel.y += 600.0 * dt
		if particles[i].life <= 0.0:
			particles.remove_at(i)
	if hitstop > 0.0:
		hitstop -= dt
		return
	if state == "intro":
		phase_time -= dt
		if phase_time <= 0.0:
			state = "fight"
		return
	if state == "round_end":
		phase_time -= dt
		if phase_time <= 0.0:
			if p1.wins >= 2 or p2.wins >= 2:
				state = "match_end"
			else:
				round_no += 1
				start_round()
		return
	if state != "fight":
		return
	remaining = maxf(0.0, remaining - dt)
	p1.tick(dt, _human("p1"), p2)
	p2.tick(dt, _human("p2") if local_mode else _cpu(dt), p1)
	# Body collision applies only at similar heights, allowing jumps over the rival.
	var separation: float = p2.pos.x - p1.pos.x
	if absf(separation) < 76.0 and absf(p1.pos.y - p2.pos.y) < 110.0:
		var push: float = (76.0 - absf(separation)) * 0.5
		var direction := 1.0 if separation >= 0.0 else -1.0
		p1.pos.x = clampf(p1.pos.x - push * direction, 65.0, 1215.0)
		p2.pos.x = clampf(p2.pos.x + push * direction, 65.0, 1215.0)
	# Snapshot both attacks before applying damage so simultaneous strikes can trade.
	var hit1: bool = p1.can_hit(p2)
	var hit2: bool = p2.can_hit(p1)
	var kind1: String = p1.attack
	var kind2: String = p2.attack
	if hit1:
		_resolve_hit(p1, p2, kind1)
	if hit2:
		_resolve_hit(p2, p1, kind2)
	if p1.health <= 0.0 or p2.health <= 0.0 or remaining <= 0.0:
		_finish_round()

func _human(prefix: String) -> Dictionary:
	return {
		"move": Input.get_axis(prefix + "_left", prefix + "_right"),
		"jump": Input.is_action_just_pressed(prefix + "_jump"),
		"crouch": Input.is_action_pressed(prefix + "_crouch"),
		"guard": Input.is_action_pressed(prefix + "_guard"),
		"light": Input.is_action_just_pressed(prefix + "_light"),
		"heavy": Input.is_action_just_pressed(prefix + "_heavy"),
		"special": Input.is_action_just_pressed(prefix + "_special")
	}

func _cpu(dt: float) -> Dictionary:
	p2.ai_timer -= dt
	if p2.ai_timer <= 0.0:
		p2.ai_timer = randf_range(0.16, 0.36)
		var distance: float = absf(p1.pos.x - p2.pos.x)
		var c := {"move": 0.0}
		if distance > 165.0:
			c.move = p2.facing
		elif distance < 92.0 and randf() < 0.40:
			c.move = -p2.facing
		if not p1.attack.is_empty() and distance < 220.0 and randf() < 0.62:
			c.guard = true
		elif distance < 192.0:
			if p2.rage >= 100.0:
				c.special = true
			elif randf() < 0.52:
				c.light = true
			else:
				c.heavy = true
		if distance > 220.0 and randf() < 0.10:
			c.jump = true
		p2.ai_command = c
	var command: Dictionary = p2.ai_command.duplicate()
	for one_shot in ["jump", "light", "heavy", "special"]:
		p2.ai_command.erase(one_shot)
	return command

func _resolve_hit(attacker, defender, kind: String) -> void:
	attacker.connected = true
	var damage: float = Fighter.ATTACKS[kind].damage
	var blocked: bool = defender.receive_hit(damage, attacker.facing, kind != "light")
	attacker.rage = minf(100.0, attacker.rage + (5.0 if blocked else 11.0))
	hitstop = 0.045 if blocked else (0.12 if kind != "light" else 0.065)
	shake = 2.0 if blocked else (9.0 if kind != "light" else 4.0)
	_play_sound("block" if blocked else "hit")
	var impact: Vector2 = defender.pos + Vector2(-attacker.facing * 20.0, -100.0 + (34.0 if defender.crouching else 0.0))
	if blocked:
		for i in range(18):
			particles.append({"pos": impact, "vel": Vector2(randf_range(-290, 290), randf_range(-310, 80)), "life": randf_range(0.18, 0.48), "color": TEAL})
	else:
		blood.emit(impact, attacker.facing, kind)

func _finish_round() -> void:
	state = "round_end"
	phase_time = 2.5
	if is_equal_approx(p1.health, p2.health):
		banner = "EMPATE"
	else:
		var winner = p1 if p1.health > p2.health else p2
		winner.wins += 1
		banner = "REN VENCE" if winner == p1 else "AKANE VENCE"
	_play_sound("gong")

func _draw() -> void:
	var offset := Vector2(sin(clock * 173.0), cos(clock * 137.0)) * shake
	draw_set_transform(offset)
	_draw_stage()
	_draw_fighter(p1, false)
	_draw_fighter(p2, true)
	draw_set_transform(offset)
	blood.draw(self)
	for spark in particles:
		draw_line(spark.pos, spark.pos - spark.vel * 0.035, spark.color, 2.5, true)
	draw_set_transform(Vector2.ZERO)
	_draw_hud()
	if state == "menu":
		_draw_menu()
	elif state == "intro":
		_center("ROUND %02d" % round_no if phase_time > 0.75 else "LUTEM", 332, 66, PAPER)
		_center("UM INSTANTE. UM CORTE.", 372, 15, GOLD)
	elif state == "round_end" or state == "match_end":
		draw_rect(Rect2(0, 239, 1280, 190), Color(0.025, 0.04, 0.065, 0.90))
		_center(banner, 326, 57, PAPER)
		_center("VITÓRIA  •  ENTER: REVANCHE  /  ESC: OPÇÕES" if state == "match_end" else "O SILÊNCIO DEPOIS DO AÇO", 377, 17, GOLD)
	if paused:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.025, 0.04, 0.065, 0.88))
		_center("PAUSA", 308, 64, PAPER)
		_center("ESC  CONTINUAR     R  REINICIAR     Q  MENU", 366, 18, GOLD)

func _poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)

func _text(text: String, at: Vector2, size: int, color := PAPER) -> void:
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _center(text: String, y: float, size: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_text(text, Vector2((1280.0 - width) * 0.5, y), size, color)

func _draw_stage() -> void:
	# Approved single-image stage; fighter footing and combat bounds stay unchanged.
	draw_texture_rect(STAGE_BACKGROUND, Rect2(0, 0, 1280, 720), false)
	draw_rect(Rect2(0, 658, 1280, 62), Color("0e1b29"))
	draw_line(Vector2(40, 658), Vector2(1240, 658), Color("4b5152"), 1)

func _draw_fighter(f, rival: bool) -> void:
	var color := RED if rival else TEAL
	var dark := Color("613c48") if rival else Color("23505b")
	var bob := sin(clock * 3.5) * 2.0
	var crouch := 34.0 if f.crouching else 0.0
	var stride := sin(clock * 14.0) * 15.0 if f.walking else 0.0
	draw_set_transform(Vector2(f.pos.x, 565), 0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, 52, Color(0.02, 0.04, 0.07, 0.40))
	if not rival:
		RenVisual.draw(self, f, clock)
		return
	draw_set_transform(f.pos + Vector2(0, bob + crouch), 0.0, Vector2(f.facing, 1.0))
	if f.health <= 0.0:
		draw_set_transform(f.pos + Vector2(-25, -16), -f.facing * 1.35, Vector2(f.facing, 1.0))
	if f.flash > 0.0:
		color = PAPER
	if f.rage >= 100.0:
		draw_arc(Vector2(0, -90), 104 + sin(clock * 8) * 4, -2.8, 0.2, 32, Color(0.85, 0.45, 0.28, 0.5), 3, true)
	# Scabbard and trailing sash.
	draw_line(Vector2(-22, -79), Vector2(-88, -36), Color("151c2a"), 9, true)
	_poly([Vector2(-17, -108), Vector2(-58, -108 + sin(clock * 5) * 5), Vector2(-93, -84 + sin(clock * 4) * 8), Vector2(-54, -97), Vector2(-14, -92)], color)
	# Wide hakama trousers and sandals.
	_poly([Vector2(-25, -82), Vector2(25, -82), Vector2(43 + stride, -13 - crouch), Vector2(12 + stride, -8 - crouch), Vector2(-4, -49), Vector2(-23 - stride, -6 - crouch), Vector2(-48 - stride, -13 - crouch)], INK)
	draw_line(Vector2(-17, -64), Vector2(-29 - stride, -18 - crouch), dark, 5)
	draw_line(Vector2(14, -65), Vector2(27 + stride, -19 - crouch), dark, 6)
	draw_line(Vector2(-43 - stride, -5 - crouch), Vector2(-17 - stride, -5 - crouch), Color("b3a690"), 9)
	draw_line(Vector2(17 + stride, -5 - crouch), Vector2(48 + stride, -5 - crouch), Color("b3a690"), 9)
	# Layered jacket, collar and obi.
	_poly([Vector2(-27, -145), Vector2(10, -152), Vector2(34, -126), Vector2(24, -84), Vector2(-31, -84), Vector2(-40, -121)], color)
	_poly([Vector2(-19, -146), Vector2(3, -111), Vector2(16, -146), Vector2(24, -138), Vector2(2, -94), Vector2(-31, -141)], dark)
	draw_line(Vector2(-25, -89), Vector2(26, -89), GOLD, 10)
	# Neck, face, hair, headband and tied hair.
	draw_rect(Rect2(-8, -163, 17, 22), Color("c78f71"))
	_poly([Vector2(-17, -185), Vector2(13, -187), Vector2(24, -170), Vector2(16, -151), Vector2(-8, -154), Vector2(-21, -170)], Color("e2b58e"))
	_poly([Vector2(-22, -170), Vector2(-26, -188), Vector2(-15, -201), Vector2(9, -199), Vector2(22, -183), Vector2(7, -184), Vector2(-5, -174), Vector2(-9, -159)], Color("131b29"))
	draw_circle(Vector2(-18, -201), 12, Color("131b29"))
	draw_line(Vector2(-21, -182), Vector2(17, -182), color, 6)
	draw_line(Vector2(10, -173), Vector2(17, -172), INK, 2)
	# Articulated arms and sword; attack timing drives the pose.
	var hand := Vector2(40, -104)
	var angle := -0.72
	if f.guarding:
		hand = Vector2(40, -133)
		angle = -1.8
	elif not f.attack.is_empty():
		var data: Dictionary = Fighter.ATTACKS[f.attack]
		if f.attack_time < data.startup:
			hand = Vector2(-5, -165)
			angle = -2.2
		else:
			var progress: float = clampf((f.attack_time - data.startup) / data.active, 0.0, 1.0)
			hand = Vector2(50, -122)
			angle = lerpf(-1.5, 0.45, progress)
			if f.attack_time < data.startup + data.active:
				var radius: float = data.reach - 20.0
				draw_arc(hand, radius, -1.55, angle, 24, Color(0.97, 0.9, 0.72, 0.7), 8, true)
				draw_arc(hand, radius - 14, -1.4, angle, 24, Color(color, 0.4), 14, true)
	draw_line(Vector2(10, -137), hand - Vector2(17, -4), dark, 23, true)
	draw_line(hand - Vector2(17, -4), hand, Color("e2b58e"), 13, true)
	var blade := Vector2.from_angle(angle)
	var cross := blade.orthogonal()
	draw_line(hand - blade * 18, hand + blade * 11, INK, 8, true)
	draw_line(hand + blade * 9 - cross * 11, hand + blade * 9 + cross * 11, GOLD, 5, true)
	draw_line(hand + blade * 15, hand + blade * 115, Color("bbcad0"), 6, true)
	draw_line(hand + blade * 15 - cross * 2, hand + blade * 120 - cross * 2, PAPER, 2, true)
	draw_set_transform(Vector2.ZERO)

func _draw_hud() -> void:
	draw_rect(Rect2(0, 0, 1280, 128), Color(0.035, 0.065, 0.1, 0.95))
	_text("L U M E N F A L L", Vector2(42, 29), 15, GOLD)
	_text("TEMPLO AO LUAR  /  " + ("DUELO LOCAL" if local_mode else "CONTRA CPU"), Vector2(900, 29), 13, Color("9daeb4"))
	_text("REN", Vector2(43, 60), 24, PAPER)
	_text("AKANE", Vector2(1135, 60), 24, PAPER)
	for index in range(2):
		var f = p1 if index == 0 else p2
		var x := 43.0 if index == 0 else 716.0
		draw_rect(Rect2(x, 72, 520, 24), Color("372e34"))
		var width: float = 516.0 * f.health / 100.0
		var hx: float = x + 2 if index == 0 else x + 518 - width
		draw_rect(Rect2(hx, 74, width, 20), GOLD if index == 0 else RED)
		draw_rect(Rect2(x, 72, 520, 24), Color("a7977e"), false, 1)
		for mark in range(1, 10):
			draw_line(Vector2(x + mark * 52, 74), Vector2(x + mark * 52, 94), Color(0.08, 0.1, 0.13, 0.22), 1)
		for win in range(2):
			draw_circle(Vector2(x + (win * 18 if index == 0 else 510 - win * 18), 111), 5, GOLD if f.wins > win else Color("384653"))
		var rx := 43.0 if index == 0 else 996.0
		draw_rect(Rect2(rx, 608, 240, 9), Color("172536"))
		draw_rect(Rect2(rx, 608, 240 * f.rage / 100.0, 9), TEAL if index == 0 else RED)
		_text("FÚRIA  /  " + ("PRONTA" if f.rage >= 100.0 else "%02d%%" % int(f.rage)), Vector2(rx, 640), 14, GOLD if f.rage >= 100.0 else PAPER)
	draw_circle(Vector2(640, 77), 45, INK)
	draw_arc(Vector2(640, 77), 44, 0, TAU, 64, GOLD, 1.5, true)
	_center("%02d" % int(ceil(remaining)), 93, 39, PAPER)
	_center("ROUND %02d" % round_no, 143, 12, GOLD)
	_text("A D  MOVER    W  PULAR    S  AGACHAR    J  LEVE    K  FORTE    L  DEFESA    U  FÚRIA", Vector2(42, 685), 14, PAPER)
	_text("ESC  PAUSA   •   F1  " + ("SOM OFF" if muted else "SOM ON"), Vector2(987, 685), 13, GOLD)
	if local_mode:
		_center("J2: SETAS  MOVER / PULAR / AGACHAR    B / N / M / H  LEVE / FORTE / DEFESA / FÚRIA", 708, 12, Color("9daeb4"))
	else:
		_center("SEGURE PARA TRÁS PARA DEFENDER  •  MELHOR DE TRÊS", 708, 12, Color("9daeb4"))

func _draw_menu() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color(0.025, 0.045, 0.075, 0.72))
	draw_rect(Rect2(308, 153, 664, 429), Color(0.045, 0.08, 0.12, 0.95))
	draw_rect(Rect2(320, 165, 640, 405), Color("6c6658"), false, 1)
	_center("UM DUELO SOB A LUA", 221, 15, GOLD)
	_center("LUMENFALL", 309, 76, PAPER)
	_center("L Â M I N A S   D O   A M A N H E C E R", 348, 17, GOLD)
	draw_line(Vector2(489, 377), Vector2(791, 377), Color("56574f"), 1)
	_center("ENTER / 1     ENFRENTAR A CPU", 424, 23, PAPER)
	_center("2     DUELO LOCAL", 467, 23, PAPER)
	_center("DOIS GUERREIROS. CADA GOLPE IMPORTA.", 532, 14, Color("9daeb4"))

func _make_audio() -> void:
	for kind in ["hit", "block", "gong"]:
		var duration := 0.75 if kind == "gong" else 0.16
		var samples := int(22050 * duration)
		var bytes := PackedByteArray()
		bytes.resize(samples * 2)
		var rng := RandomNumberGenerator.new()
		rng.seed = 17
		for i in range(samples):
			var t := float(i) / 22050.0
			var envelope := exp(-t * (5.0 if kind == "gong" else 25.0))
			var value := 0.0
			if kind == "gong":
				value = (sin(t * TAU * 130) + 0.4 * sin(t * TAU * 207) + 0.2 * sin(t * TAU * 311)) * 0.25
			elif kind == "block":
				value = (sin(t * TAU * 1450) + sin(t * TAU * 2130)) * 0.17
			else:
				value = rng.randf_range(-0.5, 0.5) + sin(t * TAU * 90) * 0.3
			bytes.encode_s16(i * 2, int(clampf(value * envelope, -1, 1) * 22000))
		var stream := AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		stream.data = bytes
		sound_bank[kind] = stream
	for i in range(4):
		var player := AudioStreamPlayer.new()
		player.volume_db = -9
		add_child(player)
		sound_players.append(player)

func _play_sound(kind: String) -> void:
	if muted or sound_players.is_empty():
		return
	var player := sound_players[sound_index % sound_players.size()]
	sound_index += 1
	player.stream = sound_bank[kind]
	player.play()
