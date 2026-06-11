extends Node


func _ready() -> void:
	# main.tscn is just an entry point for the game and switches
	# immediately to main_menu.tscn. If we want to add something
	# like a splash screen, we can add it to main.tscn and wait
	# for a few seconds before switching.
	get_tree().change_scene_to_file("res://ui/menus/main_menu.tscn")
