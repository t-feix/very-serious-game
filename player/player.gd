class_name Player
extends CharacterBody2D

@export var speed: float = 220.0

func _physics_process(_delta: float) -> void:
	#if RewindBuffer.is_rewinding():
		#return
	
	# for later I guess
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	
	look_at(get_global_mouse_position())
	
	move_and_slide()
