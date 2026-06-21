
extends CharacterBody2D

@export var speed: float = 220.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	#if RewindBuffer.is_rewinding():
		#return
	
	# for later I guess
	
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
