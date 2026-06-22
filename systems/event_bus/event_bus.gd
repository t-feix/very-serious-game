class_name EventBusType
extends Node

signal rewind_started
signal rewind_ended

signal door_lock_changed(door_id: int, is_locked: bool)

signal button_pressed(button_id: int)
