extends Node2D

const MAX_STATES := 300

@onready var player = get_parent()
@onready var sprite = %AnimatedSprite2D

signal rewind_started
signal rewind_ended

var buffer: Array[Dictionary] = []


var write_index := 0
var read_index := 0

var size := 0
var rewinding := false



#data model
func record_state():
	var state := {
		"position": player.global_position,
		"rotation": player.rotation,
		"animation": sprite.animation,
		"frame": sprite.frame,
		"frame_progress": sprite.frame_progress,
		"is_playing": sprite.is_playing()
	}

	buffer[write_index] = state
	write_index = (write_index + 1) % MAX_STATES
	size = min(size + 1, MAX_STATES)


#API
func is_rewinding() -> bool:
	return rewinding


func rewind_step() -> void:
	var state = buffer[read_index]
	apply_state(state)
	read_index = (read_index - 1 + MAX_STATES) % MAX_STATES
	size -= 1
	if size == 0:
		stop_rewind()


func stop_rewind() -> void:
	rewinding = false
	emit_signal("rewind_ended")
	sprite.play()


func get_buffer_seconds() -> float:
	return float(size) / Engine.physics_ticks_per_second

func start_rewind() -> void:
	if rewinding or size == 0:
		return
	rewinding = true
	read_index = (write_index - 1 + MAX_STATES) % MAX_STATES
	emit_signal("rewind_started")
	sprite.pause()




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	buffer.resize(MAX_STATES)
	record_state()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		start_rewind()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if rewinding:
		rewind_step()
	else:
		record_state()



func apply_state(state: Dictionary):
	player.global_position = state["position"]
	player.rotation = state["rotation"]
	sprite.animation = state["animation"]
	sprite.set_frame_and_progress(
		state["frame"],
		state["frame_progress"]
	)
	if state["is_playing"]:
		sprite.play()
	else:
		sprite.pause()
