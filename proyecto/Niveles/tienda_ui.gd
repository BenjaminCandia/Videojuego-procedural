extends CanvasLayer

@onready var productos_container = $Panel/VBoxContainer/HBoxContainer
@onready var layout = $Panel/VBoxContainer

var mejoras = {
	"economica": [
		{"nombre": "Overlock", "descripción": "Mayor aceleración", "precio": 5, "imagen": "res://Interfaces/items/chip.png"},
		{"nombre": "Nanoescudo", "descripción": "Protección básica", "precio": 7, "imagen":"res://Interfaces/items/nanoescudo.png"},
	],
	"media": [
		{"nombre": "Clarividencia", "descripción": "Muestra parte de la solución por 15 segundos", "precio": 15, "imagen": "res://Interfaces/items/clarividencia.png"  },
		{"nombre": "Sensor", "descripción": "Permite ver una parte de la solución", "precio": 20, "imagen":"res://Interfaces/items/sensor.png" },
	],
	"alta": [
		{"nombre": "Rafaga", "descripción": "No disponible", "precio": 40, "imagen":"res://Interfaces/items/rafaga.png"},
		{"nombre": "Nanoescudo avanzado", "descripción": "No disponible", "precio": 50 , "imagen": "res://Interfaces/items/campoavanzado.png"},
	]
}

func _ready():
	visible = false


func mostrar_tienda():
	for child in productos_container.get_children():
		child.queue_free()
	visible = true

	var categorias = ["economica", "media", "alta"]

	for tipo in categorias:
		var lista = mejoras[tipo]
		var mejora = lista[randi() % lista.size()]
		agregar_producto(mejora, tipo)

	var cerrar = Button.new()
	cerrar.text = "Cerrar"
	cerrar.custom_minimum_size = Vector2(10, 10)
	cerrar.add_theme_color_override("font_color", Color(0.0, 0.762, 0.836, 1.0))
	cerrar.pressed.connect(func(): ocultar_tienda())

	layout.add_child(cerrar)  

func ocultar_tienda():
	visible = false


func agregar_producto(mejora: Dictionary, tipo: String):
	var contenedor = VBoxContainer.new()
	contenedor.alignment = HBoxContainer.ALIGNMENT_CENTER
	contenedor.custom_minimum_size = Vector2(60, 60)
	contenedor.add_theme_constant_override("separation", 6)

	# Imagen del ítem
	if mejora.has("imagen"):
		var textura = load(mejora["imagen"])
		if textura:
			var wrapper = CenterContainer.new()
			wrapper.custom_minimum_size = Vector2(30, 30)

			var imagen = TextureRect.new()
			imagen.texture = textura
			imagen.custom_minimum_size = Vector2(10, 10) 
			imagen.stretch_mode = TextureRect.STRETCH_SCALE
			imagen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

			wrapper.add_child(imagen)
			contenedor.add_child(wrapper)
		else:
			print("[TIENDA] ⚠ No se pudo cargar imagen para:", mejora["nombre"])

	# Nombre
	var nombre_label = Label.new()
	nombre_label.text = mejora["nombre"]
	nombre_label.add_theme_color_override("font_color", Color(0.946, 0.025, 0.829, 1.0))
	nombre_label.custom_minimum_size = Vector2(60, 0)  # ancho = 60px
	nombre_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	nombre_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre_label.add_theme_font_size_override("font_size", 10)
	contenedor.add_child(nombre_label)

	# Descripción
	var desc_label = Label.new()
	desc_label.text = mejora["descripción"]
	desc_label.add_theme_font_size_override("font_size", 8)
	desc_label.custom_minimum_size = Vector2(60, 0)  # ancho = 60px
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenedor.add_child(desc_label)

	# Precio
	var precio_label = Label.new()
	precio_label.text = "💰 " + str(mejora["precio"])
	precio_label.add_theme_font_size_override("font_size", 8)
	precio_label.custom_minimum_size = Vector2(60, 0)  # ancho = 60px
	precio_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	precio_label.add_theme_color_override("font_color", Color(0.8, 1, 0.8))
	precio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	contenedor.add_child(precio_label)

	# Botón comprar
	var boton = Button.new()
	boton.text = "Comprar"
	boton.add_theme_font_size_override("font_size", 8)
	boton.custom_minimum_size = Vector2(10,10)

	boton.pressed.connect(func(): comprar(mejora))
	contenedor.add_child(boton)

	productos_container.add_child(contenedor)


func comprar(mejora):
	if Global.gastar_monedas(mejora["precio"]):
		print("[TIENDA] Compraste:", mejora["nombre"], "| Monedas restantes:", Global.coins_total)
		Global.emit_signal("monedas_actualizadas", Global.coins_total)
	else:
		print("[TIENDA] No tienes suficientes monedas para:", mejora["nombre"])
