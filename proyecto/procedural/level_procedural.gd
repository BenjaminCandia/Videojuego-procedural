extends Node2D

# ============================================================
# 🧩 MÓDULO: Variables
# ============================================================

# --- Escenas a instanciar ---
@export var player_scene: PackedScene
@export var door_scene: PackedScene
@export var result_panel_scene: PackedScene
@export var coin_scene: PackedScene
@export var enemy_scene: PackedScene
@onready var equation_label: Label = $HUD/TextureRect/Label

# --- Capas (TileMapLayer) ---
@onready var wall:    TileMapLayer = $TileMap/Wall
@onready var ground:  TileMapLayer = $TileMap/Ground
@onready var objects_layer: TileMapLayer = $TileMap/Objects

# --- Config de muros (borde de 2) ---
@export var WALL_SOURCE_ID := 3
@export var WALL_ATLAS_BASE := Vector2i(0, 0)
@export var border_thickness := 2

# --- Config de suelo (tiles/atlas) ---
@export var GROUND_SOURCE_ID: int = 5
@export var GROUND_ATLAS_BASE: Vector2i = Vector2i(0, 0)
@export_enum("checker_x","solid","checker_2x2") var ground_pattern := "checker_x"

# --- Estado runtime ---
var player: Node2D = null
var coins: Array = []
var enemies: Array = []
var door: Node2D = null
var door2: Node2D = null
var start_tile: Vector2i
var end_tile: Vector2i
var alt_end_tile: Vector2i
var path_tiles: Array[Vector2i] = []
var result_panel_door: Node2D = null    # correcto
var result_panel_door2: Node2D = null   # incorrecto

# Donde guardarás la ecuación actual
var current_expression: String = ""
var current_correct: int = 0
var current_wrongs: Array[int] = []
const MAX_JUMP_TILES = 4
const MAX_GAP_TILES  = 4
const MAX_FALL_TILES = 7
const TILE_SIZE: int = 16
const BORDER_TILES: int = 2
var object_prototypes: Array = []  # se llena en _ready
var map_width: int = 40
var map_height: int = 23
const NUM_OBJECT_PLACEMENTS: int = 8
const MIN_DIST_END_TILES: int = 6
func place_objects_on_path(path_tiles: Array[Vector2i]) -> void:
	if object_prototypes.is_empty():
		return

	var candidates: Array[Vector2i] = get_candidate_tiles_for_objects(path_tiles)
	if candidates.is_empty():
		print("⚠️ No hay tiles candidatos para colocar objetos.")
		return

	candidates.shuffle()

	var total_objects: int = min(NUM_OBJECT_PLACEMENTS, candidates.size())
	var num_protos: int = object_prototypes.size()

	for i in range(total_objects):
		var anchor: Vector2i = candidates[i]
		var proto_index: int = i % num_protos  # 0,1,2,0,1,2...
		var proto: Dictionary = object_prototypes[proto_index]

		stamp_object(proto, anchor)


func stamp_object(proto: Dictionary, anchor_tile: Vector2i) -> void:
	var cells: Array = proto["cells"]
	var size_tiles: Vector2i = proto["size_tiles"]

	for cell_data in cells:
		var offset: Vector2i = cell_data["offset"]
		var source_id: int = cell_data["source_id"]
		var atlas: Vector2i = cell_data["atlas"]

		var tile_pos: Vector2i = anchor_tile + offset + Vector2i(0, -2)

		# dentro del mapa
		if tile_pos.x < 0 or tile_pos.x >= map_width:
			continue
		if tile_pos.y < 0 or tile_pos.y >= map_height:
			continue

		objects_layer.set_cell(tile_pos, source_id, atlas)


func get_candidate_tiles_for_objects(path_tiles: Array[Vector2i]) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []

	for t in path_tiles:
		# lejos de las puertas
		var dist_end: int = manhattan_distance(t, end_tile)
		var dist_alt: int = manhattan_distance(t, alt_end_tile)

		if dist_end < MIN_DIST_END_TILES:
			continue
		if dist_alt < MIN_DIST_END_TILES:
			continue

		# también podemos evitar muy cerca del inicio si quieres:
		# var dist_start: int = manhattan_distance(t, start_tile)
		# if dist_start < 3: continue

		candidates.append(t)

	return candidates


func manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func build_object_prototypes() -> Array:
	var groups: Array = get_object_groups()
	var protos: Array = []

	for group in groups:
		var info: Dictionary = get_group_bounds(group)
		var min_tile: Vector2i = info["min"]
		var size_tiles: Vector2i = info["size_tiles"]

		var cells: Array = []  # cada elemento: { offset: Vector2i, source_id: int, atlas: Vector2i }

		for t in group:
			var offset: Vector2i = t - min_tile
			var source_id: int = objects_layer.get_cell_source_id(t)
			var atlas: Vector2i = objects_layer.get_cell_atlas_coords(t)
			var cell_data: Dictionary = {
				"offset": offset,
				"source_id": source_id,
				"atlas": atlas,
			}
			cells.append(cell_data)

		var proto: Dictionary = {
			"cells": cells,
			"size_tiles": size_tiles,
		}
		protos.append(proto)

	return protos


func get_group_bounds(group: Array[Vector2i]) -> Dictionary:
	var min_x: int = group[0].x
	var max_x: int = group[0].x
	var min_y: int = group[0].y
	var max_y: int = group[0].y

	for tile in group:
		if tile.x < min_x:
			min_x = tile.x
		if tile.x > max_x:
			max_x = tile.x
		if tile.y < min_y:
			min_y = tile.y
		if tile.y > max_y:
			max_y = tile.y

	var width_tiles: int = max_x - min_x + 1
	var height_tiles: int = max_y - min_y + 1

	# centro en tiles
	var center_tile := Vector2(
		min_x + width_tiles / 2.0,
		min_y + height_tiles / 2.0
	)

	# centro en píxeles (si necesitas posiciones en el mundo)
	var center_px := Vector2(
		(center_tile.x + 0.0) * TILE_SIZE,
		(center_tile.y + 0.0) * TILE_SIZE
	)

	return {
		"min": Vector2i(min_x, min_y),
		"max": Vector2i(max_x, max_y),
		"size_tiles": Vector2i(width_tiles, height_tiles),
		"center_tile": center_tile,
		"center_px": center_px,
	}

func get_object_groups() -> Array:
	var groups: Array = []
	var used: Array[Vector2i] = objects_layer.get_used_cells()
	var visited: Dictionary = {}

	for cell in used:
		if visited.has(cell):
			continue

		var source_id: int = objects_layer.get_cell_source_id(cell)
		var stack: Array[Vector2i] = [cell]
		var group: Array[Vector2i] = []
		visited[cell] = true

		while stack.size() > 0:
			var current: Vector2i = stack.pop_back()
			group.append(current)

			var dirs := [
				Vector2i(1, 0),
				Vector2i(-1, 0),
				Vector2i(0, 1),
				Vector2i(0, -1)
			]

			for d in dirs:
				var nb: Vector2i = current + d
				if visited.has(nb):
					continue
				if not used.has(nb):
					continue
				if objects_layer.get_cell_source_id(nb) != source_id:
					continue

				visited[nb] = true
				stack.append(nb)

		groups.append(group)

	return groups

func get_object_tiles() -> Dictionary:
	var objects := {}   # key = tile signature, value = array of tile coords
	
	# Obtener todos los tiles colocados en este TileMapLayer
	var used: Array[Vector2i] = objects_layer.get_used_cells()
	
	for tile: Vector2i in used:
		var source_id := objects_layer.get_cell_source_id(tile)
		var atlas_coords := objects_layer.get_cell_atlas_coords(tile)
		
		# clave única del "objeto"
		var key := str(source_id) + "_" + str(atlas_coords)
		
		if not objects.has(key):
			objects[key] = []
		
		objects[key].append(tile)
	
	return objects

func is_ground_tile(tile: Vector2i) -> bool:
	var source_id: int = ground.get_cell_source_id(tile)  # ✅ solo el tile
	return source_id != -1

