## Explosion Scene Script
## Creates shockwave with particle effects & tile destruction
## 💥 PURE FIRE & DESTRUCTION! 🔥

extends Area2D
class_name Explosion

var explosion_duration = 0.5
var tiles_to_destroy = []
var shockwave_radius = 3.0
var shockwave_direction = Vector2.DOWN
var explosion_center = Vector2.ZERO

# Tile reference - assume TileMapLayer as child
@onready var tile_map_layer = $TileMapLayer
const TILE_SIZE = 32.0

# Animation variant for explosion size
enum ExplosionStage {
	STAGE1 = 0,  # Initial explosion
	STAGE2 = 1,  # Max size
	STAGE3 = 2   # Dissipate
}
@onready var animation_player = $AnimationPlayer

func _ready() -> void:
	@onready var timer = $Timer
	if timer:
		timer.wait_time = explosion_duration
		timer.start()
	
	# Start explosion animation
	if animation_player and animation_player.has_animation("explosion"):
		animation_player.play("explosion")

func _process(delta: float) -> void:
	# Visual pulsing/shrinking
	if visible and animation_player:
		var current_scale = transform.scale
		if current_scale.x > 0.5:
			current_scale.x -= delta * 2.0
			current_scale.y -= delta * 2.0
			transform.scale = current_scale

func _on_timer_timeout() -> void:
	# Explosion complete - check for remaining tiles to destroy
	if not tiles_to_destroy.is_empty():
		var duration = explosion_duration + 0.2
		await get_tree().create_timer(duration).timeout
		_process_remaining_tiles()
	
	queue_free()

# Check all tiles within shockwave radius
func check_collisions(center: Vector2) -> void:
	explosion_center = center
	
	if not tile_map_layer:
		push_error("Explosion: TileMapLayer not found!")
		return
	
	# Get collision layer mask (adjust for your tilemap layers)
	var collision_mask = 1
	
	# Check all directions
	for dir in directions():
		_check_tiles_in_direction(dir, collision_mask)

func directions() -> Array:
	return [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

# Check tiles in a specific direction
func _check_tiles_in_direction(direction: Vector2, collision_mask: int) -> void:
	var check_position = explosion_center + direction * shockwave_radius * TILE_SIZE
	
	# Query for tiles in this direction
	var result = tile_map_layer.get_used_cells_in_rect(
		Rect2(check_position.x - TILE_SIZE, check_position.y - TILE_SIZE, TILE_SIZE * 2, TILE_SIZE * 2)
	)
	
	for pos in result:
		handle_tile(pos, collision_mask)

# Handle a tile that might be destroyed
func handle_tile(tile_pos: Vector2i, collision_mask: int) -> void:
	var tile_layer = tile_map_layer.get_layer(0)
	if not tile_layer:
		return
	
	for cell in tile_layer.get_used_cells():
		if cell == tile_pos:
			# Get tile properties
			var prop_key = tile_layer.get_cell_key(cell)
			var tile_data = tile_layer.get_cell_value(cell)
			
			# Check if tile is destructible
			if tile_data != 0 and is_destructible(tile_data):
				var closest_tile = TileMap.cell_to_rect(cell)
				_destroy_tile(tile_data, closest_tile)

func is_destructible(tile_id: int) -> bool:
	# Define destructible tile IDs (adjust for your game)
	return tile_id in [1, 2, 3]  # Wall, Bricks, Wood - add your destructible tiles here

# Mark tile for destruction list
func destroy_tile(tile_data: int, tile_rect: Rect2) -> void:
	if tiles_to_destroy.has(tile_data, tile_rect):
		return
	
	tiles_to_destroy.append(tile_data, tile_rect)
	_destroy_tile(tile_data, tile_rect)

# Actually destroy a tile
func _destroy_tile(tile_data: int, tile_rect: Rect2) -> void:
	var count = tiles_to_destroy.erase(tile_data, tile_rect)
	
	if count > 0 and tile_map_layer:
		# Create particle effect
		if has_node("Particles"):
			var particles = $Particles.current_particle_count > 0
			if particles:
				$Particles.restart()
		
		# Update tilemap to break tile
		var tile_layer = tile_map_layer.get_layer(0)
		if tile_layer:
			tile_layer.replace_cell(tile_rect.position.x, tile_rect.position.y, 0)

# REMOVED DUPLICATE _process function - already defined at line 36
# REMOVED DUPLICATE _on_timer_timeout - already defined at line 45
# REMOVED DUPLICATE directions(), destroy_tile() - already defined earlier
