## Level Manager
## Owns the current level: tile grid state, visual TileMap layers, physical
## collision bodies for solid tiles, enemy spawning, and all cell queries.
##
## Cell conventions:
##  - (0, 0) is the top-left tile; tile (x, y) occupies world
##    (x*32, y*32) .. (x*32+32, y*32+32).
##  - walls   = indestructible (stop movement, bombs, line of sight)
##  - bricks  = destructible (stop movement until a bomb destroys them)

class_name LevelManager
extends Node2D

const TILE_SIZE := 32.0

signal level_loaded(level_index: int)

var current_level_index := 0
var player_spawn_point := Vector2.ZERO
var map_size := Vector2i(20, 20)

var _walls: Dictionary = {}
var _bricks: Dictionary = {}
var _tile_bodies: Dictionary = {}
var _layers: Dictionary = {}
var _tile_sets: Dictionary = {}
var _enemies_root: Node2D = null
var _level_paths: Array = []

func _ready() -> void:
	_discover_levels()

## ---------------------------------------------------------------- levels

func _discover_levels() -> void:
	_level_paths.clear()
	var dir := DirAccess.open("res://level_data")
	if dir == null:
		push_error("LevelManager: res://level_data not found")
		return
	for file in dir.get_files():
		if file.begins_with("level_") and file.ends_with(".json"):
			_level_paths.append("res://level_data/" + file)
	_level_paths.sort()

func level_count() -> int:
	return _level_paths.size()

func has_next_level() -> bool:
	return current_level_index + 1 < _level_paths.size()

func load_level(index: int) -> bool:
	if index < 0 or index >= _level_paths.size():
		push_error("LevelManager: no level at index %d" % index)
		return false
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(_level_paths[index])) != OK:
		push_error("LevelManager: JSON error in %s: %s" % [
			_level_paths[index], json.get_error_message()
		])
		return false
	var data: Variant = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_error("LevelManager: %s is not a dictionary" % _level_paths[index])
		return false

	_clear_current_level()

	map_size = Vector2i(int(data.get("map_width", 20)), int(data.get("map_height", 20)))
	_walls.clear()
	_bricks.clear()

	for rect_data in data.get("walls", []):
		_fill_rect(_walls, rect_data)
	for rect_data in data.get("destructibles", []):
		_fill_rect(_bricks, rect_data)

	_build_layers()
	_build_tile_bodies()
	_spawn_enemies(data.get("enemies", []))

	var spawn: Variant = data.get("player_spawn_point", {"x": 1.0, "y": 1.0})
	player_spawn_point = cell_to_position(Vector2i(int(spawn.x), int(spawn.y)))

	current_level_index = index
	level_loaded.emit(index)
	return true

func _fill_rect(target: Dictionary, rect_data: Dictionary) -> void:
	var origin := Vector2i(int(rect_data["x"]), int(rect_data["y"]))
	var size: Dictionary = rect_data["size"]
	for dy in range(int(size.y)):
		for dx in range(int(size.x)):
			target[origin + Vector2i(dx, dy)] = true

func _clear_current_level() -> void:
	for body in _tile_bodies.values():
		if body is Node:
			(body as Node).queue_free()
	_tile_bodies.clear()
	for layer in _layers.values():
		if layer is Node:
			(layer as Node).queue_free()
	_layers.clear()
	if _enemies_root != null and is_instance_valid(_enemies_root):
		_enemies_root.queue_free()
		_enemies_root = null

## -------------------------------------------------------------- cell API

func cell_to_position(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * TILE_SIZE + TILE_SIZE / 2.0,
		cell.y * TILE_SIZE + TILE_SIZE / 2.0
	)

func position_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(
		floori(position.x / TILE_SIZE),
		floori(position.y / TILE_SIZE)
	)

func is_inside_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < map_size.x and cell.y >= 0 and cell.y < map_size.y

## Solid = wall or brick (physically blocking).
func is_solid_cell(cell: Vector2i) -> bool:
	return _walls.has(cell) or _bricks.has(cell)

func is_brick_cell(cell: Vector2i) -> bool:
	return _bricks.has(cell)

func is_walkable_cell(cell: Vector2i) -> bool:
	return is_inside_bounds(cell) and not is_solid_cell(cell)

## Destroys a brick tile (visual + physics). No-op for non-bricks.
func clear_tile(cell: Vector2i) -> void:
	if not _bricks.has(cell):
		return
	_bricks.erase(cell)
	var layer: TileMapLayer = _layers.get("bricks")
	if layer != null:
		layer.erase_cell(cell)
	var body: Node = _tile_bodies.get(cell)
	if body != null:
		_tile_bodies.erase(cell)
		body.queue_free()

## --------------------------------------------------------------- enemies

func get_alive_enemies() -> Array:
	var alive: Array = []
	if _enemies_root != null and is_instance_valid(_enemies_root):
		for enemy in _enemies_root.get_children():
			if enemy is Node and not (enemy as Node).is_queued_for_deletion():
				alive.append(enemy)
	return alive