func get_random_empty_tile() -> Vector2i:

	var map_width: int = 40
	var map_height: int = 23
	var attempts: int = 0
	var max_attempts: int = 100

	while attempts < max_attempts:
		attempts += 1

		var tx_min: int = BORDER_TILES
		var tx_max: int = map_width - BORDER_TILES - 1
		var ty_min: int = BORDER_TILES
		var ty_max: int = map_height - BORDER_TILES - 1

		var tile_x: int = randi_range(tx_min, tx_max)
		var tile_y: int = randi_range(ty_min, ty_max)
		var tile: Vector2i = Vector2i(tile_x, tile_y)

		if not is_ground_tile(tile):
			return tile

	# Si no encontramos nada “vacío”, devolvemos algo seguro
	return Vector2i(BORDER_TILES + 1, BORDER_TILES + 1)

func validate_route(path_tiles: Array[Vector2i]) -> bool:
	if path_tiles.size() < 2:
		print("❌ Ruta demasiado corta.")
		return false

	for i in range(path_tiles.size() - 1):
		var a: Vector2i = path_tiles[i]
		var b: Vector2i = path_tiles[i + 1]

		var dx : int = abs(b.x - a.x)
		var dy := b.y - a.y  # y positiva = hacia abajo en Godot

		# --- Horizontal ---
		if dx > MAX_GAP_TILES:
			print("❌ Gap horizontal demasiado grande entre", a, "y", b, "dx:", dx)
			return false

		# --- Salto hacia arriba ---
		if b.y < a.y:
			var up : int = abs(dy)
			if up > MAX_JUMP_TILES:
				print("❌ Salto vertical muy alto entre", a, "y", b, "dy:", up)
				return false

		# --- Caída hacia abajo ---
		if b.y > a.y:
			var fall := dy
			if fall > MAX_FALL_TILES:
				print("❌ Caída demasiado grande entre", a, "y", b, "dy:", fall)
				return false

		print("✅ Segmento válido", a, "→", b, "dx:", dx, "dy:", dy)

	print("✅ Ruta jugable validada con", path_tiles.size(), "puntos.")
	return true

func _update_equation_label() -> void:
	if equation_label:
		equation_label.text = current_expression

# ============================================================
# 🧩 MÓDULO: TILES (utilidades de tiles y grilla)
# ============================================================

func _ts_tile_size() -> Vector2i:
	# Detecta el tamaño real del tileset (16×16 si no hay)
	if ground and ground.tile_set:
		return ground.tile_set.tile_size
	return Vector2i(32,32)

func _grid_from_viewport() -> Vector2i:
	var ts := _ts_tile_size()
	var vp := get_viewport().get_visible_rect().size
	return Vector2i(ceil(vp.x / ts.x), ceil(vp.y / ts.y))

func _tile_center_world(tile: Vector2i) -> Vector2:
	# Centro del tile en coordenadas globales
	var ts: Vector2i =  ground.tile_set.tile_size if ground and ground.tile_set else  Vector2i(16, 16)
	return Vector2((tile.x + 0.5) * ts.x, (tile.y + 0.5) * ts.y)

# Atlas helper para patrones de suelo (si quieres alternar visual)
func _ground_atlas_for(x:int, y:int) -> Vector2i:
	match ground_pattern:
		"checker_x":
			return Vector2i(GROUND_ATLAS_BASE.x + (x % 2), GROUND_ATLAS_BASE.y + 0)
		"checker_2x2":
			return Vector2i(GROUND_ATLAS_BASE.x + (x % 2), GROUND_ATLAS_BASE.y + (y % 2))
		"solid":
			return GROUND_ATLAS_BASE
		_:
			return GROUND_ATLAS_BASE

# ============================================================
# 🧱 CREA MUROS DE 2 TILES DE GROSOR, PATRÓN 2×2 REPETIDO
# ============================================================
func fill_walls(tiles_x: int, tiles_y: int) -> void:
	wall.clear()
	for x in range(tiles_x):
		for y in range(tiles_y):
			if x < 2 or x >= tiles_x - 2 or y < 2 or y >= tiles_y - 2:
				var atlas_x = x % 2
				var atlas_y = y % 2
				wall.set_cell(Vector2i(x, y), WALL_SOURCE_ID, Vector2i(atlas_x, atlas_y))

