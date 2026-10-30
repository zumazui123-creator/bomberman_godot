## Player Controller
## Grid-based N64-style movement, bomb placement, invincibility frames,
## damage handling and respawn.

extends CharacterBody2D
class_name BombermanPlayer

const SPRITE_PATH := "res://Assets/Player/Red/player_03.png"
const SPRITE_DEAD_PATH := "res://Assets/Player/Red/dead.png"
const SPRITE_SCALE := 0.22

const BOMB_PLACE_COOLDOWN := 0.25
const RESPAWN_DELAY := 1.2
const RESPAWN_INVINCIBILITY := 2.0

signal bomb_dropped(bomb: BomberBomb)
signal player_died

var level_manager: LevelManager = null
var collision_manager: CollisionManager = null
var bomb_rules: BombCollisionHandler = null
var power_up_manager: PowerUpManager = null
var world: Node2D = null

var move_speed := 140.0
var max_bombs := 1
var bomb_radius := 1

var _invincible_time := 0.0
var _last_bomb_drop := -10.0
var _dead := false
var _sprite: Sprite2D
var _camera: Camera2D
var _live_texture: Texture2D = null

static func create() -> BombermanPlayer:
	var player := BombermanPlayer.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20.0, 20.0)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	player.add_child(collision)
	var sprite := Sprite2D.new()
	if ResourceLoader.exists(SPRITE_PATH):
		sprite.texture = load(SPRITE_PATH)
		player._live_texture = sprite.texture
	sprite.scale = Vector2.ONE * SPRITE_SCALE
	player.add_child(sprite)
	player._sprite = sprite
	var camera := Camera2D.new()
	camera.position = Vector2(0.0, -40.0)
	camera.zoom = Vector2.ONE * 1.2
	player.add_child(camera)
	player._camera = camera
	return player

func setup(
	p_level_manager: LevelManager,
	p_collision_manager: CollisionManager,
	p_bomb_rules: BombCollisionHandler,
	p_power_up_manager: PowerUpManager,
	p_world: Node2D
) -> void:
	level_manager = p_level_manager
	collision_manager = p_collision_manager
	bomb_rules = p_bomb_rules
	power_up_manager = p_power_up_manager
	world = p_world
	_sync_powerups()

func _ready() -> void:
	add_to_group("player")
	_sync_powerups()

func _sync_powerups() -> void:
	if power_up_manager:
		move_speed = power_up_manager.move_speed
		max_bombs = power_up_manager.max_bombs
		bomb_radius = power_up_manager.bomb_radius

func _physics_process(_delta: float) -> void:
	if _dead or level_manager == null:
		return
	if not GameStateManager.is_playing():
		velocity = Vector2.ZERO
		return
	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if input_dir != Vector2.ZERO:
		# Axis-locked movement (classic feel), horizontal wins when both pressed.
		if input_dir.x != 0.0:
			input_dir = Vector2(signf(input_dir.x), 0.0)
		else:
			input_dir = Vector2(0.0, signf(input_dir.y))
		velocity = input_dir * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_snap_to_grid()
	if Input.is_action_just_pressed("drop_bomb"):
		place_bomb()

func _snap_to_grid() -> void:
	var tile := float(level_manager.TILE_SIZE)
	var nearest := Vector2i(
		int(roundf(position.x / tile)),
		int(roundf(position.y / tile))
	)
	if level_manager.is_walkable_cell(nearest):
		position = level_manager.cell_to_position(nearest)

## Drops a bomb on the tile the player is standing on.
func place_bomb() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_bomb_drop < BOMB_PLACE_COOLDOWN:
		return
	var cell := level_manager.position_to_cell(global_position)
	if not collision_manager.can_place_bomb(cell):
		return
	if get_tree().get_nodes_in_group("bombs").size() >= max_bombs:
		return
	_last_bomb_drop = now
	var bomb := BomberBomb.new()
	bomb.bomb_radius = bomb_radius
	bomb.owner_player = self
	if world:
		world.add_child(bomb)
	bomb.position = level_manager.cell_to_position(cell)
	bomb.setup(level_manager, collision_manager, bomb_rules)
	bomb_dropped.emit(bomb)

## Called by enemies (contact) and bombs. `source` lets bombs owned by this
## player be lenient: your own explosion never kills you.
func take_damage(_damage: float = 1.0, source: Node2D = null) -> void:
	if _dead or _invincible_time > 0.0:
		return
	if source is BomberBomb and (source as BomberBomb).owner_player == self:
		return
	_die()

func _die() -> void:
	_dead = true
	velocity = Vector2.ZERO
	player_died.emit()
	if _sprite:
		if ResourceLoader.exists(SPRITE_DEAD_PATH):
			_sprite.texture = load(SPRITE_DEAD_PATH)
		visible = false
	if _camera:
		_camera.enabled = false
	var game_ended := GameStateManager.lose_life()
	if game_ended:
		return
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if not GameStateManager.is_playing():
		return
	_respawn()

func _respawn() -> void:
	reset()
	position = level_manager.player_spawn_point

## Public revive: used on level start and game restart.
func reset() -> void:
	_dead = false
	velocity = Vector2.ZERO
	_invincible_time = RESPAWN_INVINCIBILITY
	visible = true
	if _sprite:
		if _live_texture:
			_sprite.texture = _live_texture
	if _camera:
		_camera.enabled = true

func is_dead() -> bool:
	return _dead

func _process(delta: float) -> void:
	if _invincible_time <= 0.0:
		return
	_invincible_time -= delta
	modulate.a = 0.5 if fmod(_invincible_time, 0.25) < 0.125 else 1.0
	if _invincible_time <= 0.0:
		modulate.a = 1.0
