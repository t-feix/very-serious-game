extends CharacterBody2D

@export var speed: float = 200.0
@export var arrival_threshold: float = 4.0

var target_position: Vector2

func _ready() -> void:
	target_position = global_position

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and \
	event.button_index == MOUSE_BUTTON_LEFT:
		target_position = get_global_mouse_position()

func _physics_process(_delta: float) -> void:
	var to_target := target_position - global_position
	if to_target.length() <= arrival_threshold:
		velocity = Vector2.ZERO
	else:
		velocity = to_target.normalized() * speed
	if velocity.length() > 0:
		rotation = velocity.angle() + PI/2 
		move_and_slide()
