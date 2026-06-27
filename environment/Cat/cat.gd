class_name Cat extends Area2D

@export_file("*.tscn") var ending_scene: String = "res://world/Cutscenes/EndingCutscene/ending_cutscene.tscn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body) -> void:
	if body is Player:
		body.register_nearby_cat(self)


func _on_body_exited(body) -> void:
	if body is Player:
		body.unregister_nearby_cat(self)


func interact_with(player: Player) -> void:
	monitoring = false
	
	$AnimatedSprite2D.play("Cat_empty")
	
	#GameState.reset_level_state()
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file(ending_scene)
