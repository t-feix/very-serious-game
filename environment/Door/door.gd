class_name Door extends AnimatableBody2D

@export var unlocked_texture: Texture2D = preload("res://environment/door/door_green.tres")
@export var locked_texture: Texture2D = preload("res://environment/door/door_red.tres")

@export var door_id: int = 0
@export var is_locked: bool = false
@export var swing_angle_deg: float = 90.0
@export var swing_duration: float = 0.2
@onready var sprite: Sprite2D = $Sprite2D

enum State { CLOSED, OPENING, OPEN }
var state: State = State.CLOSED

@onready var player_sensor: Area2D = $PlayerSensor

func is_swinging() -> bool:
	return state == State.OPENING


func _ready() -> void:
	add_to_group("doors")
	EventBus.door_lock_changed.connect(_on_lock_changed)
	player_sensor.body_entered.connect(_on_player_entered)
	player_sensor.body_exited.connect(_on_player_exited)
	_update_sprite()


func _on_lock_changed(target_id: int, locked: bool) -> void:
	print("[door %d] received lock_changed: target=%d locked=%s (my id=%d)" % [
		door_id, target_id, locked, door_id
	])
	if target_id == door_id:
		is_locked = locked
		print("[door %d] is_locked is now %s" % [door_id, is_locked])
		_update_sprite()
	
	

func _update_sprite() -> void:
	if is_locked:
		sprite.texture = locked_texture
	else:
		sprite.texture = unlocked_texture


func can_open() -> bool:
	return state == State.CLOSED and not is_locked


func try_open(opener_pos: Vector2) -> bool:
	if not can_open():
		return false
	
	state = State.OPENING
	

	var to_opener := opener_pos - global_position
	var door_normal := Vector2.UP.rotated(rotation)
	var side := signf(to_opener.dot(door_normal))
	if side == 0.0:
		side = 1.0
	
	var target_rot := rotation - side * deg_to_rad(swing_angle_deg)
	
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "rotation", target_rot, swing_duration)
	tween.tween_callback(_on_swing_finished)
	
	return true


func _on_swing_finished() -> void:
	remove_from_group("navigation_polygon_source")
	var nav_region_node = get_tree().get_first_node_in_group("nav_region")
	if nav_region_node:
		nav_region_node.bake_navigation_polygon()
	state = State.OPEN


func _on_player_entered(body) -> void:
	if body is Player:
		body.register_nearby_door(self)


func _on_player_exited(body) -> void:
	if body is Player:
		body.unregister_nearby_door(self)
