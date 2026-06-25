extends Node2D

@export var spawn_from_lower: Vector2 = Vector2.ZERO
@export var spawn_from_higher: Vector2 = Vector2.ZERO

func _ready() -> void:
	GameState.last_level_path = scene_file_path
	
	var player := get_node_or_null("Player") as Player
	if player == null:
		return
	
	if GameState.spawn_from == "from_higher":
		player.global_position = spawn_from_higher
	else:
		player.global_position = spawn_from_lower
	
	GameState.spawn_from = ""
