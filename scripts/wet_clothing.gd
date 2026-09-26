extends RefCounted
## Cosmetic state, independent of combat and random number generators.
var levels: Array[float] = [0.0, 0.0]
var contact_age: Array[float] = [100.0, 100.0]

func update(dt: float, contacts: Dictionary, paused: bool = false) -> void:
	if paused or dt <= 0.0:
		return
	var step := minf(dt, 0.05)
	for i in range(levels.size()):
		contact_age[i] += step
		if contacts.get(i, 0) > 0:
			contact_age[i] = 0.0
		# Cloth absorbs residual water for a short time after a real rain contact.
		if contact_age[i] < 3.0:
			levels[i] = minf(1.0, levels[i] + step * 0.09)
		else:
			levels[i] = maxf(0.0, levels[i] - step * 0.008)

static func tint(color: Color, amount: float) -> Color:
	var wet := Color(color.r * 0.44, color.g * 0.50, color.b * 0.57, color.a)
	# Dark saturated fabric and narrow cool highlights emphasize the existing folds.
	var highlight := pow(color.v, 8.0) * 0.22
	wet.r += highlight * 0.68
	wet.g += highlight * 0.80
	wet.b += highlight
	return color.lerp(wet, clampf(amount, 0.0, 1.0))
