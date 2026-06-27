class_name Draggable
extends AnimatableBody2D

enum ShapeType { RECTANGLE, CIRCLE }
@export var shape_type: ShapeType = ShapeType.RECTANGLE
@export var grab_distance_vertical: float = 26.0
@export var grab_distance_horizontal: float = 43.0
@export var drag_weight: float = 1.0

@export var sprite_texture: Texture2D
@onready var sprite: Sprite2D = $Sprite2D


var _held_by: Node2D = null
var _grab_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	var grab_area := $GrabArea as Area2D
	grab_area.body_entered.connect(_on_body_entered)
	grab_area.body_exited.connect(_on_body_exited)
	
	if sprite_texture:
		sprite.texture = sprite_texture

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body._on_grab_area_entered(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body._on_grab_area_exited(self)

func try_grab(grabber: Node2D) -> bool:
	if _held_by != null:
		return false
	_held_by = grabber
	add_collision_exception_with(grabber)
	var to_grabber: Vector2 = grabber.global_position - global_position

	match shape_type:
		ShapeType.RECTANGLE:
			var snapped_dir := _snap_to_cardinal(to_grabber)
			var dist: float = grab_distance_horizontal if snapped_dir.x != 0 else grab_distance_vertical
			var snap_pos := global_position + snapped_dir * dist
			
			if _position_is_clear_for(grabber, snap_pos):
				grabber.global_position = snap_pos
				grabber.rotation = (-snapped_dir).angle() + PI/2
				_grab_offset = snapped_dir * dist
			else:
				remove_collision_exception_with(grabber)
				_held_by = null
				return false
		
		ShapeType.CIRCLE:
			grabber.rotation = (-to_grabber.normalized()).angle() + PI/2
			_grab_offset = to_grabber
	return true


func _position_is_clear_for(body: Node2D, candidate: Vector2) -> bool:
	var params := PhysicsTestMotionParameters2D.new()
	params.from = Transform2D(body.rotation, candidate)
	params.motion = Vector2.ZERO
	params.recovery_as_collision = true
	
	var result := PhysicsTestMotionResult2D.new()
	var would_collide := PhysicsServer2D.body_test_motion(body.get_rid(), params, result)
	
	return not would_collide



func release() -> void:
	if _held_by:
		remove_collision_exception_with(_held_by)
	_held_by = null

#func _physics_process(_delta: float) -> void:
	#if _held_by != null:
		#global_position = _held_by.global_position - _grab_offset

func update_held_position(grabber_pos: Vector2) -> void:
	var target := grabber_pos - _grab_offset
	var motion := target - global_position
	var collision := move_and_collide(motion)
	if collision and _held_by:
		_held_by.global_position = global_position + _grab_offset

func _snap_to_cardinal(direction: Vector2) -> Vector2:
	if abs(direction.x) > abs(direction.y):
		return Vector2.RIGHT if direction.x > 0 else Vector2.LEFT
	else:
		return Vector2.DOWN if direction.y > 0 else Vector2.UP
