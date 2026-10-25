## Powerup/Item Manager Script
## Health potions, bomb upgrades, weapon boosts
## 🎁 POWERUPS! ⚡

extends Node2D
class_name PowerupManager

# Powerup types
enum PowerupType { HEALTH, BOMB, EXPLOSION, SPEED, TIME, FLIGHT }

# Powerup data
var active_powerups: Dictionary = {}
var collected_powerups: Array[PowerupType] = []

# References
@onready var explosions_manager: ExplosionManager = $ExplosionsManager
@onready var particles_manager: ParticlesManager = $ParticlesManager
@onready var camera: Camera2D = get_tree().get_first_node_in_group("camera")

signal powerup_pickup(powerup_type: PowerupType)
signal health_changed(health: int)
signal bomb_count_changed(bomb_count: int)
signal explosion_radius_changed(radius: int)

func _ready() -> void:
	# Setup default powerups
	_setup_explosions_manager()
	_setup_particles_manager()

# Setup explosions manager
func _setup_explosions_manager() -> void:
	if explosions_manager:
		explosions_manager.setup_bomb_count(9)
		explosions_manager.setup_explosion_radius(3.0)

# Setup particles manager
func _setup_particles_manager() -> void:
	if particles_manager:
		particles_manager.setup_particles()

# Add powerup at position
func add_powerup(powerup_type: PowerupType, position: Vector2) -> void:
	active_powerups[powerup_type] = {
		"position": position,
		"active": true
	}

# Remove powerup
func remove_powerup(powerup_type: PowerupType) -> void:
	if active_powerups.has(powerup_type):
		active_powerups[powerup_type]["active"] = false

# Get powerup at position
func get_powerup_at_position(position: Vector2) -> PowerupType:
	for powerup_type in PowerupType:
		if active_powerups.has(powerup_type):
			var powerup_data = active_powerups[powerup_type]
			if powerup_data["active"] and position.distance_to(powerup_data["position"]) < 32:
				return powerup_type
	return PowerupType.HEALTH

# Collect powerup
func collect_powerup(powerup_type: PowerupType) -> bool:
	if not active_powerups.has(powerup_type):
		return false
	
	active_powerups[powerup_type]["active"] = false
	collected_powerups.append(powerup_type)
	powerup_pickup.emit(powerup_type)

# Apply effect to player
func apply_powerup_to_player(player: CharacterBody2D) -> void:
	match collected_powerups.back():
		PowerupType.HEALTH:
			player.health = min(player.max_health + 1, 100)
			health_changed.emit(player.health)
		
		PowerupType.BOMB:
			player.max_bombs = 9
			bomb_count_changed.emit(player.max_bombs)
		
		PowerupType.EXPLOSION:
			player.explosion_radius = 4
			explosion_radius_changed.emit(player.explosion_radius)
		
		PowerupType.SPEED:
			player.speed *= 1.5
			if player:
				player.velocity.x = min(player.velocity.x * 1.5, player.max_speed)

# Create explosion at position with powerup effect
func create_powerup_explosion(position: Vector2, color: Color = Color.RED) -> void:
	var explosion = preset_explosion(position, color)
	if "explosions_manager" in globals() and explosions_manager:
		explosions_manager.explosions.append(explosion)
	elif camera:
	.camera.add_child(explosion)

# Clear all powerups
func clear_powerups() -> void:
	for powerup_type in PowerupType:
		remove_powerup(powerup_type)

# Reset powerups
func reset_powerups() -> void:
	active_powerups.clear()
	collected_powerups.clear()