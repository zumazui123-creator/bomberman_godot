## Main scene
## Wires all systems together: game state, level, player, bombs, UI.
## Everything is built in code so the scene stays a single root node.

extends Node2D

var power_up_manager: PowerUpManager
var collision_manager: CollisionManager
var bomb_rules: BombCollisionHandler
var level_manager: LevelManager
var game_loop: GameLoop
var ui_manager: UIManager
var player: BombermanPlayer

func _ready() -> void:
	power_up_manager = PowerUpManager.new()
	add_child(power_up_manager)

	level_manager = LevelManager.new()
	add_child(level_manager)

	collision_manager = CollisionManager.new()
	add_child(collision_manager)

	bomb_rules = BombCollisionHandler.new()
	add_child(bomb_rules)

	collision_manager.setup(level_manager, self, power_up_manager)
	bomb_rules.setup(collision_manager)

	ui_manager = UIManager.new()
	add_child(ui_manager)

	player = BombermanPlayer.create()
	add_child(player)
	player.setup(level_manager, collision_manager, bomb_rules, power_up_manager, self)

	game_loop = GameLoop.new()
	add_child(game_loop)
	game_loop.level_manager = level_manager
	game_loop.ui_manager = ui_manager
	game_loop.player = player
	game_loop.power_up_manager = power_up_manager

	GameStateManager.start_game()
	game_loop.start_level(0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameStateManager.is_playing():
			GameStateManager.pause_game()
		elif GameStateManager.is_paused():
			GameStateManager.resume_game()
	elif event.is_action_pressed("ui_accept"):
		match GameStateManager.current_state:
			GameStateManager.GameState.GAME_OVER, GameStateManager.GameState.VICTORY:
				game_loop.restart_game()
			_:
				pass
