extends RefCounted
## Presentation-only rain. Screen-space surfaces belong to separate depth planes.
const DROP_COUNT := 390
const MAX_SPLASHES := 128
const ROOFS := [
	Vector4(790, 191, 911, 160), Vector4(911, 160, 1019, 60),
	Vector4(1019, 60, 1179, 183), Vector4(1179, 183, 1280, 203),
	Vector4(714, 290, 831, 250), Vector4(831, 250, 908, 223),
	Vector4(124, 211, 174, 181), Vector4(174, 181, 232, 209),
	Vector4(663, 216, 711, 184), Vector4(711, 184, 753, 215)
]
var drops: Array[Dictionary] = []
var splashes: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var enabled := true
var body_contacts: Dictionary = {}

func _init() -> void:
	rng.seed = 934751
	for i in range(DROP_COUNT):
		var layer := 0 if i < 165 else (1 if i < 330 else 2)
		var drop := {"layer": layer, "pos": Vector2.ZERO, "ground": 0.0, "speed": 0.0}
		_reset_drop(drop)
		drop.pos.y = rng.randf_range(-620.0, -10.0)
		drops.append(drop)

func _reset_drop(drop: Dictionary) -> void:
	drop.pos = Vector2(rng.randf_range(-90.0, 1280.0), rng.randf_range(-70.0, -8.0))
	var layer: int = drop.layer
	drop.ground = rng.randf_range(471.0, 490.0) if layer == 0 else (rng.randf_range(540.0, 581.0) if layer == 1 else rng.randf_range(583.0, 590.0))
	drop.speed = [460.0, 750.0, 970.0][layer] * rng.randf_range(0.88, 1.12)

func body_polygon(f) -> PackedVector2Array:
	var height := 204.0
	if f.crouching:
		height = 166.0
	if f.health <= 0.0:
		height = 65.0
	# Head, shoulders and torso follow the fighter's actual world position (including jumps).
	return PackedVector2Array([
		f.pos + Vector2(-14, -height), f.pos + Vector2(13, -height),
		f.pos + Vector2(22, -height + 35), f.pos + Vector2(36, -height + 52),
		f.pos + Vector2(30, -8), f.pos + Vector2(-30, -8),
		f.pos + Vector2(-36, -height + 52), f.pos + Vector2(-22, -height + 35)
	])

func trace_drop(start: Vector2, finish: Vector2, layer: int, ground: float, bodies: Array) -> Dictionary:
	var hit: Dictionary = {}
	var best := INF
	if finish.y >= ground and start.y <= ground and finish.y > start.y:
		var point := start.lerp(finish, (ground - start.y) / (finish.y - start.y))
		hit = {"pos": point, "kind": "ground"}
		best = start.distance_squared_to(point)
	if layer == 0:
		for roof in ROOFS:
			var point = Geometry2D.segment_intersects_segment(start, finish, Vector2(roof.x, roof.y), Vector2(roof.z, roof.w))
			if point != null and start.distance_squared_to(point) < best:
				best = start.distance_squared_to(point)
				hit = {"pos": point, "kind": "roof"}
	elif layer == 1 and absf(ground - 562.0) <= 18.0:
		for body_index in range(bodies.size()):
			var body = bodies[body_index]
			for i in range(body.size()):
				var point = Geometry2D.segment_intersects_segment(start, finish, body[i], body[(i + 1) % body.size()])
				if point != null and start.distance_squared_to(point) < best:
					best = start.distance_squared_to(point)
					hit = {"pos": point, "kind": "body", "body_index": body_index}
	return hit

func update(dt: float, fighters: Array, paused: bool = false) -> void:
	if paused or dt <= 0.0:
		return
	body_contacts.clear()
	if not enabled:
		return
	var step := minf(dt, 0.05)
	elapsed += step
	var bodies: Array = []
	for fighter in fighters:
		bodies.append(body_polygon(fighter))
	for i in range(splashes.size() - 1, -1, -1):
		splashes[i].age += step
		if splashes[i].age >= splashes[i].life:
			splashes.remove_at(i)
	var wind := 0.09 + sin(elapsed * 0.43) * 0.014
	for drop in drops:
		var start: Vector2 = drop.pos
		var finish := start + Vector2(wind, 1.0) * float(drop.speed) * step
		var hit := trace_drop(start, finish, drop.layer, drop.ground, bodies)
		if not hit.is_empty():
			if hit.kind == "body":
				body_contacts[hit.body_index] = body_contacts.get(hit.body_index, 0) + 1
			if splashes.size() < MAX_SPLASHES:
				splashes.append({"pos": hit.pos, "kind": hit.kind, "layer": drop.layer, "age": 0.0, "life": rng.randf_range(0.26, 0.36) if hit.kind == "body" else rng.randf_range(0.16, 0.28), "size": rng.randf_range(4.0, 6.0) if hit.kind == "body" else rng.randf_range(2.0, 4.5)})
			_reset_drop(drop)
		elif finish.x > 1310.0:
			_reset_drop(drop)
		else:
			drop.pos = finish

func draw(canvas: Node2D, foreground: bool) -> void:
	if not enabled:
		return
	var direction := Vector2(0.09 + sin(elapsed * 0.43) * 0.014, 1.0)
	for drop in drops:
		if (drop.layer == 2) != foreground or drop.pos.y < 0.0:
			continue
		var length: float = [8.0, 12.0, 18.0][drop.layer]
		var alpha: float = [0.16, 0.26, 0.32][drop.layer]
		canvas.draw_line(drop.pos - direction * length, drop.pos, Color(0.64, 0.77, 0.89, alpha), 1.0, true)
	for splash in splashes:
		if (splash.layer > 0) != foreground:
			continue
		var t: float = splash.age / splash.life
		var origin: Vector2 = splash.pos
		var spread: float = splash.size * (0.3 + t)
		var lift := sin(t * PI) * (6.5 if splash.kind == "body" else 4.5)
		var color := Color(0.69, 0.82, 0.93, (1.0 - t) * (0.80 if splash.kind == "body" else (0.32 if splash.layer == 0 else 0.52)))
		canvas.draw_line(origin + Vector2(-spread, -lift), origin + Vector2(-spread * 0.6, -lift + 1.2), color, 1.0, true)
		canvas.draw_line(origin + Vector2(spread, -lift), origin + Vector2(spread * 0.6, -lift + 1.2), color, 1.0, true)
		if splash.kind == "body":
			canvas.draw_line(origin + Vector2(0, -lift * 1.2), origin + Vector2(0.5, -lift * 1.2 + 2.0), color, 1.0, true)
		if splash.kind == "ground":
			canvas.draw_line(origin - Vector2(spread, 0), origin + Vector2(spread, 0), Color(color, color.a * 0.45), 1.0, true)
