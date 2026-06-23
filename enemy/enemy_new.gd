extends CharacterBody2D

# --- STATES ---
enum State {IDLE, PATROL, PATROL_WAIT, ALERT, CHASE, SHOOT, RETURN}
var current_state = State.IDLE
var previous_state = -1

# --- STATS ---
@export var speed: float = 100.0
@export var shoot_range: float = 200.0
@export var fire_rate: float = 1.5
@export var health: float = 1.0  # Dies in 1 hit

# --- PATROL ---
@export var is_patrolling: bool = true
@export var patrol_offset_a: Vector2 = Vector2(100, 0)
@export var patrol_offset_b: Vector2 = Vector2(-100, 0)
@export var patrol_delay: float = 2.0

# --- VISION ---
@export var vision_range: float = 250.0
@export var vision_angle_deg: float = 45.0

# --- PURSUIT ---
@export var max_pursuit_distance: float = 500.0

# --- BULLET ---
@export var bullet_scene: PackedScene

# --- DEBUG ---
@export var debug_enabled: bool = true

# --- INTERNAL ---
var anchor: Vector2
var point_a: Vector2
var point_b: Vector2
var patrol_target: Vector2
var player: Player = null
var can_shoot: bool = true
var alert_timer: float = 0.0
var alert_duration: float = 1.0

var state_names = {
	State.IDLE: "IDLE",
	State.PATROL: "PATROL",
	State.PATROL_WAIT: "PATROL_WAIT",
	State.ALERT: "ALERT",
	State.CHASE: "CHASE",
	State.SHOOT: "SHOOT",
	State.RETURN: "RETURN"
}

# --- NODES ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area = $DetectionArea
@onready var vision_debug = $VisionConeDebug
@onready var patrol_timer = $PatrolTimer
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	print("==============================================")
	print("!!! NEW SCRIPT LOADED !!!")
	print("!!! SCRIPT PATH: %s" % get_script().resource_path)
	print("!!! NODE NAME: %s" % name)
	print("!!! CHILDREN:")
	for child in get_children():
		print("  -> %s | %s" % [child.name, child.get_class()])
	print("==============================================")
	
	# Save anchor position
	anchor = global_position
	
	# Calculate patrol points from offsets
	point_a = anchor + patrol_offset_a
	point_b = anchor + patrol_offset_b
	
	# Build vision cone visual
	build_vision_debug()
	
	# Connect signals
	print("[%s] Connecting signals..." % name)
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	patrol_timer.timeout.connect(_on_patrol_timeout)
	print("[%s] Signals connected!" % name)
	
	# Start patrol or idle
	if is_patrolling:
		patrol_target = point_a
		current_state = State.PATROL
	else:
		current_state = State.IDLE
	
	print("[%s] READY | Anchor: %s | Patrolling: %s" % [name, anchor, is_patrolling])
	print("[%s] Patrol A: %s | B: %s" % [name, point_a, point_b])
	print("[%s] DetectionArea monitoring: %s" % [name, detection_area.monitoring])
	print("[%s] DetectionArea mask: %s" % [name, detection_area.collision_mask])
	
		# DEBUG: Check animations
	print("[%s] === ANIMATION CHECK ===" % name)
	if sprite.sprite_frames == null:
		print("[%s] !!! NO SPRITE FRAMES !!!" % name)
	else:
		var anims = sprite.sprite_frames.get_animation_names()
		print("[%s] Available animations: %s" % [name, anims])
		for a in anims:
			var count = sprite.sprite_frames.get_frame_count(a)
			print("[%s]   -> '%s' has %s frames" % [name, a, count])
	# Wait then check for player
	await get_tree().process_frame
	await get_tree().process_frame
	
	var found_player = false
	for node in get_tree().root.get_children():
		for child in node.get_children():
			if child is Player or child.name == "Player":
				print("[%s] FOUND PLAYER: %s | Layer: %s" % [name, child.name, child.collision_layer])
				found_player = true
	
	if not found_player:
		print("[%s] !!! WARNING: NO PLAYER FOUND !!!" % name)
	
	print("[%s] Players in group 'player': %s" % [name, get_tree().get_nodes_in_group("player").size()])

