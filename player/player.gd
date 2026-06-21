class_name Player
extends CharacterBody2D

@export var speed: float = 220.0
@export var push_strength: float = 400.0

const ANIMATIONS_NEEDING_FLIP_V := ["player_push", "player_pull", "player_push_pull_start"]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var RewindBuffer = %RewindBuffer

func _physics_process(_delta: float) -> void:
	if RewindBuffer.is_rewinding():
		return
	
	handle_movement()

# draggable section
var _nearby_draggables: Array[Draggable] = []
var _held: Draggable = null

var _grab_forward: Vector2 = Vector2.ZERO 

func _on_grab_area_entered(draggable: Draggable) -> void:
	if not _nearby_draggables.has(draggable):
		_nearby_draggables.append(draggable)

func _on_grab_area_exited(draggable: Draggable) -> void:
	_nearby_draggables.erase(draggable)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("grab"):
		_try_grab()
	elif event.is_action_released("grab"):
		_release()

func _try_grab() -> void:
	if _held != null:
		return
	var closest := _closest_draggable()
	if closest and closest.try_grab(self):
		_held = closest
		_grab_forward = Vector2.from_angle(rotation - PI/2)
		sprite.play("player_push_pull_start")

func _release() -> void:
	if _held:
		_held.release()
		_held = null

func _closest_draggable() -> Draggable:
	var best: Draggable = null
	var best_dist: float = INF
	for d in _nearby_draggables:
		var dist := global_position.distance_squared_to(d.global_position)
		if dist < best_dist:
			best_dist = dist
			best = d
	return best

# end draggable section

func handle_movement():
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	var effective_speed := speed
	if _held != null:
		effective_speed *= 1.0 / (1.0 + _held.drag_weight)
	
	velocity = input_dir * effective_speed
	
	if input_dir != Vector2.ZERO and _held == null:
		rotation = input_dir.angle() + PI/2
	
	_update_sprite(input_dir)
	move_and_slide()
	
	if _held:
		_held.update_held_position(global_position)
	
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is RigidBody2D:
			var contact_local: Vector2 = collision.get_position() - collider.global_position
			collider.apply_force(-collision.get_normal() * push_strength, contact_local)

func _update_sprite(input_dir: Vector2) -> void:
	sprite.flip_v = sprite.animation in ANIMATIONS_NEEDING_FLIP_V
	if _held != null:
		if sprite.animation == "player_push_pull_start" and sprite.is_playing():
			return
		
		if input_dir == Vector2.ZERO:
			sprite.pause()
			return

		var alignment := input_dir.normalized().dot(_grab_forward)
		var target_anim := "player_push" if alignment >= 0 else "player_pull"
		
		if sprite.animation != target_anim:
			sprite.play(target_anim)
		elif not sprite.is_playing():
			sprite.play(target_anim)
	else:
		if input_dir != Vector2.ZERO:
			sprite.flip_h = false
			if sprite.animation != "Player walk" or not sprite.is_playing():
				sprite.play("Player walk")
		else:
			sprite.stop()
			sprite.frame = 2
	
	sprite.flip_v = sprite.animation in ANIMATIONS_NEEDING_FLIP_V
