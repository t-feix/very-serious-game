extends Node

# what the NPC says
signal say(text: String)
# what the player can answer
signal present_choices(choices: Array)
# dialogue ended, collaps UI
signal dialogue_ended

var _current_line: LineNode = null
var _current_choice: ChoiceNode = null

func start(graph: DialogueGraph) -> void:
	if graph == null or graph.start == null:
		push_warning("DialogueRunner: Empty Graph")
		return
	_enter(graph.start)

func advance() -> void:
	if _current_line == null:
		return
	var line := _current_line
	_current_line = null
	_enter(line.next)

func select_response(index: int) -> void:
	if _current_choice == null:
		return
	if index < 0 or index >= _current_choice.responses.size():
		return
	
	var response := _current_choice.responses[index]
	_current_choice = null
	_enter(response)

func _enter(node: DialogueNode) -> void:
	if node == null:
		_end()
		return
	
	if node is LineNode:
		_current_line = node
		say.emit(node.text)
		if node.next is ChoiceNode:
			_current_line = null
			_enter(node.next)
	
	elif node is ChoiceNode:
		_current_choice = node
		present_choices.emit(node.responses)
	
	elif node is ResponseNode:
		_enter(node.next)
	
	elif node is GateNode:
		var open: bool = Flags.get_flag(node.flag)
		_enter(node.on_true if open else node.on_false)
	
	elif node is EndNode:
		for f in node.set_flags:
			Flags.set_flag(f, true)
		_end()

func is_active() -> bool:
	return _current_line != null or _current_choice != null

func _end() -> void:
	_current_line = null
	_current_choice = null
	dialogue_ended.emit()
