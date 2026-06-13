extends Node

signal say(entity_id: String, line: String)
signal responses_changed(entity_id: String, responses: Array)
signal dialogue_ended(entity_id: String)

var entities: Dictionary = {}
var active_speaker: String = ""

func register_entity(entity_id: String, fsm: Dictionary, initial_state: String) -> void:
	entities[entity_id] = {
		"fsm": fsm,
		"state": initial_state,
		"anchor": initial_state,
	}

func start_dialogue(entity_id: String) -> void:
	print("start_dialogue called for ", entity_id, " known? ", entities.has(entity_id))
	if not entities.has(entity_id):
		push_warning("DialogueManager: unknown entity '%s'" % entity_id)
		return
	active_speaker = entity_id
	_emit_current_state(entity_id)

func select_response(response_index: int) -> void:
	if active_speaker == "":
		return
	var data = entities[active_speaker]
	var current = data.fsm[data.state]
	if response_index < 0 or response_index >= current.responses.size():
		return
	var response = current.responses[response_index]
	# Apply state transitions
	for target_id in response.transitions:
		if entities.has(target_id):
			entities[target_id].state = response.transitions[target_id]

	if response.has("set_anchor"):
		for target_id in response.set_anchor:
			if entities.has(target_id):
				entities[target_id].anchor = response.set_anchor[target_id]
	_emit_current_state(active_speaker)

func reset_dialogue(entity_id: String) -> void:
	if not entities.has(entity_id):
		return
	entities[entity_id].state = entities[entity_id].anchor
	if active_speaker == entity_id:
		active_speaker = ""
		dialogue_ended.emit(entity_id)

func _emit_current_state(entity_id: String) -> void:
	var data = entities[entity_id]
	var state = data.fsm[data.state]
	say.emit(entity_id, state.line)
	responses_changed.emit(entity_id, state.responses)
	if state.responses.is_empty():
		dialogue_ended.emit(entity_id)
		active_speaker = ""