func _physics_process(delta):
	if current_state != previous_state:
		print("[%s] STATE: %s -> %s" % [name, state_names.get(previous_state, "NONE"), state_names[current_state]])
		previous_state = current_state
	
	update_debug_color()
	
	# CONTINUOUS VISION CHECK
	# If player is in detection area but we're still patrolling/idle
	# keep checking if they enter the vision cone
	if player != null and (current_state == State.IDLE or current_state == State.PATROL or current_state == State.PATROL_WAIT):
		if is_player_in_vision_cone(player):
			print("[%s] Player entered vision cone -> ALERT" % name)
			current_state = State.ALERT
			alert_nearby_enemies()
	
	match current_state:
		State.IDLE:
			do_idle()
		State.PATROL:
			do_patrol()
		State.PATROL_WAIT:
			do_patrol_wait()
		State.ALERT:
			do_alert(delta)
		State.CHASE:
			do_chase()
		State.SHOOT:
			do_shoot()
		State.RETURN:
			do_return()

# ========================
# COLLISION DETECTION (for doors etc)
# ========================
func _physics_process_collisions():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Only check for doors (navigation handles walls)
		if collider != null and collider.is_in_group("doors"):
			print("[%s] HIT BY DOOR: %s" % [name, collider.name])
			die()
			return

func build_vision_debug():
	var points = PackedVector2Array()
	points.append(Vector2.ZERO)
	
	var segments = 24
	var half = deg_to_rad(vision_angle_deg)
	
	for i in range(segments + 1):
		var angle = -half + (2.0 * half * i / segments)
		var p = Vector2(cos(angle), sin(angle)) * vision_range
		points.append(p)
	
	points.append(Vector2.ZERO)
	
	vision_debug.polygon = points
	vision_debug.color = Color(1, 1, 0, 0.2)

func is_player_in_vision_cone(target: Node2D) -> bool:
	var to_player = target.global_position - global_position
	
	if to_player.length() > vision_range:
		return false
	
	var forward = Vector2.RIGHT.rotated(rotation)
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
	else:
		print("[%s] Vision blocked by: %s" % [name, result.collider.name])
		return false

func update_debug_color():
	match current_state:
		State.IDLE, State.PATROL, State.PATROL_WAIT:
			vision_debug.color = Color(1, 1, 0, 0.2)
		State.ALERT:
			vision_debug.color = Color(1, 0.5, 0, 0.3)
		State.CHASE:
			vision_debug.color = Color(1, 0, 0, 0.3)
		State.SHOOT:
			vision_debug.color = Color(1, 0, 0, 0.5)
		State.RETURN:
			vision_debug.color = Color(0, 0, 1, 0.2)

# ========================
# ANIMATION
# ========================
func play_anim(anim_name: String):
	if sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(anim_name):
		# Fallback to default if animation doesn't exist
		if sprite.sprite_frames.has_animation("default"):
			anim_name = "default"
		else:
			return
	if sprite.animation != anim_name:
		sprite.play(anim_name)
		
# ========================
# NAVIGATION
# ========================
func navigate_to(target_pos: Vector2):
	nav_agent.target_position = target_pos

func get_next_nav_position() -> Vector2:
	return nav_agent.get_next_path_position()

func is_navigation_finished() -> bool:
	return nav_agent.is_navigation_finished()

func move_toward_nav_target():
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return
	
	var next_pos = nav_agent.get_next_path_position()
	var dir = (next_pos - global_position).normalized()
	velocity = dir * speed
	
	if dir.length() > 0.1:
		rotation = dir.angle()

func do_idle():
	velocity = Vector2.ZERO
	move_and_slide()
	play_anim("Enemy aim_hold")

func do_patrol():
	# Set navigation target
	navigate_to(patrol_target)
	
	# Move using navigation
	move_toward_nav_target()
	move_and_slide()
	play_anim("Enemy walk")
	
	# Reached target?
	if global_position.distance_to(patrol_target) < 15.0:
		velocity = Vector2.ZERO
		current_state = State.PATROL_WAIT
		patrol_timer.wait_time = patrol_delay
		patrol_timer.start()
		print("[%s] Reached patrol point, waiting %.1fs" % [name, patrol_delay])
		return

func do_patrol_wait():
	velocity = Vector2.ZERO
	move_and_slide()
	play_anim("Enemy aim_hold")
	
func flip_patrol_target():
	if patrol_target == point_a:
		patrol_target = point_b
	else:
		patrol_target = point_a
func do_alert(delta):
	velocity = Vector2.ZERO
	move_and_slide()
	play_anim("Enemy aim_start")
	
	if player != null:
		look_at(player.global_position)
	
	alert_timer += delta
	if alert_timer >= alert_duration:
		alert_timer = 0.0
		current_state = State.CHASE
		print("[%s] Alert done -> CHASE" % name)

