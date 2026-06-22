class_name Throwable
extends Area2D

@export var throwable_id: int = 0
@export var throw_duration: float = 0.3
@export var wall_offset: float = 8.0

@onready var sprite: Sprite2D = $Sprite2D

var _carried_by: Node2D = null

signal picked_up
signal put_down

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body._on_throwable_area_entered(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body._on_throwable_area_exited(self)

func try_pickup(carrier: Node2D) -> bool:
	if _carried_by != null:
		return false
	_carried_by = carrier
	sprite.visible = false
	picked_up.emit()
	return true

func drop_at(pos: Vector2) -> void:
	if _carried_by == null:
		return
	var validated := _find_valid_position(pos)
	_carried_by = null
	global_position = validated
	sprite.visible = true
	put_down.emit()

func throw_from_to(start: Vector2, target: Vector2) -> void:
	if _carried_by == null:
		return
	var landing := _compute_throw_landing(start, target)
	_carried_by = null
	global_position = start
	sprite.visible = true
	var tween := create_tween()
	tween.tween_property(self, "global_position", landing, throw_duration)
	put_down.emit()

func is_carried() -> bool:
	return _carried_by != null

func _compute_throw_landing(start: Vector2, target: Vector2) -> Vector2:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(start, target)
	query.collision_mask = 1
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return target

	var direction := (target - start).normalized()
	return result.position - direction * wall_offset

func _find_valid_position(pos: Vector2) -> Vector2:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 1
	var results := space_state.intersect_point(query)
	if results.is_empty():
		return pos

	return _carried_by.global_position if _carried_by else pos
