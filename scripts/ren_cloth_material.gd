extends RefCounted
## Conservative material selection in source UVs: teal fabric and ivory cloth.
## The overlay shares every pose/mesh UV, so it never drifts during animation.
const Wet = preload("res://scripts/wet_clothing.gd")
static var cached: Texture2D
const TROUSERS := [
	Rect2i(55, 334, 247, 120), Rect2i(466, 334, 208, 118),
	Rect2i(829, 304, 248, 150), Rect2i(1136, 332, 267, 121),
	Rect2i(61, 800, 266, 149), Rect2i(476, 750, 190, 91),
	Rect2i(776, 864, 267, 88), Rect2i(1244, 813, 225, 134)
]

static func is_cloth(c: Color) -> bool:
	if c.a < 0.1:
		return false
	var teal := c.h >= 0.46 and c.h <= 0.58 and c.s > 0.46 and c.v > 0.13
	var ivory := c.h >= 0.10 and c.h <= 0.18 and c.s < 0.40 and c.v > 0.43
	return teal or ivory

static func overlay(source: Texture2D, rebuild: bool = false) -> Texture2D:
	if cached != null and not rebuild:
		return cached
	if not rebuild and ResourceLoader.exists("res://assets/fighters/ren/wet-cloth.res"):
		cached = load("res://assets/fighters/ren/wet-cloth.res")
		return cached
	var image := source.get_image()
	image.convert(Image.FORMAT_RGBA8)
	var pixels := image.get_data()
	for i in range(0, pixels.size(), 4):
		var c := Color8(pixels[i], pixels[i + 1], pixels[i + 2], pixels[i + 3])
		var cloth := is_cloth(c)
		# Pose-specific trouser regions include their dark folds, without selecting skin.
		if c.a > 0.1 and c.h > 0.045 and c.h < 0.20 and c.v > 0.18 and c.s < 0.72:
			var point := Vector2i((i / 4) % image.get_width(), (i / 4) / image.get_width())
			for area in TROUSERS:
				if area.has_point(point):
					cloth = true
					break
		if not cloth:
			pixels[i + 3] = 0
			continue
		var wet := Wet.tint(c, 1.0)
		pixels[i] = int(wet.r * 255)
		pixels[i + 1] = int(wet.g * 255)
		pixels[i + 2] = int(wet.b * 255)
	cached = ImageTexture.create_from_image(Image.create_from_data(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, pixels))
	return cached
