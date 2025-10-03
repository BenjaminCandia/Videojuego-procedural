extends Area2D

@export var next_scene: String

func _process(delta):
	pass
	

func _on_body_entered(body):
	if body.name == "personaje":
		change_scene()

func change_scene():
	get_tree().change_scene_to_file(next_scene)
