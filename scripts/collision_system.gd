## Collision System Script
## Central collision management for bombs, explosions, and player
## 🛡️ SHIELD OF LOGIC! 💥✅

class_name CollisionManager
extends Node2D

signal collision_processed(collision_data)
signal tile_destroyed(tile_position)
signal bomb_hits_player(player)

# Collision layer masks
const LAYER_FLOOR = 1 << 0
const LAYER_WALL = 1 << 1
const LAYER_DESTRUCTIBLE = 1 << 2
const LAYER_ENEMY = 1 << 3
const LAYER_PLAYER = 1 << 4
const LAYER_COVERS = 1 << 5

# Collision groups
group("collision_floor")
group("collision_wall")
group("collision_destructible")
group("collision_enemy")
group("collision_player")
group("collision_cover")

# Tilemap reference
@onready var tile_map = $TileMapLayer

# Current collision mask for area bodies
var current_collision_mask := LAYER_FLOOR | LAYER_WALL | LAYER_DESTRUCTIBLE

func _ready() -> void:
	# Initialize collision groups
	setup_collision_layers()

# Setup collision layers from tilemap
func setup_collision_layers() -> void:
	if not tile_map:
		push_error("CollisionManager: TileMapLayer not found!")
		return

	# Get tile layers
	var floor_layer = tile_map.get_layer(0)
	var wall_layer = tile_map.get_layer(1)

	# Set collision masks based on layer cell values
	for cell in floor_layer.get_used_cells():
		var layer_value = floor_layer.get_cell_value(cell)
		# Assign floor collision mask based on layer value
		# Adjust layer values to match your game design
		set_collision_layer_value(LAYER_FLOOR, false)

	for cell in wall_layer.get_used_cells():
		var layer_value = wall_layer.get_cell_value(cell)
		set_collision_layer_value(LAYER_WALL, layer_value != 0)

# Check if position is solid at world position
func is_solid(position: Vector2, collision_mask: int = LAYER_FLOOR | LAYER_WALL) -> bool:
	if not tile_map:
		return false

	# Check floor collision
	if collision_mask & LAYER_FLOOR != 0:
		var floor_cells = tile_map.get_used_cells_in_rect(
			Rect2(position.x - 16, position.y - 16, 32, 32)
		)
		for cell in floor_cells:
			var layer = tile_map.get_layer(0)
			if layer.get_cell_value(cell) != 0:
				return true

	# Check wall collision
	if collision_mask & LAYER_WALL != 0:
		var wall_cells = tile_map.get_used_cells_in_rect(
			Rect2(position.x - 16, position.y - 16, 32, 32)
		)
		for cell in wall_cells:
			var layer = tile_map.get_layer(1)
			if layer.get_cell_value(cell) != 0:
				return true

	return false

# Check if tile is destructible
func is_tile_destructible(position: Vector2) -> bool:
	if not tile_map:
		return false
	var cells = tile_map.get_used_cells_in_rect(
		Rect2(position.x - 16, position.y - 16, 32, 32)
	)
	for cell in cells:
		var layer = tile_map.get_layer(0)
		if layer.get_cell_value(cell) in [2, 3, 4]:  # Destructible tile IDs
			return true
	return false

# Resolve collision for area body
func resolve_area_collision(area: Area2D) -> void:
	var positions = get_child(0).laser_pointlight.laser_test()
	for pos in positions:
		if is_solid(pos, current_collision_mask):
			# Create Impulse
			var impulse = Impulse2D.new()
			impulse.transform = pos
			area.collision_layer = LAYER_FLOOR | LAYER_WALL
			area.collision_mask = current_collision_mask
			await get_tree().process_frame

# Process collision hit
func process_collision_hit(collision_data: Dictionary) -> void:
	collision_processed.emit(collision_data)

# Destroy tile at position
func destroy_tile_at_position(position: Vector2) -> void:
	if not tile_map:
		return

	var cell = tile_map.map_to_cell(position)
	if cell in tile_map.get_used_cells():
		var layer = tile_map.get_layer(0)
		var tile_id = layer.get_cell_value(cell)
		if tile_id in [2, 3, 4]:  # Destructible tiles
			tile_id = 0
			layer.set_cell_value(cell, tile_id)
			tile_destroyed.emit(cell)

# Get collision shape for testing
func get_collision_shape_at_position(position: Vector2) -> CollisionShape2D:
	if not tile_map:
		return null
	var cells = tile_map.get_used_cells_in_rect(
		Rect2(position.x - 16, position.y - 16, 32, 32)
	)
	if cells.is_empty():
		return null
	var cell = cells.front()
	var layer = tile_map.get_layer(0)
	return layer.get_cell_collision_id(cell)