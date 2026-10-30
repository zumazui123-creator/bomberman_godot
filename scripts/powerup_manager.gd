## Power Up Manager
## Player upgrades: more bombs, bigger fire, more speed.
## Pure data/state - the player reads these values, bricks drop the items.

class_name PowerUpManager
extends Node

signal power_up_applied(kind: String)

const MAX_BOMBS_CAP := 3
const MAX_FIRE_CAP := 3
const MAX_SPEED_CAP := 220.0

var max_bombs := 1
var bomb_radius := 1
var move_speed := 140.0

func reset() -> void:
	max_bombs = 1
	bomb_radius = 1
	move_speed = 140.0

func apply_bomb_upgrade() -> bool:
	if max_bombs >= MAX_BOMBS_CAP:
		return false
	max_bombs += 1
	power_up_applied.emit("bomb")
	return true

func apply_fire_upgrade() -> bool:
	if bomb_radius >= MAX_FIRE_CAP:
		return false
	bomb_radius += 1
	power_up_applied.emit("fire")
	return true

func apply_speed_upgrade() -> bool:
	if move_speed >= MAX_SPEED_CAP:
		return false
	move_speed += 20.0
	power_up_applied.emit("speed")
	return true
