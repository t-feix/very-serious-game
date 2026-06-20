class_name Player
extends CharacterBody2D

@export var speed: float = 220.0
@export var push_strength: float = 5000.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	#if RewindBuffer.is_rewinding():
		#return
	
	handle_movement()

func handle_movement():
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	
	if input_dir != Vector2.ZERO:
		rotation = input_dir.angle() + PI/2
		if not sprite.is_playing():
			sprite.play("walk")
	else:
		sprite.stop()
		sprite.frame = 0
	
	move_and_slide()
	
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is RigidBody2D:
			var contact_local: Vector2 = collision.get_position() - collider.global_position
			collider.apply_force(-collision.get_normal() * push_strength, contact_local)
