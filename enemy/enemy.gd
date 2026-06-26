extends CharacterBody2D

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D


@onready var vision_light: PointLight2D = $PointLight2D

func _nav_move(target_pos: Vector2, move_speed: float) -> bool:
	nav_agent.target_position = target_pos
	
	if nav_agent.is_navigation_finished():
		nav_agent.velocity = Vector2.ZERO
		velocity = Vector2.ZERO
		_stable_move()
		return false
	
	var next_pos := nav_agent.get_next_path_position()
	var dir := (next_pos - global_position).normalized()
	var desired_velocity := dir * move_speed * _current_time_scale()
	
	nav_agent.velocity = desired_velocity   # avoidance computes safe velocity
	_face_direction(dir)
	
	return true

# --- STATES ---
enum State {IDLE, ALERT, CHASE, SHOOT, RETURN, INVESTIGATE}
var current_state = State.IDLE
var previous_state = -1

# --- STATS ---
@export var speed: float = 100.0
@export var shoot_range: float = 200.0
@export var fire_rate: float = 1
@export var health: float = 1.0  # Dies in 1 hit
@export var turn_speed: float = 4

# --- VISION ---
@export var vision_range: float = 250.0
@export var vision_angle_deg: float = 45.0

# --- PURSUIT ---
@export var max_pursuit_distance: float = 500.0

# --- BULLET ---
@export var bullet_scene: PackedScene

# --- DEBUG ---
@export var debug_enabled: bool = true

# --- REWIND ---
@export var rewind_time_scale: float = 0.2  # speed multiplier during rewind

# --- INTERNAL ---
var anchor: Vector2
var anchor_rotation: float
var player: Player = null
var can_shoot: bool = true
var alert_timer: float = 0.0
var alert_duration: float = 1.0

# Investigate state internals
var _investigate_pos: Vector2
var _investigate_scanning: bool = false
var _investigate_scan_progress: float = 0.0
const INVESTIGATE_SCAN_SPEED: float = PI/2

var _investigate_base_rotation: float = 0.0
var _investigate_sweep_phase: int = 0
var _investigate_pause_timer: float = 0.0
const INVESTIGATE_SWEEP_LEFT: float = deg_to_rad(45.0)
const INVESTIGATE_SWEEP_RIGHT: float = deg_to_rad(90.0)
const INVESTIGATE_PAUSE_DURATION: float = 1.0


var _shoot_cooldown: float = 0.0
var _is_rewinding: bool = false

var state_names = {
	State.IDLE: "IDLE",
	State.ALERT: "ALERT",
	State.CHASE: "CHASE",
	State.SHOOT: "SHOOT",
	State.RETURN: "RETURN",
	State.INVESTIGATE: "INVESTIGATE"
}

# --- NODES ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var vision_debug = $VisionConeDebug


func dprint(msg: String) -> void:
	if debug_enabled and 1 == 0:
		print(msg)


func _current_time_scale() -> float:
	return rewind_time_scale if _is_rewinding else 1.0


func _on_rewind_started() -> void:
	_is_rewinding = true
	sprite.speed_scale = rewind_time_scale
	dprint("[%s] Rewind started, slowing to %.2fx" % [name, rewind_time_scale])


func _on_rewind_ended() -> void:
	_is_rewinding = false
	sprite.speed_scale = 1.0
	dprint("[%s] Rewind ended, resuming full speed" % name)



func _face_direction(dir: Vector2) -> void:
	if dir.length() < 0.001:
		return
	var target_rot = dir.angle() - PI / 2
	var max_step = turn_speed * _current_time_scale() * get_physics_process_delta_time()
	rotation = rotate_toward(rotation, target_rot, max_step)


func _face_position(target_pos: Vector2) -> void:
	_face_direction(target_pos - global_position)


func _stable_move() -> void:
	var intended := velocity
	var pos_before := global_position
	
	var was_overlapping := test_move(global_transform, Vector2.ZERO)
	
	move_and_slide()
	
	if was_overlapping:
		return
	
	var actual := global_position - pos_before
	
	if intended.length() < 0.001:
		global_position = pos_before
		return
	
	var intended_dir := intended.normalized()
	var along := actual.dot(intended_dir)
	var max_along := intended.length() * get_physics_process_delta_time() + 1.0
	along = clamp(along, 0.0, max_along)
	
	global_position = pos_before + intended_dir * along


