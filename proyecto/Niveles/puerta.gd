extends Area2D

@export var next_scene: String
@onready var hud = get_parent().get_node("/root/Hud")

func _process(delta):
	pass
	
func _on_body_entered(body):
	if body.name == "personaje":
		Global.award_coin()
		hud.update_coins()
		change_scene()

func change_scene():
	get_tree().change_scene_to_file(next_scene)
