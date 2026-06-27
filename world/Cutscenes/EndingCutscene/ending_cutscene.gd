extends Control

@export_file("*.tscn") var next_scene: String = "res://world/Tutorial/Tutorial.tscn"

@onready var image: TextureRect = $Image
@onready var display_text: Label = $Label

const PANELS = [
	["res://world/Cutscenes/EndingCutscene/S04.png", "", 4.0],
]


func _ready() -> void:
	_play_sequence()


func _play_sequence() -> void:
	for panel in PANELS:
		await _show_panel(panel[0], panel[1], panel[2])
	
	_finish()


func _show_panel(texture_path: String, text: String, duration: float) -> void:
	var fade_out := create_tween()
	fade_out.set_parallel(true)
	fade_out.tween_property(image, "modulate:a", 0.0, 0.3)
	fade_out.tween_property(display_text, "modulate:a", 0.0, 0.3)
	await fade_out.finished
	
	image.texture = load(texture_path)
	display_text.text = text
	
	var fade_in := create_tween()
	fade_in.set_parallel(true)
	fade_in.tween_property(image, "modulate:a", 1.0, 0.4)
	fade_in.tween_property(display_text, "modulate:a", 1.0, 0.4)
	await fade_in.finished
	
	await get_tree().create_timer(duration).timeout


func _finish() -> void:
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.6)
	await fade.finished
	GameState.spawn_from = "from_lower"
	get_tree().change_scene_to_file(next_scene)
