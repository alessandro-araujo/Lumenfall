extends RefCounted
## Short pixel-art bursts. A private RNG keeps visuals independent of CPU choices.

const PALETTE := [Color("761d35"), Color("bd2941"), Color("ed4a50")]
const MAX_DROPS := 160
var drops: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func emit(origin: Vector2, direction: float, kind: String) -> void:
	var count := 12 if kind == "light" else (30 if kind == "special" else 22)
	var strength := 0.8 if kind == "light" else (1.25 if kind == "special" else 1.0)
	for i in range(count):
		var lifetime := rng.randf_range(0.28, 0.52)
		drops.append({
			"pos": origin + Vector2(rng.randf_range(-4, 4), rng.randf_range(-9, 9)),
			"vel": Vector2(direction * rng.randf_range(100, 360), rng.randf_range(-210, 65)) * strength,
			"life": lifetime, "duration": lifetime,
			"size": 4.0 if i % 3 else 6.0,
			"color": PALETTE[i % PALETTE.size()]
		})
	while drops.size() > MAX_DROPS:
		drops.pop_front()

func update(dt: float) -> void:
	for i in range(drops.size() - 1, -1, -1):
		var drop: Dictionary = drops[i]
		drop.life -= dt
		drop.pos += drop.vel * dt
		drop.vel.y += 720.0 * dt
		if drop.life <= 0.0 or drop.pos.y >= 562.0:
			drops.remove_at(i)

func draw(canvas: Node2D) -> void:
	for drop in drops:
		var color: Color = drop.color
		color.a *= clampf(drop.life / 0.12, 0.0, 1.0)
		var size: float = drop.size
		# Overlapping squares give the initial spray a stepped, unfiltered silhouette.
		var tail: Vector2 = drop.vel * 0.026 * (drop.life / drop.duration)
		for step in range(3):
			var point: Vector2 = drop.pos - tail * float(step) / 2.0
			point = point.snapped(Vector2(2, 2))
			canvas.draw_rect(Rect2(point, Vector2.ONE * size), color)
			size = maxf(2.0, size - 2.0)

func clear() -> void:
	drops.clear()
