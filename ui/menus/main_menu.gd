extends Control

func _on_start_pressed() -> void:
	$UIConfirm.play()
	await get_tree().create_timer(0.5).timeout
	GameState.spawn_from = "from_lower"
	get_tree().change_scene_to_file("res://world/Floor0.tscn")


func _on_quit_pressed() -> void:
	$UIConfirm.play()
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()


func _on_start_new_game_button_mouse_entered() -> void:
	$UIHover.play()


func _on_load_saved_game_button_mouse_entered() -> void:
	$UIHover.play()


func _on_options_button_mouse_entered() -> void:
	$UIHover.play()


func _on_quit_button_mouse_entered() -> void:
	$UIHover.play()


func _on_options_button_pressed() -> void:
	$UIConfirm.play()
	await get_tree().create_timer(0.5).timeout


func _on_load_saved_game_button_pressed() -> void:
	$UIConfirm.play()
	await get_tree().create_timer(0.5).timeout
