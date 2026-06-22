extends Area2D

# --- STATS ---
@export var speed: float = 400.0
@export var damage: float = 1.0
@export var lifetime: float = 3.0

# --- INTERNAL ---
var direction = Vector2.ZERO
var shooter = null  # Who shot this bullet

# --- NODES ---
@onready var visible_notifier = $VisibleOnScreenNotifier2D

func _ready():
	# Connect signals
	visible_notifier.screen_exited.connect(_on_screen_exited)
	body_entered.connect(_on_body_entered)
	
	# Auto delete after lifetime
	await get_tree().create_timer(lifetime).timeout
	if is_inside_tree():
		queue_free()

func _physics_process(delta):
	global_position += direction * speed * delta

func setup(shoot_direction: Vector2, who_shot = null):
	direction = shoot_direction.normalized()
	rotation = direction.angle()
	shooter = who_shot

func _on_screen_exited():
	queue_free()

func _on_body_entered(body):
	# Don't hit the one who shot us
	if body == shooter:
		return
	
	# Hit player
	if body is Player:
		print("Player Hit!")
		queue_free()
		return
	
	# Hit enemy
	if body.is_in_group("enemies"):
		print("Enemy %s hit by bullet!" % body.name)
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
		return
	
	# Hit door - just destroy bullet
	if body.is_in_group("doors"):
		print("Bullet hit door!")
		queue_free()
		return
	
	# Hit wall or anything else
	print("Bullet hit: %s" % body.name)
	queue_free()
