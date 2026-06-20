extends Area2D

#  STATS 
@export var speed: float = 400.0
@export var damage: float = 10.0
@export var lifetime: float = 3.0

#  INTERNAL 
var direction = Vector2.ZERO

#  NODES 
@onready var visible_notifier = $VisibleOnScreenNotifier2D

func _ready():
	# Connect signals
	visible_notifier.screen_exited.connect(_on_screen_exited)
	body_entered.connect(_on_body_entered)
	
	# Auto delete after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	# Move bullet forward
	global_position += direction * speed * delta

#  SET DIRECTION 
func setup(shoot_direction: Vector2):
	direction = shoot_direction.normalized()
	# Rotate bullet to face direction
	rotation = direction.angle()

#  SIGNALS 
func _on_screen_exited():
	# Delete when off screen
	queue_free()

func _on_body_entered(body):
	if body.name == "Player":
		# Hit player
		print("Player Hit!")
		queue_free()
