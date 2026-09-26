extends RefCounted
## Twelve gait keys, interpolated continuously over the original idle artwork.
## Torso vertices only translate vertically: no change of anatomy or width.

const REGION := Rect2(12, 94, 357, 396)
const PIVOT := Vector2(184, 483)
const SCALE := 0.58
const KEY_COUNT := 12
const STRIDE := 128.0
const COLS := 24
const ROWS := 32
var phase := 0.0
var weight := 0.0
var last_x := 0.0
var initialized := false
var mesh := ArrayMesh.new()
var rest := PackedVector2Array()
var uvs := PackedVector2Array()
var indices := PackedInt32Array()
var keys: Array[PackedVector2Array] = []

func _init() -> void:
	for row in range(ROWS + 1):
		for col in range(COLS + 1):
			var point := REGION.position + REGION.size * Vector2(float(col) / COLS, float(row) / ROWS)
			rest.append(point)
			uvs.append(point / Vector2(1536, 1024))
	for row in range(ROWS):
		for col in range(COLS):
			var a := row * (COLS + 1) + col
			indices.append_array(PackedInt32Array([a, a + 1, a + COLS + 1, a + 1, a + COLS + 2, a + COLS + 1]))
	for key in range(KEY_COUNT):
		var points := PackedVector2Array()
		for point in rest:
			points.append(gait_point(point, float(key) / KEY_COUNT))
		keys.append(points)

func reset(x: float) -> void:
	last_x = x
	initialized = true
	phase = 0.0
	weight = 0.0

static func eligible(f) -> bool:
	return f.health > 0.0 and f.stun <= 0.0 and f.attack.is_empty() and f.grounded() and not f.crouching

func update(f, dt: float) -> void:
	if not initialized:
		reset(f.pos.x)
	var distance: float = f.pos.x - last_x
	last_x = f.pos.x
	if absf(distance) > 60.0 or not eligible(f):
		phase = 0.0
		weight = 0.0
		return
	var moving: bool = f.walking and absf(distance) > 0.001
	if moving:
		phase = fposmod(phase + distance * f.facing / STRIDE, 1.0)
	weight = move_toward(weight, 1.0 if moving else 0.0, dt / (0.10 if moving else 0.12))
	if weight == 0.0:
		phase = 0.0

static func foot(cycle: float) -> Vector2:
	var p := fposmod(cycle, 1.0)
	# Low swing, then a longer planted support phase. Opposite feet are half a cycle apart.
	if p < 0.40:
		var t := p / 0.40
		return Vector2(lerpf(-24.0, 24.0, smoothstep(0.0, 1.0, t)), -14.0 * pow(sin(PI * t), 2.0))
	return Vector2(lerpf(24.0, -24.0, (p - 0.40) / 0.60), 0.0)

static func gait_point(point: Vector2, cycle: float) -> Vector2:
	var lower := smoothstep(338.0, 450.0, point.y)
	var side := smoothstep(5.0, 70.0, absf(point.x - PIVOT.x))
	var leg := foot(cycle if point.x > PIVOT.x else cycle + 0.5)
	# Bring each foot slightly inward rather than lengthening the wide idle stance.
	leg.x += -10.0 if point.x > PIVOT.x else 10.0
	var bob := 1.8 * sin(TAU * cycle * 2.0)
	return point + leg * lower * side + Vector2(0, bob * (1.0 - lower))

func vertices(at_phase: float, amount: float) -> PackedVector2Array:
	var cursor := fposmod(at_phase, 1.0) * KEY_COUNT
	var key := int(cursor)
	var t := cursor - key
	var result := PackedVector2Array()
	result.resize(rest.size())
	for i in range(rest.size()):
		var animated := keys[key][i].cubic_interpolate(keys[(key + 1) % KEY_COUNT][i], keys[(key + KEY_COUNT - 1) % KEY_COUNT][i], keys[(key + 2) % KEY_COUNT][i], t)
		# Cubic interpolation must not push a planted sole below its original ground.
		if rest[i].y >= 450.0:
			animated.y = minf(animated.y, rest[i].y)
		result[i] = (rest[i].lerp(animated, amount) - PIVOT) * SCALE
	return result

func draw(canvas: Node2D, texture: Texture2D, tint: Color) -> void:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices(phase, weight)
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	canvas.draw_mesh(mesh, texture, Transform2D.IDENTITY, tint)
