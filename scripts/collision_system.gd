## Collision Manager
## Central tile queries for bombs, explosions and movement, plus item drops
## from destroyed bricks.

class_name CollisionManager
extends Node

const ITEM_DROP_CHANCE := 0.25

signal tile_destroyed(tile_position: Vector2i)

var level_manager: LevelManager = null
var world: Node2D = null
var power_up_manager: PowerUpManager = null

func setup(p_level_manager: LevelManager, p_world: Node2D, p_power_up_manager: PowerUpManager) -> void:
	level_manager = p_level_manager
	world = p_world
	power_up_manager = p_power_up_manager

func is_inside_bounds(cell: Vector2i) -> bool:
	return level_manager != null and level_manager.is_inside_bounds(cell)

func is_solid(cell: Vector2i) -> bool:
	if level_manager == null:
		return true
	return level_manager.is_solid_cell(cell)

func is_destructible(cell: Vector2i) -> bool:
	if level_manager == null:
		return false
	return level_manager.is_brick_cell(cell)

func is_walkable(cell: Vector2i) -> bool:
	if level_manager == null:
		return false
	return level_manager.is_walkable_cell(cell)

func can_place_bomb(cell: Vector2i) -> bool:
	return is_walkable(cell) and get_bomb_at(cell) == null

func get_bomb_at(cell: Vector2i) -> Node:
	if level_manager == null:
		return null
	var bombs := get_tree().get_nodes_in_group("bombs")
	for bomb in bombs:
		if bomb is Node2D and level_manager.position_to_cell(bomb.global_position) == cell:
			return bomb
	return null

func destroy_tile(cell: Vector2i) -> bool:
	if not is_destructible(cell):
		return false
	level_manager.clear_tile(cell)
	tile_destroyed.emit(cell)
	_maybe_spawn_item(cell)
	return true

func _maybe_spawn_item(cell: Vector2i) -> void:
	if world == null:
		return
	if randf() >= ITEM_DROP_CHANCE:
		return
	var roll := randf()
	var item_type: EnergyItem.ItemType
	if roll < 0.5:
		item_type = EnergyItem.ItemType.ENERGY
	elif roll < 0.75:
		item_type = EnergyItem.ItemType.BOMB
	else:
		item_type = EnergyItem.ItemType.FIRE
	var item := EnergyItem.create(item_type)
	item.power_up_manager = power_up_manager
	item.position = level_manager.cell_to_position(cell)
	world.add_child(item)