func do_chase():
	if player == null:
		print("[%s] Lost player -> RETURN" % name)
		go_return()
		return
	
	if global_position.distance_to(anchor) > max_pursuit_distance:
		print("[%s] Too far from anchor -> RETURN" % name)
		player = null
		go_return()
		return
	
	if not is_player_in_vision_cone(player):
		print("[%s] Lost sight -> RETURN" % name)
		player = null
		go_return()
		return
	
	var dist = global_position.distance_to(player.global_position)
	
	if dist <= shoot_range:
		current_state = State.SHOOT
		print("[%s] In range -> SHOOT" % name)
		return
	
	# Navigate toward player
	navigate_to(player.global_position)
	move_toward_nav_target()
	move_and_slide()
	
	# Face movement direction but look toward player when close
	if dist < shoot_range * 2:
		look_at(player.global_position)
	
	play_anim("Enemy walk")

func do_shoot():
	if player == null:
		print("[%s] Lost player -> RETURN" % name)
		go_return()
		return
	
	if global_position.distance_to(anchor) > max_pursuit_distance:
		print("[%s] Too far from anchor -> RETURN" % name)
		player = null
		go_return()
		return
	
	if not is_player_in_vision_cone(player):
		print("[%s] Lost sight -> RETURN" % name)
		player = null
		go_return()
		return
	
	var dist = global_position.distance_to(player.global_position)
	
	if dist > shoot_range:
		current_state = State.CHASE
		print("[%s] Out of range -> CHASE" % name)
		return
	
	look_at(player.global_position)
	play_anim("Enemy aim_hold")
	
	if can_shoot:
		shoot()

func do_return():
	var dist = global_position.distance_to(anchor)
	
	if dist < 15.0:
		velocity = Vector2.ZERO
		global_position = anchor
		
		if is_patrolling:
			patrol_target = point_a
			current_state = State.PATROL
			print("[%s] Back home -> PATROL" % name)
		else:
			current_state = State.IDLE
			print("[%s] Back home -> IDLE" % name)
		return
	
	# Navigate back to anchor
	navigate_to(anchor)
	move_toward_nav_target()
	move_and_slide()
	play_anim("Enemy walk")

func go_return():
	current_state = State.RETURN

func alert_nearby_enemies():
	print("[%s] ALERTING nearby enemies!" % name)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e != self:
			var dist = global_position.distance_to(e.global_position)
			if dist <= 300.0:
				if e.current_state == State.IDLE or e.current_state == State.PATROL or e.current_state == State.PATROL_WAIT:
					e.player = player
					e.current_state = State.ALERT
					print("[%s] Alerted %s" % [name, e.name])

func shoot():
	if bullet_scene == null:
		print("[%s] ERROR: No bullet scene!" % name)
		return
	
	can_shoot = false
	print("[%s] SHOOTING!" % name)
	
	# Play aim_shoot then shot_front
	play_anim("Enemy aim_shoot")
	await get_tree().create_timer(0.2).timeout
	
	if not is_inside_tree() or player == null:
		can_shoot = true
		return
	
	play_anim("Enemy shot_front")
	
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_position = global_position
	
	var dir = (player.global_position - global_position).normalized()
	bullet.setup(dir, self)
	
	await get_tree().create_timer(fire_rate).timeout
	if is_inside_tree():
		can_shoot = true

func _on_body_entered(body):
	print("[%s] !!! BODY ENTERED: %s | Is Player: %s" % [name, body.name, body is Player])
	
	if body is Player:
		print("[%s] >>> PLAYER DETECTED <<<" % name)
		player = body
		
		if is_player_in_vision_cone(body):
			print("[%s] Player in vision cone -> ALERT" % name)
			current_state = State.ALERT
			alert_nearby_enemies()
		else:
			print("[%s] Player nearby but NOT in vision cone" % name)

func _on_body_exited(body):
	print("[%s] !!! BODY EXITED: %s" % [name, body.name])
	
	if body is Player:
		print("[%s] >>> PLAYER LEFT <<<" % name)
		if current_state == State.IDLE or current_state == State.PATROL or current_state == State.PATROL_WAIT:
			player = null

func _on_patrol_timeout():
	flip_patrol_target()
	current_state = State.PATROL
	print("[%s] Patrol timer done -> moving to %s" % [name, patrol_target])

# ========================
# DAMAGE & DEATH
# ========================
func take_damage(amount: float):
	health -= amount
	print("[%s] TOOK DAMAGE! Health: %s" % [name, health])
	
	if health <= 0:
		die()

func die():
	print("[%s] DESTROYED!" % name)
	
	set_physics_process(false)
	velocity = Vector2.ZERO
	
	play_anim("Enemy Dead")
	
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("Enemy Dead"):
		await sprite.animation_finished
		await get_tree().create_timer(0.3).timeout
	
	queue_free()
