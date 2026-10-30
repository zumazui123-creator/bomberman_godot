## Bomb Rules
## Explosion propagation: walks from a bomb's origin outward in one
## direction, destroying bricks along the way and collecting the affected
## cells. The walk stops at the first indestructible wall (or out of bounds)
## or when the radius is exhausted. Bricks are destroyed but do NOT stop
## the blast (classic behavior).

class_name BombCollisionHandler
extends Node

const DIRECTIONS := [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]

var collision_manager: CollisionManager = null

func setup(p_collision_manager: CollisionManager) -> void:
	collision_manager = p_collision_manager

## Returns the ordered list of cells a blast of `radius` tiles covers in
## `direction`, starting from `origin` (the bomb's own cell).
func propagate_explosion(origin: Vector2i, direction: Vector2i, radius: int) -> Array[Vector2i]:
	var affected: Array[Vector2i] = []
	if collision_manager == null:
		return affected
	var cell := origin + direction
	for _i in range(radius):
		if not collision_manager.is_inside_bounds(cell):
			break
		if collision_manager.is_solid(cell) and not collision_manager.is_destructible(cell):
			break
		if collision_manager.is_destructible(cell):
			collision_manager.destroy_tile(cell)
		affected.append(cell)
		cell += direction
	return affected
