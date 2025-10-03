extends Button
class_name CustomButton

@onready var click: AudioStreamPlayer = $Click
@onready var onhover: AudioStreamPlayer = $OnHover

#Funcionalidad para cuando el boton sea presionado 
func _on_pressed() -> void:
	click.play()

#Funcionalidad para cuando el mouse haga contacto con el boton
func _on_mouse_entered() -> void:
	onhover.play()
