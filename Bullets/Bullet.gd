extends Area2D

# --- STATS ---
@export var speed: float = 2000.0
@export var damage: float = 1.0
@export var lifetime: float = 3.0

# --- REWIND ---
@export var rewind_time_scale: float = 0.1 

# --- INTERNAL ---
var direction = Vector2.ZERO
var shooter = null 
var _is_rewinding: bool = false
var _life_remaining: float = 0.0

# --- NODES ---
@onready var visible_notifier = $VisibleOnScreenNotifier2D


func _current_time_scale() -> float:
	return rewind_time_scale if _is_rewinding else 1.0


func _on_rewind_started() -> void:
	_is_rewinding = true


func _on_rewind_ended() -> void:
	_is_rewinding = false


func _ready():
	# Connect signals
	visible_notifier.screen_exited.connect(_on_screen_exited)
	body_entered.connect(_on_body_entered)
	EventBus.rewind_started.connect(_on_rewind_started)
	EventBus.rewind_ended.connect(_on_rewind_ended)
	

	if EventBus.is_rewinding:
		_is_rewinding = true
	

	_life_remaining = lifetime


func _physics_process(delta):
	var scaled_delta: float = delta * _current_time_scale()
	
	global_position += direction * speed * _current_time_scale() * delta
	
	_life_remaining -= scaled_delta
	if _life_remaining <= 0.0:
		queue_free()


func setup(shoot_direction: Vector2, who_shot = null):
	direction = shoot_direction.normalized()
	rotation = direction.angle()
	shooter = who_shot


func _on_screen_exited():
	queue_free()


func _on_body_entered(body):
	if body == shooter:
		return
	
	if body is Player:
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
		return
	
	if body.is_in_group("enemies"):
		print("Enemy %s hit by bullet!" % body.name)
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
		return
	
	if body.is_in_group("doors"):
		print("Bullet hit door!")
		queue_free()
		return
	
	print("Bullet hit: %s" % body.name)
	queue_free()
