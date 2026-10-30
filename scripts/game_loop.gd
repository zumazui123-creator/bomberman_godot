## Game Loop
## Countdown timer, win/lose checks, level progression and restart.

extends Node
class_name GameLoop

const TIME_LIMIT := 120.0
const LEVEL_BONUS := 250

signal time_updated(seconds_remaining: int)

var level_manager: LevelManager = null
var ui_manager: UIManager = null
var player: BombermanPlayer = null
var power_up_manager: PowerUpManager = null

var time_remaining := TIME_LIMIT
var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.timeout.connect(_on_tick)
	add_child(_timer)
	GameStateManager.state_changed.connect(_on_state_changed)

func start_level(level_index: int) -> void:
	if level_manager == null:
		return
	level_manager.load_level(level_index)
	GameStateManager.level_index = level_index
	time_remaining = TIME_LIMIT
	if player:
		player.reset()
		player.position = level_manager.player_spawn_point
	if ui_manager:
		ui_manager.update_time(int(ceilf(time_remaining)))
		ui_manager.update_level(level_index + 1)
	_on_state_changed(GameStateManager.current_state)

func restart_game() -> void:
	if power_up_manager:
		power_up_manager.reset()
	GameStateManager.start_game()
	start_level(0)

func _process(_delta: float) -> void:
	if not GameStateManager.is_playing() or level_manager == null:
		return
	if not level_manager.get_alive_enemies().is_empty():
		return
	# All enemies destroyed: level complete.
	if level_manager.has_next_level():
		GameStateManager.add_score(LEVEL_BONUS)
		start_level(level_manager.current_level_index + 1)
	else:
		GameStateManager.trigger_victory()

func _on_tick() -> void:
	if not GameStateManager.is_playing() or level_manager == null:
		_timer.stop()
		return
	time_remaining -= 1.0
	var display := int(ceilf(time_remaining))
	if ui_manager:
		ui_manager.update_time(display)
	time_updated.emit(display)
	if time_remaining <= 0.0:
		_timer.stop()
		GameStateManager.trigger_game_over()

func _on_state_changed(state: int) -> void:
	match state:
		GameStateManager.GameState.PLAYING:
			_timer.start()
		_:
			_timer.stop()
