extends Node2D

@export var spawn_from_lower: Vector2 = Vector2.ZERO
@export var spawn_from_higher: Vector2 = Vector2.ZERO

@export var enemy_scene: PackedScene
@onready var walls: TileMapLayer = $Walls

const ROT_90_CW := TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_H
const ROT_180  := TileSetAtlasSource.TRANSFORM_FLIP_H | TileSetAtlasSource.TRANSFORM_FLIP_V
const ROT_90_CCW := TileSetAtlasSource.TRANSFORM_TRANSPOSE | TileSetAtlasSource.TRANSFORM_FLIP_V

var stage_one_buttons_pressed = 0

func _ready() -> void:
	print("[level] _ready, connecting to EventBus.button_pressed")
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

func reveal_spawn_room() -> void:
	var tiles_to_erase: Array[Vector2i] = [
		Vector2i(46, 10),
		Vector2i(47, 10),
		Vector2i(48, 10),
		Vector2i(49, 10),
		Vector2i(50, 10),
		Vector2i(51, 10),
		Vector2i(52, 10),
		Vector2i(53, 10),
		Vector2i(54, 10),
		Vector2i(55, 10),
		Vector2i(56, 10),
		Vector2i(57, 10),
		Vector2i(58, 10),
	]
	for cell in tiles_to_erase:
		walls.set_cell(cell, -1)
	
	var tiles_to_draw: Array[Dictionary] = [
		{"cell": Vector2i(45, 10), "atlas": Vector2i(3, 0), "rot": ROT_90_CCW},
		{"cell": Vector2i(59, 10), "atlas": Vector2i(3, 0), "rot": ROT_90_CW},
		{"cell": Vector2i(45, 14), "atlas": Vector2i(3, 0), "rot": ROT_180},
		{"cell": Vector2i(46, 14), "atlas": Vector2i(3, 0), "rot": ROT_180},
		{"cell": Vector2i(47, 14), "atlas": Vector2i(3, 0), "rot": ROT_180},
		{"cell": Vector2i(48, 14), "atlas": Vector2i(3, 0), "rot": ROT_180},
		{"cell": Vector2i(49, 14), "atlas": Vector2i(3, 0), "rot": ROT_180},
		{"cell": Vector2i(50, 14), "atlas": Vector2i(3, 0), "rot": ROT_180},
		{"cell": Vector2i(51, 14), "atlas": Vector2i(3, 0), "rot": ROT_180},
		{"cell": Vector2i(52, 14), "atlas": Vector2i(3, 0), "rot": ROT_180},
		{"cell": Vector2i(53, 14), "atlas": Vector2i(3, 0), "rot": ROT_180},
		{"cell": Vector2i(54, 14), "atlas": Vector2i(3, 0), "rot": ROT_180},
		{"cell": Vector2i(55, 14), "atlas": Vector2i(3, 0), "rot": ROT_180},
		{"cell": Vector2i(56, 14), "atlas": Vector2i(3, 0), "rot": ROT_180},
		{"cell": Vector2i(57, 14), "atlas": Vector2i(3, 0), "rot": ROT_180},
		{"cell": Vector2i(58, 14), "atlas": Vector2i(3, 0), "rot": ROT_180},
		{"cell": Vector2i(59, 14), "atlas": Vector2i(3, 0), "rot": ROT_180},
		
	]
	for tile in tiles_to_draw:
		if tile.rot:
			walls.set_cell(tile.cell, 2, tile.atlas, tile.rot)
		else:
			walls.set_cell(tile.cell, 2, tile.atlas)
	
	var spawn_positions: Array[Dictionary] = [
		{"x": 1533, "y": 519, "rot": 45},
		{"x": 1533, "y": 602, "rot": 135},
	]
	for dict in spawn_positions:
		var enemy = enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_position = Vector2(dict.x, dict.y)
		enemy.global_rotation = deg_to_rad(dict.rot)

func _on_button_pressed(button_id: int) -> void:
	print("[level] received button_pressed: id=%d" % button_id)
	match button_id:
		0, 1:
			stage_one_buttons_pressed += 1
			if stage_one_buttons_pressed >= 2:
				EventBus.door_lock_changed.emit(4, false)
				EventBus.door_lock_changed.emit(5, false)
				EventBus.door_lock_changed.emit(6, false)
				EventBus.door_lock_changed.emit(7, false)
		2:
			reveal_spawn_room()
		_:
			push_warning("Unhandled button press: %d" % button_id)
			print("[level] no mapping for button %d" % button_id)
