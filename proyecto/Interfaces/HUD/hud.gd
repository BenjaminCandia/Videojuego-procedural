extends CanvasLayer

@onready var coins_label = $Control/Monedas
@onready var time_label = $Control/Cronometro

func _ready():
	# Detecta cambios de escena
	get_tree().connect("scene_changed", Callable(self, "_on_scene_changed"))
	call_deferred("_on_scene_changed", get_tree().current_scene)

func _on_scene_changed(new_scene = null):
	if not new_scene:
		new_scene = get_tree().current_scene
	if not new_scene:
		return

	var name = new_scene.name.to_lower()
	var hide_scenes := ["mainmenu", "gameover", "opciones"]

	if name in hide_scenes:
		visible = false
		Global.stop_timer()
	else:
		visible = true
		Global.start_timer()
		update_coins()

func _process(delta):
	if not visible or not Global.timer_running:
		return

	Global.elapsed_time += delta
	var minutes = int(Global.elapsed_time / 60)
	var seconds = int(Global.elapsed_time) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]

func update_coins():
	if coins_label:
		coins_label.text = str(Global.coins_total)