func _ready():
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	sprite.rotation = PI
	EventBus.noise_made.connect(_on_noise_made)
	dprint("==============================================")
	dprint("!!! NEW SCRIPT LOADED !!!")
	dprint("!!! SCRIPT PATH: %s" % get_script().resource_path)
	dprint("!!! NODE NAME: %s" % name)
	dprint("!!! CHILDREN:")
	for child in get_children():
		dprint("  -> %s | %s" % [child.name, child.get_class()])
	dprint("==============================================")
	
	anchor = global_position
	anchor_rotation = global_rotation
	
	build_vision_debug()
	vision_debug.visible = false
	

	dprint("[%s] Connecting signals..." % name)
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	EventBus.rewind_started.connect(_on_rewind_started)
	EventBus.rewind_ended.connect(_on_rewind_ended)
	dprint("[%s] Signals connected!" % name)
	
	current_state = State.IDLE
	
	dprint("[%s] READY | Anchor: %s" % [name, anchor])
	dprint("[%s] DetectionArea monitoring: %s" % [name, detection_area.monitoring])
	dprint("[%s] DetectionArea mask: %s" % [name, detection_area.collision_mask])
	

	dprint("[%s] === ANIMATION CHECK ===" % name)
	if sprite.sprite_frames == null:
		dprint("[%s] !!! NO SPRITE FRAMES !!!" % name)
	else:
		var anims = sprite.sprite_frames.get_animation_names()
		dprint("[%s] Available animations: %s" % [name, anims])
		for a in anims:
			var count = sprite.sprite_frames.get_frame_count(a)
			dprint("[%s]   -> '%s' has %s frames" % [name, a, count])
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var found_player := get_tree().get_first_node_in_group("player")
	if found_player:
		dprint("[%s] FOUND PLAYER: %s | Layer: %s" % [name, found_player.name, found_player.collision_layer])
	else:
		dprint("[%s] !!! WARNING: NO PLAYER FOUND !!!" % name)
	

	for body in detection_area.get_overlapping_bodies():
		if body is Player:
			player = body
			dprint("[%s] Player already in detection area at spawn" % name)
			break

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	_stable_move()

func _on_noise_made(noise_pos: Vector2, radius: float) -> void:
	if current_state != State.IDLE:
		return
	
	if global_position.distance_to(noise_pos) > radius:
		return
	
	dprint("[%s] Heard noise at %s -> INVESTIGATE" % [name, noise_pos])
	_investigate_pos = noise_pos
	_investigate_scanning = false
	_investigate_scan_progress = 0.0
	current_state = State.INVESTIGATE

func _physics_process(delta):
	if current_state != previous_state:
		dprint("[%s] STATE: %s -> %s" % [name, state_names.get(previous_state, "NONE"), state_names[current_state]])
		_on_state_enter(current_state, previous_state)
		previous_state = current_state
	
	print("[%s] state=%s rotation=%.1f" % [name, state_names[current_state], rad_to_deg(rotation)])

	var scaled_delta: float = delta * _current_time_scale()
	
	if _shoot_cooldown > 0.0:
		_shoot_cooldown -= scaled_delta
		if _shoot_cooldown <= 0.0:
			can_shoot = true
	
	update_debug_color()
	

	if player != null and (current_state == State.IDLE or current_state == State.INVESTIGATE):
		if not player._dying and not player._dead and is_player_in_vision_cone(player):
			dprint("[%s] Player spotted -> ALERT" % name)
			current_state = State.ALERT
			alert_nearby_enemies()
	
	var prev_pos := global_position
	
	match current_state:
		State.IDLE:
			do_idle()
		State.ALERT:
			do_alert(scaled_delta)
		State.CHASE:
			do_chase()
		State.SHOOT:
			do_shoot()
		State.RETURN:
			do_return()
		State.INVESTIGATE:
			do_investigate(scaled_delta)
	
	if current_state == State.IDLE or current_state == State.ALERT or current_state == State.SHOOT:
		global_position = prev_pos
	
	_check_door_collisions()