# ============================================================
# 🪨 MÓDULO: GENERAR SUELO (route + plataformas por sectores)
# ============================================================
func generate_ground() -> Dictionary:
	# RNG
	path_tiles.clear()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()

	# Dimensiones del mapa y sectores
	var sector_w: int = 8
	var sector_h: int = 5
	var sectors_x: int = map_width / sector_w
	var sectors_y: int = map_height / sector_h
	
	# Limpia capa de ground
	if ground:
		ground.clear()
	
	var route_tiles: Array[Vector2i] = []
	var sector_path: Array[Vector2i] = []
	var visited: Dictionary = {}

	var start_positions: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(sectors_x - 1, 0),
		Vector2i(0, sectors_y - 1),
		Vector2i(sectors_x - 1, sectors_y - 1)
	]

	# --- Escoger inicio ---
	var start_index := rng.randi_range(0, start_positions.size() - 1)
	var start_sector: Vector2i = start_positions[start_index]

	# --- Escoger fin principal (en otra esquina) ---
	var valid_ends: Array[Vector2i] = start_positions.filter(func(p): return p != start_sector)
	var end_sector: Vector2i = valid_ends[rng.randi_range(0, valid_ends.size() - 1)]

	# --- Escoger segundo fin (para door2) ---
	var alt_end_sector: Vector2i = end_sector
	if valid_ends.size() > 1:
		var remaining_ends: Array[Vector2i] = []
		for p in valid_ends:
			if p != end_sector:
				remaining_ends.append(p)
		if remaining_ends.size() > 0:
			alt_end_sector = remaining_ends[rng.randi_range(0, remaining_ends.size() - 1)]

	# Parámetros
	var OFFSET_TOP := 5
	var OFFSET_SIDE := 2
	var START_WIDTH := 2
	var END_WIDTH := 6
	var BORDER := border_thickness            # ej: 2

	# Tamaño total del mapa en tiles
	var MAP_W := int(map_width)
	var MAP_H := int(map_height)

	# Helpers de borde interior
	var LEFT_INNER_X := BORDER
	var RIGHT_INNER_X := MAP_W - BORDER - 1
	var TOP_INNER_Y := BORDER
	var BOTTOM_INNER_Y := MAP_H - BORDER - 1

	# =================== INICIO (2 tiles) ===================
	var start_y: int
	if start_sector.y == 0:
		# esquina superior → a OFFSET_TOP del borde superior
		start_y = TOP_INNER_Y + OFFSET_TOP
	else:
		# esquina inferior → a OFFSET_TOP del borde inferior
		start_y = BOTTOM_INNER_Y - OFFSET_TOP

	var start_first_x: int
	if start_sector.x == 0:
		# lado izquierdo → a OFFSET_SIDE del borde izquierdo
		start_first_x = LEFT_INNER_X + OFFSET_SIDE
		# dibujar hacia la derecha
		for i in range(START_WIDTH):
			ground.set_cell(Vector2i(start_first_x + i, start_y), GROUND_SOURCE_ID, GROUND_ATLAS_BASE)
	else:
		# lado derecho → a OFFSET_SIDE del borde derecho, dibujando hacia la izquierda
		var rightmost_x := RIGHT_INNER_X - OFFSET_SIDE
		for i in range(START_WIDTH):
			ground.set_cell(Vector2i(rightmost_x - i, start_y), GROUND_SOURCE_ID, GROUND_ATLAS_BASE)
		start_first_x = rightmost_x - (START_WIDTH - 1)

	start_tile = Vector2i(start_first_x, start_y)
	route_tiles.insert(0, start_tile)
	path_tiles.append(start_tile)

	# ==================== FINAL PRINCIPAL (6 tiles) ====================
	var end_y: int
	if end_sector.y == 0:
		end_y = TOP_INNER_Y + OFFSET_TOP
	else:
		end_y = BOTTOM_INNER_Y - OFFSET_TOP

	var end_first_x: int
	if end_sector.x == 0:
		# izquierda → hacia la derecha
		end_first_x = LEFT_INNER_X + OFFSET_SIDE
		for i in range(END_WIDTH):
			ground.set_cell(Vector2i(end_first_x + i, end_y), GROUND_SOURCE_ID, GROUND_ATLAS_BASE)
	else:
		# derecha → hacia la izquierda
		var rightmost_x2 := RIGHT_INNER_X - OFFSET_SIDE
		for i in range(END_WIDTH):
			ground.set_cell(Vector2i(rightmost_x2 - i, end_y), GROUND_SOURCE_ID, GROUND_ATLAS_BASE)
		end_first_x = rightmost_x2 - (END_WIDTH - 1)

	end_tile = Vector2i(end_first_x, end_y)
	route_tiles.append(end_tile)
	path_tiles.append(end_tile)

	# ==================== SEGUNDA PUERTA (6 tiles) =====================
	var alt_end_y: int
	if alt_end_sector.y == 0:
		alt_end_y = TOP_INNER_Y + OFFSET_TOP
	else:
		alt_end_y = BOTTOM_INNER_Y - OFFSET_TOP

	var alt_end_first_x: int
	if alt_end_sector.x == 0:
		alt_end_first_x = LEFT_INNER_X + OFFSET_SIDE
		for i in range(END_WIDTH):
			ground.set_cell(Vector2i(alt_end_first_x + i, alt_end_y), GROUND_SOURCE_ID, GROUND_ATLAS_BASE)
	else:
		var rightmost_x3 := RIGHT_INNER_X - OFFSET_SIDE
		for i in range(END_WIDTH):
			ground.set_cell(Vector2i(rightmost_x3 - i, alt_end_y), GROUND_SOURCE_ID, GROUND_ATLAS_BASE)
		alt_end_first_x = rightmost_x3 - (END_WIDTH - 1)

	alt_end_tile = Vector2i(alt_end_first_x, alt_end_y)
	route_tiles.append(alt_end_tile)
	path_tiles.append(alt_end_tile)

	# --- Generar camino sectorial (DFS simple) ---
	var stack: Array[Vector2i] = [start_sector]
	var reached_end := false
	var reached_alt := false

	while stack.size() > 0:
		var current: Vector2i = stack.pop_back()

		if visited.has(str(current)):
			continue

		sector_path.append(current)
		visited[str(current)] = true

		if current == end_sector:
			reached_end = true
		if current == alt_end_sector:
			reached_alt = true

		# Cuando ya pasamos por las 2 esquinas, cortamos
		if reached_end and reached_alt:
			break

		var dirs: Array[Vector2i] = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
		dirs.shuffle()
		for d in dirs:
			var next: Vector2i = current + d
			if next.x >= 0 and next.x < sectors_x and next.y >= 0 and next.y < sectors_y:
				if not visited.has(str(next)):
					stack.append(next)

	# --- Dibujar plataformas en los sectores del camino ---
	var prev_plat_y := start_tile.y
	var prev_plat_x := start_tile.x
	for sec in sector_path:
		var base_x := sec.x * sector_w
		var base_y := sec.y * sector_h
		var target_y := prev_plat_y                      # queremos mantener altura similar
		var min_y := target_y - MAX_JUMP_TILES + 1      # no demasiado arriba
		var max_y := target_y + MAX_JUMP_TILES - 1      # no demasiado abajo

		# Limitar al sector actual
		min_y = clamp(min_y, base_y + 2, base_y + sector_h - 2)
		max_y = clamp(max_y, base_y + 2, base_y + sector_h - 2)

		var plat_y := rng.randi_range(min_y, max_y)
		# Mantener X cerca del anterior, para evitar gaps imposibles
		var target_x := prev_plat_x
		var min_x := target_x - MAX_GAP_TILES
		var max_x := target_x + MAX_GAP_TILES

		# Clampear al sector actual
		var sector_min := base_x + 1
		var sector_max := base_x + sector_w - 4

		min_x = clamp(min_x, sector_min, sector_max)
		max_x = clamp(max_x, sector_min, sector_max)

		var plat_x := rng.randi_range(min_x, max_x)
		var width := rng.randi_range(3, 5)
		for i in range(width):
			ground.set_cell(Vector2i(plat_x + i, plat_y), GROUND_SOURCE_ID, GROUND_ATLAS_BASE)
		route_tiles.append(Vector2i(plat_x, plat_y))
		path_tiles.append(Vector2i(plat_x, plat_y))
		prev_plat_y = plat_y
		prev_plat_x = plat_x
	var ok := validate_route(path_tiles)
	if not ok:
		print("❌ Ruta no jugable, deberías regenerar el nivel.")

	return {
		"route_tiles": route_tiles,
		"sector_path": sector_path,
		"start_sector": start_sector,
		"end_sector": end_sector,
		"alt_end_sector": alt_end_sector,
		"grid_size": Vector2i(sectors_x, sectors_y),
		"start_tile": start_tile,
		"end_tile": end_tile,
		"alt_end_tile": alt_end_tile,
		"path_tiles": path_tiles,
	}

