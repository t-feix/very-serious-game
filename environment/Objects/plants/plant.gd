extends StaticBody2D
@export var plant_sprite: Texture2D
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.texture = plant_sprite
