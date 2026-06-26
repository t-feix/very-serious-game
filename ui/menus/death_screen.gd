extends Control
@export var main_menu_scene: String = "res://ui/menus/main_menu.tscn"

@onready var respawn_button: Button = %RespawnButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	respawn_button.pressed.connect(_on_respawn_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_respawn_pressed() -> void:
	$UIConfirm.play()
	await get_tree().create_timer(0.5).timeout
	var level_path: String = GameState.last_level_path
	if level_path == "":
		get_tree().change_scene_to_file(main_menu_scene)
		return
	get_tree().change_scene_to_file(level_path)


func _on_quit_pressed() -> void:
	$UIConfirm.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file(main_menu_scene)


func _on_start_new_game_button_mouse_entered() -> void:
	$UIHover.play()


func _on_quit_button_mouse_entered() -> void:
	$UIHover.play()
