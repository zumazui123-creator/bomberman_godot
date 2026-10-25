## Level Loading Script
## BOMBERMAN GODOT - Level Management & Scene LOADING
## 🗺️ MAP LOADER ON STEROIDS! 🎯

class_name LevelManager
extends Node2D

signal level_loaded(level_data)
signal level_complete
signal player_died(player)
signal game_paused
signal game_resumed

# Level definition
extends Resource
class_name LevelDefinition
var level_name := "level_1"
var map_width := 16
var map_height := 16
var player_spawn_point := Vector2(2.0, 2.0)
var enemies: Array[Dictionary] = []
var items: Array[Dictionary] = []
var walls: Array[Dictionary] = []
var destructibles: Array[Dictionary] = []
var powerups: Array[Dictionary] = []

# Loading state
var current_level := 0
var levels_loaded := []
var is_loading_level := false
var errors: Array[String]

# References
@onready var tile_map_layer = $TileMapLayer
@onready var collision_layer = $CollisionLayer

func _ready() -> void:
	print("🗺️ LevelManager initialized!")
	# Load first level
	load_level(current_level)

# Load a specific level from JSON
func load_level(level_index: int) -> void:
	if is_loading_level:
		push_error("LevelManager: Level already loading!")
		return
	
	is_loading_level = true
	errors.clear()
	
	var level_path = "res://level_data/level_{}.json".format(level_index)
	
	if not ResourceLoader.exists(level_path):
		errors.append("🔥 LEVEL_{}: File not found!".format(level_index))
		is_loading_level = false
		return
	
	level_loaded.emit(load_json(level_path))
	is_loading_level = false

# Create level scene from data
func create_level(level_data: Dictionary) -> void:
	if not tile_map_layer:
		push_error("LevelManager: TileMapLayer not found!")
		return
	
	# Clean existing scene
	if tile_map_layer.get_node_or_null("TileMap"):
		tile_map_layer.get_node("TileMap").queue_free()
	if collision_layer.get_node_or_null("Collision"):
		collision_layer.get_node("Collision").queue_free()
	
	# Get map dimensions
	var map_data = level_data.get("map", level_data.get("level", ""))
	var map_array = parse_map_data(map_data)
	
	var map_width = map_array.size()
	var map_height = map_array.size(1) if map_array.size(1) > 0 else 16
	
	# Create tilemap
	var tilemap = TileMap2D.new()
	tilemap.area = true
	var tileset = preload("res://assets/sprites/tiles/tileset_01.svgatlas")
	var size = IntVector2(map_width * 32, map_height * 32)
	tilemap.create_tilemap_layer_from_tileset(tileset, Rect2(0, 0, size.x, size.y))
	
	if not tile_map_layer:
		push_error("LevelManager: TileMapLayer not found!")
		return
	
	tile_map_layer.add_child(tilemap)
	
	# Set collision layers
	if collision_layer:
		collision_layer.setup_tilemap(collision_layer, map_width, map_height)
	
	level_loaded.emit(level_data)

# Parse map data (string or 2D array)
func parse_map_data(map_data: Variant) -> PackedVector2Array:
	if map_data.is_string():
		# Parse string format (e.g., "......\n......\n......")
		var lines = map_data.split("\n")
		var map_array = []
		for line in lines:
			var cells = line.split("")
			map_array.append([Vector2(cell, 0) for cell in cells])
		return map_array
	return []

# Load game configuration
func load_game_config() -> void:
	var config_path = "res://level_data/game_config.json"
	var config = load_json(config_path)
	if config:
		create_level(config)

# Save level data
func save_level(level_data: Dictionary, file_path: String) -> void:
	var json_string = json_to_string(level_data, true)
	var file = File.new()
	if file.open(file_path, File.WRITE) != OK:
		push_error("LevelManager: Failed to save level to {}".format(file_path))
	file.store_string(json_string)
	file.close()

# Load and apply save data
func load_level_from_save(file_path: String) -> void:
	var file = File.new()
	if file.open(file_path, File.READ) != OK:
		push_error("LevelManager: Failed to open save file {}".format(file_path))
	file.close()
	return

# Utility: Load JSON file
func load_json(file_path: String) -> Dictionary:
	var file = File.new()
	if file.open(file_path, File.READ) != OK:
		print("🔥 Error loading {}: {}".format(file_path, error_string(file.get_last_error())))
		return {}
	
	var error = file.get_error()
	if error != OK:
		print("🔥 Error reading {}: {}".format(file_path, error_string(error)))
		return {}
	
	file.close()
	
	print("🗺️ Loading level from: {}".format(file_path))
	var json_string = file.get_as_string()
	return json_parse(json_string)