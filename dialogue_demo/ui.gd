extends CanvasLayer

@onready var dialogue_box: PanelContainer = $DialogueBox
@onready var speaker_label: Label = $DialogueBox/MarginContainer/VBoxContainer/SpeakerLabel
@onready var line_label: Label = $DialogueBox/MarginContainer/VBoxContainer/LineLabel
@onready var responses_box: VBoxContainer = $DialogueBox/MarginContainer/VBoxContainer/ResponsesBox

func _ready() -> void:
	dialogue_box.hide()
	DialogueManager.say.connect(_on_say)
	DialogueManager.responses_changed.connect(_on_responses_changed)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _on_say(entity_id: String, line: String) -> void:
	speaker_label.text = entity_id
	line_label.text = line
	dialogue_box.show()

func _on_responses_changed(_entity_id: String, responses: Array) -> void:

	for child in responses_box.get_children():
		child.queue_free()
	# Build new buttons
	for i in responses.size():
		var btn := Button.new()
		btn.text = responses[i].text
		btn.pressed.connect(DialogueManager.select_response.bind(i))
		responses_box.add_child(btn)

	if responses.size() > 0:
		responses_box.get_child(0).call_deferred("grab_focus")

func _on_dialogue_ended(_entity_id: String) -> void:
	dialogue_box.hide()
