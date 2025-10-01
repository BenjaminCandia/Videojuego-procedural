extends Node2D

@onready var ground: TileMapLayer = $TileMap/Ground
@onready var wall: TileMapLayer = $TileMap/Wall

@export var tile_size := 32

# === TILE IDs (según tu debug) ===
@export var GROUND_SOURCE_ID := 5
@export var GROUND_ATLAS := Vector2i(0, 0)

@export var WALL_SOURCE_ID := 3
@export var WALL_ATLAS := Vector2i(0, 0)

func _ready() -> void:
	# 🔧 Forzar tamaño de ventana
	get_window().size = Vector2i(1280, 720)

	var tiles_x = 1280 / tile_size  # = 40
	var tiles_y = 720 / tile_size   # = 22

	fill_walls(tiles_x, tiles_y)
	generate_ground(tiles_x, tiles_y)


# ========================
# WALLS (marco simple)
# ========================
func fill_walls(tiles_x: int, tiles_y: int) -> void:
	wall.clear()

	# Fila superior e inferior
	for x in range(tiles_x):
		wall.set_cell(Vector2i(x, 0), WALL_SOURCE_ID, WALL_ATLAS)                # arriba
		wall.set_cell(Vector2i(x, tiles_y - 1), WALL_SOURCE_ID, WALL_ATLAS)      # abajo

	# Columnas izquierda y derecha
	for y in range(tiles_y):
		wall.set_cell(Vector2i(0, y), WALL_SOURCE_ID, WALL_ATLAS)                # izquierda
		wall.set_cell(Vector2i(tiles_x - 1, y), WALL_SOURCE_ID, WALL_ATLAS)      # derecha


# ========================
# GROUND (plataformas ascendentes)
# ========================
func generate_ground(tiles_x: int, tiles_y: int) -> void:
	ground.clear()

	var rng = RandomNumberGenerator.new()
	rng.randomize()

	# Colocar plataformas en "niveles" ascendentes
	var step_y = 3   # separación vertical entre plataformas
	var platform_len_min = 3
	var platform_len_max = 6

	var y := tiles_y - 3   # empieza cerca del piso
	var direction := 1     # 1 = izquierda→derecha, -1 = derecha→izquierda

	while y > 2:
		var length = rng.randi_range(platform_len_min, platform_len_max)

		var x_start : int
		if direction == 1:
			x_start = 2
		else:
			x_start = tiles_x - length - 3

		for i in range(length):
			var cell = Vector2i(x_start + i, y)
			ground.set_cell(cell, GROUND_SOURCE_ID, GROUND_ATLAS)

		# subir un nivel
		y -= step_y
		direction *= -1  # alterna el lado de aparición de la plataforma

	# Bloque final en la esquina superior derecha
	ground.set_cell(Vector2i(tiles_x - 3, 1), GROUND_SOURCE_ID, GROUND_ATLAS)
