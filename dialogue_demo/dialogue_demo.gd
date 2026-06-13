extends Node2D

@onready var dialogue_label: Label = $UI/TalkHint

const NPC1_FSM = {
	"greet_locked": {
		"line": "Hello there!",
		"responses": [
			{"text": "What color is the sky?", "transitions": {"npc1": "sky_locked"}},
			{"text": "Can you tell me a secret?", "transitions": {"npc1": "secret_locked"}},
		]
	},
	"greet_unlocked": {
		"line": "Hello there!",
		"responses": [
			{"text": "What color is the sky?", "transitions": {"npc1": "sky_unlocked"}},
			{"text": "Can you tell me a secret?", "transitions": {"npc1": "secret_unlocked"}},
		]
	},
	"sky_locked": {
		"line": "Uh... blue.",
		"responses": [
			{"text": "Back", "transitions": {"npc1": "greet_locked"}},
		]
	},
	"sky_unlocked": {
		"line": "Uh... blue.",
		"responses": [
			{"text": "Back", "transitions": {"npc1": "greet_unlocked"}},
		]
	},
	"secret_locked": {
		"line": "You'll have to talk to NPC2 for that...",
		"responses": [
			{"text": "Back", "transitions": {"npc1": "greet_locked"}},
		]
	},
	"secret_unlocked": {
		"line": "Here's the secret: the sky is actually red!",
		"responses": [
			{"text": "Whoa.", "transitions": {"npc1": "greet_unlocked"}},
		]
	},
}

const NPC2_FSM = {
	"greet": {
		"line": "Wazzup!",
		"responses": [
			{"text": "What is your favorite hobby?", "transitions": {"npc2": "hobby"}},
			{
	"text": "NPC1 knows a secret, but he won't tell me.",
	"transitions": {"npc2": "unlock", "npc1": "greet_unlocked"},
	"set_anchor": {"npc1": "greet_unlocked"}
},
		]
	},
	"hobby": {
		"line": "It's basketball.",
		"responses": [
			{"text": "Back", "transitions": {"npc2": "greet"}},
		]
	},
	"unlock": {
		"line": "Now that you've talked to me, NPC1 will tell you.",
		"responses": [
			{"text": "Thanks.", "transitions": {"npc2": "greet"}},
		]
	},
}

func _ready() -> void:
	DialogueManager.register_entity("npc1", NPC1_FSM, "greet_locked")
	DialogueManager.register_entity("npc2", NPC2_FSM, "greet")
	dialogue_label.hide()
	for npc in get_tree().get_nodes_in_group("npc"):
		npc.dialogue_hint.connect(_on_dialogue_hint)
		npc.dialogue_hint_ended.connect(_on_dialogue_hint_ended)

func _on_dialogue_hint() -> void:
	dialogue_label.show()

func _on_dialogue_hint_ended() -> void:
	dialogue_label.hide()
