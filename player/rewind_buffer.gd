
extends Node2D

const MAX_STATES := 300

@onready var player = get_parent()
@onready var sprite = %AnimatedSprite2D

signal rewind_started
signal rewind_ended

var buffer: Array[Dictionary] = []


var write_index := 0
var read_index := 0

var dying: bool = false
var _death_anchor: int = -1

var size := 0
var rewinding := false

func enter_dying() -> void:
	dying = true
	_death_anchor = write_index


func exit_dying() -> void:
	dying = false
	_death_anchor = -1


func is_read_before_death() -> bool:
	if not dying or not rewinding:
		return false
	var distance := (_death_anchor - read_index + MAX_STATES) % MAX_STATES
	return distance > 0

func record_state():
	if dying:
		write_index = (write_index + 1) % MAX_STATES
		if size > 0:
			size -= 1
		return
		
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


func is_rewinding() -> bool:
	return rewinding



func rewind_step() -> void:
	var state = buffer[read_index]
	apply_state(state)
	read_index = (read_index - 1 + MAX_STATES) % MAX_STATES
	size -= 1
	if size == 0:
		stop_rewind()

func clear() -> void:
	if rewinding:
		stop_rewind()
	buffer.clear()
	buffer.resize(MAX_STATES)
	write_index = 0
	read_index = 0
	size = 0
	
	dying = false
	_death_anchor = -1

func stop_rewind() -> void:
	if not rewinding:
		return
	rewinding = false
	write_index = (read_index + 1) % MAX_STATES
	emit_signal("rewind_ended")
	EventBus.rewind_ended.emit()
	EventBus.is_rewinding = false
	sprite.play()
	$RewindSound.stop()


func get_buffer_seconds() -> float:
	return float(size) / Engine.physics_ticks_per_second

func start_rewind() -> void:
	if rewinding:
		return
	if size == 0:
		return
	
	if dying:
		read_index = (_death_anchor - 1 + MAX_STATES) % MAX_STATES
	else:
		read_index = (write_index - 1 + MAX_STATES) % MAX_STATES
	
	rewinding = true
	emit_signal("rewind_started")
	EventBus.rewind_started.emit()
	$RewindSound.play()
	sprite.pause()




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	buffer.resize(MAX_STATES)
	record_state()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		start_rewind()
  
	elif event.is_action_released("ui_accept"):
		stop_rewind()


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
