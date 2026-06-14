extends Control

@export var npc1_graph: DialogueGraph
@export var npc2_graph: DialogueGraph 

@onready var npc1_button: Button = $CenterContainer/VBoxContainer/TalkToNPC1Button
@onready var npc2_button: Button = $CenterContainer/VBoxContainer/TalkToNPC2Button
@onready var dialogue_box: PanelContainer = $DialogueBox
@onready var line_label: Label = $DialogueBox/MarginContainer/VBoxContainer/LineLabel
@onready var responses_box: VBoxContainer = $DialogueBox/MarginContainer/VBoxContainer/ResponsesBox

var _waiting_for_advance: bool = false

func _ready() -> void:
	dialogue_box.hide()
	npc1_button.pressed.connect(_on_npc1_pressed)
	npc2_button.pressed.connect(_on_npc2_pressed)
	DialogueRunner.say.connect(_on_say)
	DialogueRunner.present_choices.connect(_on_present_choices)
	DialogueRunner.dialogue_ended.connect(_on_dialogue_ended)

func _on_npc1_pressed() -> void:
	_start(npc1_graph)

func _on_npc2_pressed() -> void:
	_start(npc2_graph)

func _start(graph: DialogueGraph) -> void:
	if graph == null or DialogueRunner.is_active():
		return
	_set_buttons_enabled(false)
	DialogueRunner.start(graph)

func _on_say(text: String) -> void:
	line_label.text = text
	_clear_responses()
	dialogue_box.show()
	_waiting_for_advance = true

func _on_present_choices(responses: Array) -> void:
	_waiting_for_advance = false
	_clear_responses()
	for i in responses.size():
		var btn := Button.new()
		btn.text = responses[i].text
		btn.pressed.connect(DialogueRunner.select_response.bind(i))
		responses_box.add_child(btn)
	if responses.size() > 0:
		responses_box.get_child(0).call_deferred("grab_focus")

func _on_dialogue_ended() -> void:
	_waiting_for_advance = false
	dialogue_box.hide()
	_clear_responses()
	_set_buttons_enabled(true)

func _unhandled_input(event: InputEvent) -> void:
	if _waiting_for_advance and event.is_action_pressed("ui_accept"):
		_waiting_for_advance = false
		DialogueRunner.advance()
		get_viewport().set_input_as_handled()

func _set_buttons_enabled(enabled: bool) -> void:
	npc1_button.disabled = not enabled
	npc2_button.disabled = not enabled

func _clear_responses() -> void:
	for child in responses_box.get_children():
		child.queue_free()
