class_name LevelExit
extends Area2D

@export_enum("from_lower", "from_higher") var send_as: String = "from_lower"
@export_file("*.tscn") var next_scene: String

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		GameState.spawn_from = send_as
		get_tree().change_scene_to_file(next_scene)
