extends Node2D

const POSTER = preload("res://assets/arenas/templo-ao-luar/render-poster.png")
const RENDER = preload("res://assets/arenas/templo-ao-luar/render-aprovado.ogv")
var playback := VideoStreamPlayer.new()
var stage_time := -1.0

func _ready() -> void:
	show_behind_parent = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var poster := Sprite2D.new()
	poster.texture = POSTER
	poster.centered = false
	add_child(poster)
	playback.name = "ApprovedStageRender"
	playback.stream = RENDER
	playback.expand = true
	playback.size = Vector2(1280, 720)
	playback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	playback.loop = true
	playback.volume_db = -80.0
	add_child(playback)
	playback.play()

func set_time(value: float) -> void:
	# The arena clock controls pause/resume; the native decoder handles the loop.
	# Theora has no seeking, so this method must not restart playback each frame.
	playback.paused = stage_time == value
	stage_time = value
