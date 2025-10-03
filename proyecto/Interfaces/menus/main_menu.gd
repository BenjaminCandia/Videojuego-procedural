extends Control
class_name MainMenu

func _on_start_game_pressed() -> void:
	get_tree().change_scene_to_file("res://Niveles/nivel_1.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
