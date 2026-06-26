extends CanvasLayer

@onready var rewind_buffer: Node = %RewindBuffer
@onready var rewind_overlay: ColorRect = $RewindOverlay

func _ready() -> void:
	rewind_buffer.rewind_started.connect(_on_rewind_started)
	rewind_buffer.rewind_ended.connect(_on_rewind_ended)
	rewind_overlay.modulate.a = 0.0

func _on_rewind_started() -> void:
	var tween := create_tween()
	tween.tween_property(rewind_overlay, "modulate:a", 1.0, 0.12)

func _on_rewind_ended() -> void:
	var tween := create_tween()
	tween.tween_property(rewind_overlay, "modulate:a", 0.0, 0.25)
