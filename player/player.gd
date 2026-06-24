class_name Player
extends CharacterBody2D

@export var speed: float = 220.0
@export var push_strength: float = 400.0

@export var invincible: bool = false   # debug
@export var respawn_delay: float = 1

var _dead: bool = false

const ANIMATIONS_NEEDING_FLIP_V := ["player_push", "player_pull", "player_push_pull_start"]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var RewindBuffer = %RewindBuffer

@onready var foootstep_audio: AudioStreamPlayer = %FootstepAudio
@onready var step_timer: Timer = %StepTimer

@onready var tooltip_label: Label = %TooltipLabel

func _ready() -> void:
	RewindBuffer.clear()
	step_timer.start()

func _physics_process(_delta: float) -> void:
	if RewindBuffer.is_rewinding():
		return
	
	_update_tooltip()
	handle_movement()
	footstep_audio()



func footstep_audio():
	if velocity.length() > 0:
		print("1. Animation and velocity are correct!")
		if step_timer.is_stopped():
			print("2. Timer is stopped! Playing audio now.")
			foootstep_audio.play()
			step_timer.start(0.35)

func _get_tooltip_text() -> String:

	if _carried:
		return "[Release Right-click to drop  |  Left-click to throw]"
	
	if _held:
		return "[Release Right-click to drop]"
	
	
	if not _nearby_draggables.is_empty():
		return "[Right-click to grab]"
	
	if not _nearby_throwables.is_empty():
		return "[Right-click to pick up]"
	
	if _closest_button() != null:
		return "[Right-click to press]"
	
	for door in _nearby_doors:
		if door.can_open():
			return "[Right-click to open door]"
		elif door.is_locked:
			return "[Door is locked]"
	
	return ""


func _update_tooltip() -> void:
	if RewindBuffer.is_rewinding() or _dead:
		tooltip_label.text = ""
		return
	tooltip_label.text = _get_tooltip_text()



func take_damage(amount: float) -> void:
	if invincible or _dead:
		return
	if EventBus.is_rewinding:
		return
	die()

func die() -> void:
	_dead = true
	print("Player died")
	
	set_physics_process(false)
	set_process_input(false)
	
	if RewindBuffer.rewinding:
		RewindBuffer.stop_rewind()
	velocity = Vector2.ZERO
	
	
	await get_tree().create_timer(respawn_delay).timeout
	if is_inside_tree():
		get_tree().reload_current_scene()

# interact section
var _nearby_draggables: Array[Draggable] = []
var _held: Draggable = null

var _nearby_buttons: Array[WallButton] = []

var _nearby_throwables: Array[Throwable] = []
var _carried: Throwable = null

var _nearby_doors: Array[Door] = []


func register_nearby_door(door: Door) -> void:
	if not _nearby_doors.has(door):
		_nearby_doors.append(door)


func unregister_nearby_door(door: Door) -> void:
	_nearby_doors.erase(door)

func _on_throwable_area_entered(t: Throwable) -> void:
	if not _nearby_throwables.has(t):
		_nearby_throwables.append(t)

func _on_throwable_area_exited(t: Throwable) -> void:
	_nearby_throwables.erase(t)
	
func _closest_throwable() -> Throwable:
	var best: Throwable = null
	var best_dist: float = INF
	for t in _nearby_throwables:
		var dist := global_position.distance_squared_to(t.global_position)
		if dist < best_dist:
			best_dist = dist
			best = t
	return best

func _on_button_area_entered(button: WallButton) -> void:
	if not _nearby_buttons.has(button):
		_nearby_buttons.append(button)

func _on_button_area_exited(button: WallButton) -> void:
	_nearby_buttons.erase(button)

var _grab_forward: Vector2 = Vector2.ZERO 

func _on_grab_area_entered(draggable: Draggable) -> void:
	if not _nearby_draggables.has(draggable):
		_nearby_draggables.append(draggable)

func _on_grab_area_exited(draggable: Draggable) -> void:
	_nearby_draggables.erase(draggable)

func _closest_button() -> WallButton:
	var best: WallButton = null
	var best_dist: float = INF
	for b in _nearby_buttons:
		var dist := global_position.distance_squared_to(b.global_position)
		if dist < best_dist:
			best_dist = dist
			best = b
	return best

func _try_interact() -> void:
	if not _nearby_draggables.is_empty():
		_try_grab()
		return
	
	if _try_pickup():
		sprite.play("player_pick_up")
		return
	
	var closest_button := _closest_button()
	if closest_button:
		rotation = (closest_button.global_position - global_position).angle() + PI/2
		sprite.play("player_button_press")
		closest_button.press()
		return
	
	var opened_any := false
	for door in _nearby_doors:
		if door.can_open():
			door.try_open(global_position)
			opened_any = true

	if opened_any:
		return

func _try_pickup() -> bool:
	var closest := _closest_throwable()
	if closest and closest.try_pickup(self):
		rotation = (closest.global_position - global_position).angle() + PI/2
		_carried = closest
		return true
	return false

func _drop_carried() -> void:
	if _carried:
		_carried.drop_at(global_position + Vector2(
			sin(global_rotation), -cos(global_rotation) 
		) * 15)
		_carried = null

func _throw_to(target: Vector2) -> void:
	if _carried:
		rotation = (target - global_position).angle() + PI/2
		sprite.play("player_throw_throw")
		_carried.throw_from_to(global_position, target)
		_carried = null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("grab"):
		if _carried:
			return
		_try_interact()
	elif event.is_action_released("grab"):
		if _carried:
			_drop_carried()
		elif _held:
			_release()
	
	elif event.is_action_pressed("throw"):
		if _carried:
			_throw_to(get_global_mouse_position())

func _try_grab() -> void:
	if _held != null:
		return
	var closest := _closest_draggable()
	if closest and closest.try_grab(self):
		_held = closest
		_grab_forward = Vector2.from_angle(rotation - PI/2)
		sprite.play("player_push_pull_start")
		$DragSound.play()

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

# end interact section

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
		if collider is RigidBody2D and not collider.freeze:
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
		if sprite.is_playing() and sprite.animation in ["player_button_press", "player_pick_up", "player_throw_throw"]:
			return
		
		sprite.flip_h = false
		if input_dir != Vector2.ZERO:
			if sprite.animation != "player_walk":
				sprite.play("player_walk")
		else:
			if sprite.animation != "player_idle":
				sprite.play("player_idle")
	
	sprite.flip_v = sprite.animation in ANIMATIONS_NEEDING_FLIP_V
