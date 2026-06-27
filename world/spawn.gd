extends Node2D

@export var spawn_from_lower: Vector2 = Vector2.ZERO
@export var spawn_from_higher: Vector2 = Vector2.ZERO

func _ready() -> void:
	var player := get_node_or_null("Player") as Player
	if player == null:
		return
	MusicManager.on_level_loaded(self)
	if GameState.spawn_from == "from_higher":
		player.global_position = spawn_from_higher
	else:
		player.global_position = spawn_from_lower
	
	GameState.spawn_from = ""