func do_investigate(delta: float) -> void:
	if not _investigate_scanning:
		var still_pathing := _nav_move(_investigate_pos, speed)
		play_anim("enemy_walk")
		
		if not still_pathing:
			print("[%s] arrival! capturing base_rot=%.1f" % [name, rad_to_deg(rotation)])
			_investigate_scanning = true
			_investigate_base_rotation = rotation
			_investigate_sweep_phase = 0
			_investigate_pause_timer = 0.0
	else:
		velocity = Vector2.ZERO
		_stable_move()
		play_anim("enemy_aim_hold")
		
		var step := INVESTIGATE_SCAN_SPEED * delta
		
		match _investigate_sweep_phase:
			0:
				var target := _investigate_base_rotation - INVESTIGATE_SWEEP_LEFT
				rotation = rotate_toward(rotation, target, step)
				if abs(angle_difference(rotation, target)) < 0.01:
					_investigate_sweep_phase = 1
					_investigate_pause_timer = 0.00
			
			1:
				_investigate_pause_timer += delta
				if _investigate_pause_timer >= INVESTIGATE_PAUSE_DURATION:
					_investigate_sweep_phase = 2
			
			2:
				var target := _investigate_base_rotation + (INVESTIGATE_SWEEP_RIGHT - INVESTIGATE_SWEEP_LEFT)
				rotation = rotate_toward(rotation, target, step)
				if abs(angle_difference(rotation, target)) < 0.01:
					_investigate_sweep_phase = 3
					_investigate_pause_timer = 0.0
			
			3:
				_investigate_pause_timer += delta
				if _investigate_pause_timer >= INVESTIGATE_PAUSE_DURATION:
					dprint("[%s] Done investigating -> RETURN" % name)
					current_state = State.RETURN


func _on_state_enter(new_state, old_state) -> void:
	if new_state == State.CHASE and old_state == State.SHOOT:
		play_anim("enemy_aim_finish")
	

	if new_state == State.IDLE:
		if player == null:
			for body in detection_area.get_overlapping_bodies():
				if body is Player:
					player = body
					dprint("[%s] Re-acquired player on state entry" % name)
					break


# ========================
# COLLISION DETECTION (doors etc)
# ========================
func _check_door_collisions() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider != null and collider.is_in_group("doors"):
			if collider.has_method("is_swinging") and collider.is_swinging():
				dprint("[%s] HIT BY SWINGING DOOR: %s" % [name, collider.name])
				die()
				return



func build_vision_debug():
	var points = PackedVector2Array()
	points.append(Vector2.ZERO)
	
	var segments = 24
	var half = deg_to_rad(vision_angle_deg)
	
	for i in range(segments + 1):

		var angle = PI / 2 + (-half + (2.0 * half * i / segments))
		var p = Vector2(cos(angle), sin(angle)) * vision_range
		points.append(p)
	
	points.append(Vector2.ZERO)
	
	vision_debug.polygon = points
	vision_debug.color = Color(1, 1, 0, 0.2)


func is_player_in_vision_cone(target: Node2D) -> bool:
	var to_player = target.global_position - global_position
	
	if to_player.length() > vision_range:
		return false
	
	var forward = Vector2.DOWN.rotated(rotation)
	var ang = abs(forward.angle_to(to_player))
	if ang > deg_to_rad(vision_angle_deg):
		return false
	
	var space = get_world_2d().direct_space_state
	if space == null:
		return true
	
	var query = PhysicsRayQueryParameters2D.create(global_position, target.global_position)

	query.collision_mask = (1 << 0) | (1 << 2)
	query.exclude = [self]
	
	var result = space.intersect_ray(query)
	if result.is_empty():
		return true
	
	if result.collider == target:
		return true
	
	dprint("[%s] Vision blocked by: %s" % [name, result.collider.name])
	return false


func update_debug_color():
	match current_state:
		State.IDLE:
			vision_light.color = Color(1, 1, 0.6)         
		State.ALERT:
			vision_light.color = Color(1, 0.6, 0.2) 
		State.CHASE:
			vision_light.color = Color(1, 0.3, 0.3) 
		State.SHOOT:
			vision_light.color = Color(1, 0.2, 0.2) 
		State.RETURN:
			vision_light.color = Color(0.3, 0.4, 1)   
		State.INVESTIGATE:
			vision_light.color = Color(0.6, 0.85, 1)  


# ========================
# ANIMATION
# ========================
func play_anim(anim_name: String, force_restart: bool = false):
	if sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(anim_name):
		# Fallback to default if animation doesn't exist
		if sprite.sprite_frames.has_animation("default"):
			anim_name = "default"
		else:
			return

	if force_restart or sprite.animation != anim_name:
		sprite.play(anim_name)


