extends Node2D

@export var spawn_from_lower: Vector2 = Vector2.ZERO
@export var spawn_from_higher: Vector2 = Vector2.ZERO

func _ready() -> void:
	GameState.last_level_path = scene_file_path
	EventBus.button_pressed.connect(_on_button_pressed)
		
	var player := get_node_or_null("Player") as Player
	if player == null:
		return
	MusicManager.on_level_loaded(self)
	
	if GameState.spawn_from == "from_higher":
		player.global_position = spawn_from_higher
	else:
		player.global_position = spawn_from_lower
	
	GameState.spawn_from = ""

func _on_button_pressed(button_id: int) -> void:
	match button_id:
		0:
			EventBus.door_lock_changed.emit(2, false)
			EventBus.door_lock_changed.emit(3, false)
		1:
			EventBus.door_lock_changed.emit(6, false)
			EventBus.door_lock_changed.emit(7, false)
		2:
			EventBus.door_lock_changed.emit(10, false)
			EventBus.door_lock_changed.emit(11, false)
		_:
			push_warning("Unhandled button press: %d" % button_id)
