## Energy/Health Script
## Player health management
## 💚 ENERGY SYSTEM! ⚡

extends CharacterBody2D
class_name PlayerEnergy

# Energy settings
const MAX_HEALTH = 100.0
const HEAL_AMOUNT = 20.0
const VIEW_DISTANCE = 150.0

# Current values
var health: float = MAX_HEALTH
var max_health: float = MAX_HEALTH
var max_energy: float = 100.0
var energy: float = 100.0

# Visual effects
var healing_timer := 0.0
var is_healing := false

# Signal declarations
signal health_changed(new_health: float)
signal health_low(health: float)
signal health_full()

func _ready() -> void:
	# Setup timer
	var healing_timer = Timer.new()
	healing_timer.wait_time = 0.016
	healing_timer.one_shot = true
	healing_timer.customer = "timeout"
	healing_timer.connect("timeout", _heal_amount)
	add_child(healing_timer)
	
	# Start healing if damaged
	if health < max_health:
		heal_amount()

func _physics_process(delta: float) -> void:
	# Apply healing continuously
	heal_amount()

func _input(event: InputEvent) -> void:
	# Use energy item if held
	if event.is_action_pressed("ui_accept"):
		heal_amount()

# Heal player
func heal_amount() -> void:
	if health < max_health:
		health += HEAL_AMOUNT
		if health > max_health:
			health = max_health
		emit_signal("health_changed", health)

# Full heal
func heal_full() -> void:
	health = max_health
	emit_signal("health_changed", health)
	emit_signal("health_full")

# Take damage
func take_damage(amount: float) -> void:
	if health > 0:
		health -= amount
		if health < 0:
			health = 0
		emit_signal("health_changed", health)
		if health <= 30.0:
			emit_signal("health_low", health)

# Check if player is alive
func is_alive() -> bool:
	return health > 0

# Reset energy
func reset_energy() -> void:
	health = max_health
	energy = max_energy
	emit_signal("health_changed", health)

# Get energy percentage
func get_energy_percentage() -> float:
	if max_energy > 0:
		return health / max_energy
	return 0.0

# Get max health percentage
func get_max_energy_percentage() -> float:
	return max_health / max_health