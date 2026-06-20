extends CharacterBody2D

#  STATES 
enum State {IDLE, ALERT, CHASE, SHOOT}
var current_state = State.IDLE

#  STATS 
@export var speed: float = 100.0
@export var shoot_range: float = 200.0
@export var alert_radius: float = 300.0
@export var fire_rate: float = 1.5

#  BULLET 
@export var bullet_scene: PackedScene

#  INTERNAL 
var player: Player = null
var can_shoot = true
var alert_timer = 0.0
var alert_duration = 1.5

#  NODES 
@onready var detection_area = $DetectionArea
@onready var sprite = $Sprite2D

func _ready():
	# Connect detection signals
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _physics_process(delta):
	match current_state:
		State.IDLE:
			handle_idle()
		State.ALERT:
			handle_alert(delta)
		State.CHASE:
			handle_chase()
		State.SHOOT:
			handle_shoot()

#  STATE HANDLERS 
func handle_idle():
	velocity = Vector2.ZERO
	move_and_slide()

func handle_alert(delta):
	velocity = Vector2.ZERO
	move_and_slide()
	
	# Count alert timer
	alert_timer += delta
	if alert_timer >= alert_duration:
		alert_timer = 0.0
		current_state = State.CHASE

func handle_chase():
	if player == null:
		current_state = State.IDLE
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	# If in shoot range switch to shoot
	if distance <= shoot_range:
		current_state = State.SHOOT
		return
	
	# Move toward player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	# Rotate to face player
	look_at(player.global_position)

func handle_shoot():
	if player == null:
		current_state = State.IDLE
		return
		
	var distance = global_position.distance_to(player.global_position)
	
	# If player too far go back to chase
	if distance > shoot_range:
		current_state = State.CHASE
		return
	
	# Always face player
	look_at(player.global_position)
	
	# Shoot if can
	if can_shoot:
		shoot()

#  ALERT NEARBY ENEMIES 
func alert_nearby_enemies():
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = alert_radius
	query.shape = shape
	query.transform = global_transform
	query.collision_mask = 1
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var body = result["collider"]
		if body.is_in_group("enemies") and body != self:
			if body.current_state == State.IDLE:
				body.current_state = State.ALERT
				body.player = player

#  SHOOT 
func shoot():
	if bullet_scene == null:
		print("No bullet scene assigned!")
		return
		
	can_shoot = false
	
	# Create bullet
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	
	# Set bullet position and direction
	bullet.global_position = global_position
	var shoot_direction = (player.global_position - global_position).normalized()
	bullet.setup(shoot_direction)
	
	# Wait then shoot again
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

#  DETECTION SIGNALS 
func _on_body_entered(body):
	if body is Player:
		player = body
		current_state = State.ALERT
		alert_nearby_enemies()

func _on_body_exited(body):
	if body is Player:
		player = null
		current_state = State.IDLE
