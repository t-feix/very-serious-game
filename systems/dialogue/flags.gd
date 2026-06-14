extends Node

var flags: Dictionary = {}
func get_flag(key: String) -> bool:
	return flags.get(key, false)

func set_flag(key: String, value: bool) -> void:
	flags[key] = value
