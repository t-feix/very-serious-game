extends Node2D

@export var door_id: int = 0
@export var is_locked: bool = false

@onready var rigid_body: RigidBody2D = $"Door_Rigid Body"

func _ready() -> void:
	EventBus.door_lock_changed.connect(_on_lock_changed)
	_apply_lock_state()

func _on_lock_changed(target_id: int, locked: bool) -> void:
	if target_id == door_id:
		is_locked = locked
		_apply_lock_state()

func _apply_lock_state() -> void:
	if is_locked:
		rigid_body.rotation = 0.0
		rigid_body.angular_velocity = 0.0
		rigid_body.linear_velocity = Vector2.ZERO
		rigid_body.freeze = true
	else:
		rigid_body.angular_velocity = 0.0
		rigid_body.linear_velocity = Vector2.ZERO
		rigid_body.freeze = false