func get_random_inside_map() -> Vector2:
	const TILE_SIZE: int = 16
	const BORDER_TILES: int = 3
	var map_width: int = 40
	var map_height: int = 23
	var min_tx: int = BORDER_TILES
	var max_tx: int = map_width - BORDER_TILES - 1
	
	var min_ty: int = BORDER_TILES
	var max_ty: int = map_height - BORDER_TILES - 1

	var tile_x: int = randi_range(min_tx, max_tx)
	var tile_y: int = randi_range(min_ty, max_ty)

	# Centro del tile → le sumo 0.5
	var px: float = (tile_x + 0.5) * TILE_SIZE
	var py: float = (tile_y + 0.5) * TILE_SIZE

	return Vector2(px, py)
func cell_one_tile_up_global(layer: TileMapLayer, cell: Vector2i) -> Vector2:
	var ts: Vector2i = layer.tile_set.tile_size

	var local := Vector2(
		(cell.x + 0.5) * ts.x,   # centro horizontal
		(cell.y - 1.5) * ts.y    # 1.5 tiles arriba
	)

	return layer.to_global(local)
func cell_one_tile_up_global2(layer: TileMapLayer, cell: Vector2i) -> Vector2:
	var ts: Vector2i = layer.tile_set.tile_size

	var local := Vector2(
		(cell.x + 3) * ts.x,
		(cell.y - 1.3) * ts.y
	)

	return layer.to_global(local)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