func _spawn_enemies(enemy_data: Array) -> void:
	_enemies_root = Node2D.new()
	_enemies_root.name = "Enemies"
	add_child(_enemies_root)
	for entry in enemy_data:
		var cell := Vector2i(int(entry.x), int(entry.y))
		var enemy: Node2D
		match str(entry.get("type", "")):
			"crawler":
				enemy = CrawlerEnemy.create()
			"patroller":
				enemy = PatrollerEnemy.create()
			"tracer":
				enemy = TracerEnemy.create()
			_:
				continue
		if enemy != null:
			enemy.position = cell_to_position(cell)
			enemy.set("level_manager", self)
			_enemies_root.add_child(enemy)

## ----------------------------------------------------------- visual layers

func _build_layers() -> void:
	_layers["floor"] = _make_layer("Floor", _tile_set_for("floor"))
	_layers["walls"] = _make_layer("Walls", _tile_set_for("wall"))
	_layers["bricks"] = _make_layer("Bricks", _tile_set_for("brick"))

	var floor_layer: TileMapLayer = _layers["floor"]
	for y in map_size.y:
		for x in map_size.x:
			floor_layer.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)

	var walls_layer: TileMapLayer = _layers["walls"]
	for cell in _walls:
		walls_layer.set_cell(cell, 0, Vector2i.ZERO)

	var bricks_layer: TileMapLayer = _layers["bricks"]
	for cell in _bricks:
		bricks_layer.set_cell(cell, 0, Vector2i.ZERO)

func _make_layer(layer_name: String, tile_set: TileSet) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.tile_set = tile_set
	layer.z_index = 0 if layer_name == "Floor" else 1
	add_child(layer)
	return layer

func _tile_set_for(kind: String) -> TileSet:
	if _tile_sets.has(kind):
		return _tile_sets[kind]
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(int(TILE_SIZE), int(TILE_SIZE))
	var source := TileSetAtlasSource.new()
	source.texture = _tile_texture(kind)
	source.texture_region_size = Vector2i(int(TILE_SIZE), int(TILE_SIZE))
	tile_set.add_source(source, 0)
	source.create_tile(Vector2i.ZERO)
	_tile_sets[kind] = tile_set
	return tile_set

func _tile_texture(kind: String) -> ImageTexture:
	var image := Image.create(int(TILE_SIZE), int(TILE_SIZE), false, Image.FORMAT_RGBA8)
	match kind:
		"floor":
			_paint_floor(image)
		"wall":
			_paint_wall(image)
		"brick":
			_paint_brick(image)
	return ImageTexture.create_from_image(image)

## Classic green floor with subtle speckle.
func _paint_floor(image: Image) -> void:
	var base := Color(0.40, 0.62, 0.28)
	var dark := Color(0.34, 0.55, 0.24)
	var light := Color(0.46, 0.68, 0.32)
	for y in int(TILE_SIZE):
		for x in int(TILE_SIZE):
			var color := base
			var h := (x * 7 + y * 13) % 17
			if h == 0:
				color = dark
			elif h == 5:
				color = light
			image.set_pixel(x, y, color)

## Gray 3D bevel block (classic bomberman wall).
func _paint_wall(image: Image) -> void:
	var outline := Color(0.22, 0.22, 0.26)
	var light := Color(0.85, 0.85, 0.9)
	var mid := Color(0.62, 0.62, 0.68)
	var dark := Color(0.4, 0.4, 0.46)
	for y in int(TILE_SIZE):
		for x in int(TILE_SIZE):
			var color := mid
			if x < 2 or y < 2 or x > int(TILE_SIZE) - 3 or y > int(TILE_SIZE) - 3:
				color = outline
			elif x < 5 or y < 5:
				color = light
			elif x > int(TILE_SIZE) - 6 or y > int(TILE_SIZE) - 6:
				color = dark
			image.set_pixel(x, y, color)

## Brown brick with mortar joints, staggered per row.
func _paint_brick(image: Image) -> void:
	var base := Color(0.56, 0.33, 0.17)
	var mortar := Color(0.3, 0.18, 0.1)
	for y in int(TILE_SIZE):
		for x in int(TILE_SIZE):
			var color := base
			if y % 8 == 0:
				color = mortar
			else:
				var row_offset := 0 if (y / 8) % 2 == 0 else 8
				if (x + row_offset) % 16 == 0:
					color = mortar
			if x == 0 or y == 0 or x == int(TILE_SIZE) - 1 or y == int(TILE_SIZE) - 1:
				color = Color(0.2, 0.11, 0.05)
			image.set_pixel(x, y, color)

## ---------------------------------------------------------- physics bodies

## The player moves with move_and_slide(), so every solid tile needs a
## physical body; the TileMap layers are purely visual.
func _build_tile_bodies() -> void:
	for cell in _walls.keys():
		_add_tile_body(cell)
	for cell in _bricks.keys():
		_add_tile_body(cell)

func _add_tile_body(cell: Vector2i) -> void:
	var body := StaticBody2D.new()
	body.position = cell_to_position(cell)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE, TILE_SIZE)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	_tile_bodies[cell] = body
