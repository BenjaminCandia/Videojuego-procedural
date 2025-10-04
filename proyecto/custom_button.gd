extends Button
class_name CustomButton

@onready var click: AudioStreamPlayer = $Click
@onready var on_hover: AudioStreamPlayer = $OnHover

func _ready() -> void:
	self.connect("pressed", Callable(self, "_on_pressed"))
	self.connect("mouse_entered", Callable(self, "_on_mouse_entered"))

# Funcionalidad para cuando el botón sea presionado 
func _on_pressed() -> void:
	if click and click.stream:
		click.play()

# Funcionalidad para cuando el mouse haga contacto con el botón
func _on_mouse_entered() -> void:
	if on_hover and on_hover.stream:
		on_hover.play()
