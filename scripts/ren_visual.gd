extends RefCounted
## Presentation only: every pose follows the existing combat clock.
const SHEET = preload("res://assets/fighters/ren/poses.png")
const SCALE := 0.58
# Source rectangles and sole pivots measured on the approved pose atlas.
# Unequal rectangles keep long swords inside their own frame.
const FRAMES := {
	"idle": Rect2(12, 94, 357, 396),
	"step": Rect2(426, 102, 335, 388),
	"windup": Rect2(778, 74, 325, 418),
	"strike": Rect2(1110, 126, 426, 365),
	"guard": Rect2(18, 540, 355, 447),
	"jump": Rect2(402, 554, 371, 350),
	"crouch": Rect2(751, 680, 410, 307),
	"hurt": Rect2(1138, 617, 376, 370)
}
const PIVOTS := {
	"idle": Vector2(184, 483), "step": Vector2(574, 483),
	"windup": Vector2(950, 483), "strike": Vector2(1274, 483),
	"guard": Vector2(191, 980), "jump": Vector2(557, 887),
	"crouch": Vector2(929, 980), "hurt": Vector2(1342, 976)
}

static func pose(f, time: float) -> String:
	if f.health <= 0.0 or f.stun > 0.0:
		return "guard" if f.guarding and f.health > 0.0 else "hurt"
	if not f.attack.is_empty():
		var data: Dictionary = f.ATTACKS[f.attack]
		if f.attack_time < data.startup:
			return "windup"
		if f.attack_time < data.startup + data.active + data.recovery * 0.65:
			return "strike"
		return "idle"
	if not f.grounded():
		return "jump"
	if f.crouching:
		return "crouch"
	if f.guarding:
		return "guard"
	if f.walking and int(time * 9.0) % 2 == 1:
		return "step"
	return "idle"

static func draw(canvas: Node2D, f, time: float) -> void:
	var frame := pose(f, time)
	var region: Rect2 = FRAMES[frame]
	var pivot: Vector2 = PIVOTS[frame]
	var stretch := Vector2.ONE
	var angle := 0.0
	var origin: Vector2 = f.pos.round()
	if frame == "idle":
		stretch.y += sin(time * 3.5) * 0.006
	if f.health <= 0.0:
		angle = -1.48 * f.facing
		origin += Vector2(-20.0 * f.facing, -7.0)
		# Anchor the rear edge so rotating the pose never sinks below the floor.
		pivot = Vector2(region.position.x, 825)
	canvas.draw_set_transform(origin, angle, Vector2(f.facing, 1.0) * stretch)
	if f.rage >= 100.0 and f.health > 0.0:
		canvas.draw_arc(Vector2(0, -95), 117 + sin(time * 8) * 3, -2.8, 0.2, 32, Color(0.85, 0.45, 0.28, 0.5), 3, true)
	draw_frame(canvas, frame, pivot, Vector2.ZERO, Color(1.35, 1.35, 1.35) if f.flash > 0.0 else Color.WHITE)
	if not f.attack.is_empty():
		var data: Dictionary = f.ATTACKS[f.attack]
		if f.attack_time >= data.startup and f.attack_time < data.startup + data.active:
			var progress: float = clampf((f.attack_time - data.startup) / data.active, 0, 1)
			var hand := Vector2(28, -117)
			var radius: float = data.reach - 20.0
			canvas.draw_arc(hand, radius, -1.4, lerpf(-1.3, 0.6, progress), 24, Color(0.97, 0.90, 0.72, 0.8), 5, true)
			if f.attack == "special":
				canvas.draw_arc(hand, radius - 10, -1.4, lerpf(-1.3, 0.6, progress), 24, Color(0.25, 0.8, 0.8, 0.5), 11, true)
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_frame(canvas: Node2D, frame: String, pivot: Vector2, origin: Vector2, tint := Color.WHITE) -> void:
	var regions: Array = [FRAMES[frame]]
	# These two silhouettes interlock in the source atlas; sample separate strips
	# to preserve the sword tip and ponytail without drawing the adjacent fighter.
	if frame == "crouch":
		regions = [Rect2(751, 680, 375, 100), Rect2(751, 780, 410, 207)]
	elif frame == "hurt":
		regions = [Rect2(1138, 617, 376, 163), Rect2(1163, 780, 351, 207)]
	for region: Rect2 in regions:
		canvas.draw_texture_rect_region(SHEET, Rect2(origin + (region.position - pivot) * SCALE, region.size * SCALE), region, tint)