func do_idle():
	velocity = Vector2.ZERO
	_stable_move()
	play_anim("enemy_aim_hold")


func do_alert(delta):
	velocity = Vector2.ZERO
	_stable_move()
	play_anim("enemy_aim_start")
	
	if player != null:
		_face_position(player.global_position)
	
	alert_timer += delta
	if alert_timer >= alert_duration:
		alert_timer = 0.0
		current_state = State.CHASE
		dprint("[%s] Alert done -> CHASE" % name)


func do_chase():

	if player == null or not is_instance_valid(player):
		dprint("[%s] Lost player (null/freed) -> RETURN" % name)
		player = null
		go_return()
		return
	

	
	var dist = global_position.distance_to(player.global_position)
	
	if dist <= shoot_range and is_player_in_vision_cone(player):
		current_state = State.SHOOT
		dprint("[%s] In range and visible -> SHOOT" % name)
		return
	
	_nav_move(player.global_position, speed)
	play_anim("enemy_walk")


func do_shoot():
	if player == null or not is_instance_valid(player):
		dprint("[%s] Lost player (null/freed) -> RETURN" % name)
		player = null
		go_return()
		return
	
	if player._dying or player._dead:
		dprint("[%s] player is dying/dead -> RETURN" % name)
		go_return()
		return

	if not is_player_in_vision_cone(player):
		current_state = State.CHASE
		dprint("[%s] Lost sight -> CHASE" % name)
		return
	
	var dist = global_position.distance_to(player.global_position)
	
	if dist > shoot_range:
		current_state = State.CHASE
		dprint("[%s] Out of range -> CHASE" % name)
		return
	
	_face_position(player.global_position)

	var mid_shoot_anim := sprite.animation == "enemy_shoot" and sprite.is_playing()
	if not mid_shoot_anim:
		play_anim("enemy_aim_hold")
	
	if can_shoot:
		shoot()


func do_return():
	var still_pathing := _nav_move(anchor, speed)
	play_anim("enemy_walk")
	
	if not still_pathing:
		global_position = anchor
		global_rotation = anchor_rotation
		current_state = State.IDLE
		dprint("[%s] Back home -> IDLE" % name)


func go_return():
	current_state = State.RETURN


func alert_nearby_enemies():
	dprint("[%s] ALERTING nearby enemies!" % name)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e != self:
			var dist = global_position.distance_to(e.global_position)
			if dist <= 300.0:
				if e.current_state == State.IDLE:
					e.player = player
					e.current_state = State.ALERT
					dprint("[%s] Alerted %s" % [name, e.name])


func shoot():
	if bullet_scene == null:
		dprint("[%s] ERROR: No bullet scene!" % name)
		return
	
	can_shoot = false
	_shoot_cooldown = fire_rate   
	dprint("[%s] SHOOTING!" % name)
	

	play_anim("enemy_shoot", true)
	
	var bullet = bullet_scene.instantiate()

	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
	
	var dir = (player.global_position - global_position).normalized()
	bullet.setup(dir, self)
	$EnemyShoot.play()


func _on_body_entered(body):
	dprint("[%s] !!! BODY ENTERED: %s | Is Player: %s" % [name, body.name, body is Player])
	
	if body is Player:
		dprint("[%s] >>> PLAYER DETECTED <<<" % name)
		player = body
		
		if is_player_in_vision_cone(body) and not player._dying and not player._dead:
			dprint("[%s] Player in vision cone -> ALERT" % name)
			current_state = State.ALERT
			alert_nearby_enemies()
		else:
			dprint("[%s] Player nearby but NOT in vision cone" % name)


func _on_body_exited(body):
	dprint("[%s] !!! BODY EXITED: %s" % [name, body.name])
	
	if body is Player:
		dprint("[%s] >>> PLAYER LEFT <<<" % name)

		if current_state == State.IDLE:
			player = null


# ========================
# DAMAGE & DEATH
# ========================
func take_damage(amount: float):
	health -= amount
	dprint("[%s] TOOK DAMAGE! Health: %s" % [name, health])
	
	if health <= 0:
		die()


func die():
	dprint("[%s] DESTROYED!" % name)
	
	set_physics_process(false)
	velocity = Vector2.ZERO
	
	play_anim("enemy_dead")
	
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("enemy_dead"):
		await sprite.animation_finished
		await get_tree().create_timer(0.3).timeout
	
	queue_free()
