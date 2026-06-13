extends Area2D

signal dialogue_hint
signal dialogue_hint_ended
@export var npc_name: String = "Unnamed"
@export var npc_color: Color = Color("#1dffd1")

@onready var polygon: Polygon2D = $Polygon2D

var player_nearby: bool = false

func _ready() -> void:
	polygon.color = npc_color
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	print("body_entered: ", body.name, " in group player? ", body.is_in_group("player"))
	if body.is_in_group("player"):
		dialogue_hint.emit()
		player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		dialogue_hint_ended.emit()
		player_nearby = false
		DialogueManager.reset_dialogue(npc_name)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		print("space pressed, nearby=", player_nearby, " entity=", npc_name)
	if not player_nearby:
		return
	if event.is_action_pressed("ui_accept"):
		DialogueManager.start_dialogue(npc_name)
