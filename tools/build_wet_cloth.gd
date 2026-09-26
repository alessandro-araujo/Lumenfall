extends SceneTree
func _initialize() -> void:
	var material = load("res://scripts/ren_cloth_material.gd")
	var texture = material.overlay(load("res://assets/fighters/ren/poses.png"), true)
	var error := ResourceSaver.save(texture, "res://assets/fighters/ren/wet-cloth.res")
	print("WET MATERIAL BUILD: ", error)
	quit(error)
