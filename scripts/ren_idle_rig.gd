extends RefCounted
## Approved v4 idle: same source-space movement as the 120-frame preview.
const REGION := Rect2(12, 94, 357, 396)
const PIVOT := Vector2(184, 483)
const SCALE := 0.58
const CYCLE := 3.6
const FRAME_COUNT := 120
const COLS := 36
const ROWS := 40
const WalkRig = preload("res://scripts/ren_walk_rig.gd")
var mesh := ArrayMesh.new()
var rest := PackedVector2Array()
var uv := PackedVector2Array()
var indices := PackedInt32Array()

func _init() -> void:
	for y in range(ROWS + 1):
		for x in range(COLS + 1):
			var p := REGION.position + REGION.size * Vector2(float(x) / COLS, float(y) / ROWS)
			rest.append(p)
			uv.append(p / Vector2(1536, 1024))
	for y in range(ROWS):
		for x in range(COLS):
			var a := y * (COLS + 1) + x
			indices.append_array(PackedInt32Array([a, a + 1, a + COLS + 1, a + 1, a + COLS + 2, a + COLS + 1]))

func draw(canvas: Node2D, texture: Texture2D, tint: Color, time: float, amount: float, walk) -> void:
	var points := PackedVector2Array()
	var phase := fposmod(time / CYCLE, 1.0)
	for p in rest:
		var idle := p.lerp(animate_point(p, phase), amount)
		var moving: Vector2 = WalkRig.gait_point(p, walk.phase)
		points.append((idle.lerp(moving, walk.weight) - PIVOT) * SCALE)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	canvas.draw_mesh(mesh, texture, Transform2D.IDENTITY, tint)

static func animate_point(p: Vector2, t: float) -> Vector2:
	var angle := TAU * t
	# Clear inhale, slightly longer exhale; zero velocity at both ends of the loop.
	var breathing := (1.0 - cos(PI * t / 0.4)) * 0.5 if t < 0.4 else (1.0 + cos(PI * (t - 0.4) / 0.6)) * 0.5
	var anchored := smoothstep(345.0, 455.0, p.y)
	# Rigid translation of the upper body, not inflation or scale changes.
	var upper := p - Vector2(184, 345)
	var lean := upper.rotated(-0.032 * breathing) - upper
	var offset := (Vector2(3.0 * sin(angle), -15.0 * breathing) + lean) * (1.0 - anchored)
	# Wrist-driven guard movement. The blade moves as a unit, with a soft forearm transition.
	var blade := smoothstep(217.0, 250.0, p.x) * (1.0 - smoothstep(322.0, 350.0, p.y))
	var hands := smoothstep(151.0, 209.0, p.x) * smoothstep(259.0, 294.0, p.y) * (1.0 - smoothstep(331.0, 353.0, p.y))
	var guard_weight := maxf(blade, hands)
	var wrist := Vector2(209, 308)
	var guard_angle := 0.052 * sin(angle - 0.8) + 0.010 * sin(angle * 2.0 + 0.3)
	var guard_motion := (p - wrist).rotated(guard_angle) - (p - wrist)
	guard_motion += Vector2(1.6 * sin(angle - 0.6), 3.4 * sin(angle - 0.95))
	offset += guard_motion * guard_weight
	var crown := (1.0 - smoothstep(162.0, 207.0, p.y)) * (1.0 - smoothstep(163.0, 195.0, p.x))
	var ribbons := (1.0 - smoothstep(83.0, 113.0, p.x)) * smoothstep(185.0, 242.0, p.y) * (1.0 - smoothstep(320.0, 345.0, p.y))
	# Hair and loose fabric settle behind the breathing rhythm. Face/sword are excluded.
	offset += Vector2(6.0 * sin(angle - 0.65), 2.4 * sin(angle - 1.0)) * maxf(crown, ribbons)
	return p + offset
