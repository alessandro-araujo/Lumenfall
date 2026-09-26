extends SceneTree
const Wet = preload("res://scripts/wet_clothing.gd")
const Cloth = preload("res://scripts/ren_cloth_material.gd")
const Rain = preload("res://scripts/rain_effect.gd")
const Fighter = preload("res://scripts/fighter.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1

func _initialize() -> void:
	var wet := Wet.new()
	for i in range(120):
		wet.update(1.0 / 60.0, {})
	check(wet.levels[0] == 0, "Dry clothing stays dry without contacts")
	for i in range(600):
		wet.update(1.0 / 60.0, {0: 1})
	check(wet.levels[0] > 0.8 and wet.levels[0] < 0.99, "Wetness builds gradually")
	check(wet.levels[1] == 0, "Wetness is individual per fighter")
	var saved := wet.levels.duplicate()
	wet.update(0.05, {1: 1}, true)
	check(saved == wet.levels, "Pause freezes absorption and drying")
	for i in range(10800):
		wet.update(1.0 / 60.0, {})
	check(wet.levels[0] == 0, "Clothing dries after rain contacts stop")
	for i in range(2400):
		wet.update(1.0 / 60.0, {0: 1, 1: 1})
	check(wet.levels[0] == 1 and wet.levels[1] == 1, "Wetness saturates and stays bounded")
	check(Cloth.is_cloth(Color8(238, 212, 168)), "Ivory trousers are cloth")
	check(Cloth.is_cloth(Color8(10, 110, 140)), "Teal sash is cloth")
	check(not Cloth.is_cloth(Color8(246, 155, 90)), "Skin must not receive fabric treatment")
	check(not Cloth.is_cloth(Color8(252, 252, 253)), "Sword must not receive fabric treatment")
	check(not Cloth.is_cloth(Color8(30, 25, 40)), "Hair must not receive fabric treatment")
	var rain := Rain.new()
	var fighter := Fighter.new()
	fighter.reset(400, 1)
	rain.drops.clear()
	rain.drops.append({"pos": Vector2(400, 340), "layer": 1, "ground": 562.0, "speed": 1000.0})
	rain.update(0.05, [fighter])
	check(rain.body_contacts.get(0, 0) == 1, "Body hit identifies the correct wet fighter")
	rain.enabled = false
	rain.update(0.05, [fighter])
	check(rain.body_contacts.is_empty(), "Stopped rain clears stale contacts")
	check(fighter.health == 100, "Cosmetic moisture never damages fighters")
	print("WET CLOTHING: ", failures, " failures")
	quit(failures)
