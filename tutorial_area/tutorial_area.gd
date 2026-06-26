class_name TutorialHint extends Area2D

@export_multiline var hint_text: String = "" :
	set(value):
		hint_text = value
		if is_inside_tree() and hint_label:
			hint_label.text = "Pro tip: " + value

@export var one_shot: bool = false

@onready var hint_label: Label = $HintHUD/LabelContainer/HintLabel
var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	hint_label.text = "Pro tip: " + hint_text
	hint_label.visible = false


func _on_body_entered(body) -> void:
	if not body is Player:
		return
	if one_shot and _triggered:
		return
	_triggered = true
	hint_label.visible = true


func _on_body_exited(body) -> void:
	if not body is Player:
		return
	hint_label.visible = false
