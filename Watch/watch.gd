extends CanvasLayer

@onready var rewind_buffer: Node = %RewindBuffer
@onready var anchor: Control = $Anchor
@onready var watch_handle: Sprite2D = $Anchor/Watch/WatchHandle

const FULL_THRESHOLD := 0.99 
const FADE_DURATION := 0.3

var _visible_state: bool = true
var _fade_tween: Tween


func _ready() -> void:
	anchor.modulate.a = 1.0

	var should_show := _get_fill_ratio() < FULL_THRESHOLD
	_visible_state = should_show
	anchor.modulate.a = 1.0 if should_show else 0.0


func _process(_delta: float) -> void:
	var fill_ratio := _get_fill_ratio()
	
	watch_handle.rotation = fill_ratio * TAU
	

	var should_show := fill_ratio < FULL_THRESHOLD
	if should_show != _visible_state:
		_set_visible(should_show)


func _get_fill_ratio() -> float:
	return float(rewind_buffer.size) / float(rewind_buffer.MAX_STATES)


func _set_visible(visible: bool) -> void:
	_visible_state = visible
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	var target_alpha := 1.0 if visible else 0.0
	_fade_tween.tween_property(anchor, "modulate:a", target_alpha, FADE_DURATION)
