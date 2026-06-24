class_name WallButton
extends Area2D

@export var button_id: int = 0
@export var normal_texture: Texture2D
@export var pressed_texture: Texture2D
@export var press_visual_duration: float = 1.0

@onready var sprite: Sprite2D = $Sprite2D

signal pressed

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if normal_texture:
		sprite.texture = normal_texture

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body._on_button_area_entered(self)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body._on_button_area_exited(self)

func press() -> void:
	pressed.emit()
	EventBus.button_pressed.emit(button_id)
	_flash_pressed_visual()
	$ButtonSound.play()

func _flash_pressed_visual() -> void:
	if pressed_texture:
		sprite.texture = pressed_texture
	await get_tree().create_timer(press_visual_duration).timeout
	if normal_texture:
		sprite.texture = normal_texture