# ============================================================
# 🧠 VALIDACIÓN DE RUTA SECTORIAL (MACRO)
# ============================================================
func validate_route_sectors(path: Array, start_sector: Vector2i, end_sector: Vector2i, total_x: int, total_y: int) -> bool:
	if path.is_empty():
		print("❌ Ruta vacía.")
		return false

	if path[0] != start_sector:
		print("⚠️ El primer sector no coincide con el inicio.")
	if path[-1] != end_sector:
		print("⚠️ El último sector no coincide con la meta.")

	for i in range(path.size() - 1):
		var a = path[i]
		var b = path[i + 1]
		var diff = b - a

		if abs(diff.x) + abs(diff.y) != 1:
			print("❌ Sectores no adyacentes:", a, "→", b)
			return false

		if b.x < 0 or b.y < 0 or b.x >= total_x or b.y >= total_y:
			print("❌ Sector fuera de rango:", b)
			return false

	print("✅ Ruta sectorial válida con", path.size(), "sectores conectados.")
	return true

# ============================================================
# 🧗 VALIDACIÓN DE RUTA JUGABLE (MICRO)
# ============================================================
func _request_new_equation() -> void:
	var result: Dictionary = await ApiClient.fetch_equation(3, 1)
	if typeof(result) != TYPE_DICTIONARY or result.is_empty():
		# Fallback local
		current_expression = "7 + 4 + 4"
		current_correct = 15
		current_wrongs = [16, 17]
	else:
		current_expression = str(result.get("expression", ""))
		current_correct = int(result.get("correct", 0))
		current_wrongs.clear()
		for w in result.get("wrongs", []):
			current_wrongs.append(int(w))
	
	# Aplicar los resultados a los carteles de las puertas
	_apply_results_to_panels()
	_update_equation_label()


func _apply_results_to_panels() -> void:
	if not result_panel_door or not result_panel_door2:
		return

	var correct_value: int = current_correct

	# Usar solo la PRIMERA respuesta errónea
	var wrong_value: int
	if current_wrongs.size() > 0:
		wrong_value = current_wrongs[0]
	else:
		# fallback por si algún día la API falla
		wrong_value = current_correct + 1

	# door = correcto
	result_panel_door.call("set_number", correct_value)

	# door2 = incorrecto
	result_panel_door2.call("set_number", wrong_value)

