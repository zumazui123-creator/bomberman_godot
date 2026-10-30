## Game State Manager (Autoload: GameStateManager)
## Central game state machine: MENU / PLAYING / PAUSED / GAME_OVER / VICTORY

extends Node

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER, VICTORY }

signal state_changed(new_state: GameState)
signal score_changed(new_score: int)
signal lives_changed(remaining_lives: int)
signal game_ended(ended_state: GameState)

var current_state: GameState = GameState.MENU
var score: int = 0
var lives: int = 3
var level_index: int = 0

func _ready() -> void:
	set_state(GameState.MENU)

func start_game() -> void:
	score = 0
	lives = 3
	level_index = 0
	score_changed.emit(score)
	lives_changed.emit(lives)
	set_state(GameState.PLAYING)

func set_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(current_state)

func is_playing() -> bool:
	return current_state == GameState.PLAYING

func is_paused() -> bool:
	return current_state == GameState.PAUSED

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		set_state(GameState.PAUSED)

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		set_state(GameState.PLAYING)

func trigger_game_over() -> void:
	if current_state == GameState.PLAYING:
		set_state(GameState.GAME_OVER)
		game_ended.emit(current_state)

func trigger_victory() -> void:
	if current_state == GameState.PLAYING:
		set_state(GameState.VICTORY)
		game_ended.emit(current_state)

func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

## Returns true when the game ended because no lives are left.
func lose_life() -> bool:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		trigger_game_over()
		return true
	return false

func next_level() -> void:
	level_index += 1
