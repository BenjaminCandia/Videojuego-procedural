extends CanvasLayer

var mejoras = {
	"economica": [
		{"nombre": "Overlock", "descripción": "Mayor aceleración", "precio": 5},
		{"nombre": "Nanoescudo", "descripción": "Protección básica", "precio": 7},
	],
	"media": [
		{"nombre": "Clarividencia", "descripción": "Muestra parte de la solución por 15 segundos", "precio": 15},
		{"nombre": "Sensor", "descripción": "Permite ver una parte de la solución", "precio": 20},
	],
	"alta": [
		{"nombre": "Ráfaga", "descripción": "No disponible", "precio": 40},
		{"nombre": "Nanoescudo avanzado", "descripción": "No disponible", "precio": 50},
	]
}

var tipo_actual: String

func _ready():
	visible = false  # Oculta la tienda al inicio

func mostrar_tienda():
	# Limpia productos anteriores
	for child in $Panel/VBoxContainer.get_children():
		child.queue_free()
		
	visible = true

	# Determina el tipo según las monedas actuales
	tipo_actual = Global.obtener_tipo_tienda()
	$Panel/Label.text = "Tienda " + tipo_actual.capitalize()

	# Crea botones para las mejoras del tipo actual
	for mejora in mejoras[tipo_actual]:
		var boton = Button.new()
		boton.text = "%s - %d monedas" % [mejora["nombre"], mejora["precio"]]
		boton.pressed.connect(func(): comprar(mejora))
		$Panel/VBoxContainer.add_child(boton)

	# Botón para cerrar la tienda
	var cerrar = Button.new()
	cerrar.text = "Cerrar"
	cerrar.pressed.connect(func(): ocultar_tienda())
	$Panel/VBoxContainer.add_child(cerrar)

func ocultar_tienda():
	visible = false

func comprar(mejora):
	if Global.gastar_monedas(mejora["precio"]):
		print("Compraste:", mejora["nombre"])
	else:
		print("No tienes suficientes monedas")