func spawn_coins():
	for i in range(3):
		var coin = coin_scene.instantiate()
		coin.position = get_random_inside_map()
		add_child(coin)
		coins.append(coin)
		
func spawn_enemies():
	for i in range(2):
		var enemy = enemy_scene.instantiate()
		enemy.position = get_random_inside_map()
		add_child(enemy)
		enemies.append(enemy)

func _ready() -> void:
	# Alinear TileMap y capas al origen
	$TileMap.position = Vector2.ZERO
	if wall:
		wall.position = Vector2.ZERO
	if ground:
		ground.position = Vector2.ZERO
	if objects_layer:
		objects_layer.position = Vector2.ZERO
	object_prototypes = build_object_prototypes()
	objects_layer.clear()  # limpiamos los “de muestra” del editor
	# Calcular tamaño del mapa en tiles según el viewport
	var size := get_viewport().get_visible_rect().size
	var tiles_x := int(size.x / wall.tile_set.tile_size.x)
	var tiles_y := int(size.y / wall.tile_set.tile_size.y)

	fill_walls(tiles_x, tiles_y)

	# Generar piso y obtener datos de inicio/fin
	var gen: Dictionary = generate_ground()
	place_objects_on_path(path_tiles)
	# Instanciar PLAYER si hace falta
	if player == null and player_scene:
		player = player_scene.instantiate()
		add_child(player)
		# Asegurar grupo Player
		if not player.is_in_group("Player"):
			player.add_to_group("Player")

	# Instanciar PUERTA 1 si hace falta
	if door == null and door_scene:
		door = door_scene.instantiate()
		add_child(door)
		# Esta escena se vuelve el "siguiente nivel" (reinicio)
		var level_path := get_tree().current_scene.scene_file_path
		door.next_scene = level_path   # string
		print("🔍 next_scene =", door.next_scene, "  (tipo:", typeof(door.next_scene), ")")

	# Instanciar PUERTA 2 si hace falta
	if door2 == null and door_scene:
		door2 = door_scene.instantiate()
		add_child(door2)
		# También apunta a este mismo nivel (puede ser otro nivel si quieres)
		var level_path2 := 'res://Interfaces/GameOver/game_over.tscn'
		door2.next_scene = level_path2
		print("🔍 door2 next_scene =", door2.next_scene, "  (tipo:", typeof(door2.next_scene), ")")

	# Posicionar usando la capa Ground como referencia
	var start_cell: Vector2i = gen["start_tile"]
	var end_cell: Vector2i = gen["end_tile"]
	var alt_end_cell: Vector2i = gen["alt_end_tile"]

	# PLAYER en el inicio
	player.position = cell_one_tile_up_global(ground, start_cell)

	# PUERTA 1 en end_cell
	door.position = cell_one_tile_up_global2(ground, end_cell)

	# PUERTA 2 en alt_end_cell (segunda esquina, lejos del player)
	door2.position = cell_one_tile_up_global2(ground, alt_end_cell)
	spawn_coins()
	spawn_enemies()
	# ====== CARTELITOS BAJO LAS PUERTAS (IMAGEN + TEXTO) ======
	if result_panel_scene:
		var ts: Vector2i = _ts_tile_size()
		var offset_under := Vector2(0, ts.y * 0.8)  # ~0.8 tiles debajo

		# Panel bajo puerta correcta (door)
		result_panel_door = result_panel_scene.instantiate()
		add_child(result_panel_door)
		result_panel_door.position = door.position + offset_under

		# Panel bajo puerta incorrecta (door2)
		result_panel_door2 = result_panel_scene.instantiate()
		add_child(result_panel_door2)
		result_panel_door2.position = door2.position + offset_under
	var groups: Array = get_object_groups()
	for i in range(groups.size()):
		var info := get_group_bounds(groups[i])
		print("Objeto", i)
		print("  Tiles:", groups[i])
		print("  min:", info["min"], "max:", info["max"])
		print("  size (tiles):", info["size_tiles"])
		print("  center_tile:", info["center_tile"])
		print("  center_px:", info["center_px"])

	await _request_new_equation()
