## Game State Manager
## Handles menu, playing, paused, game over states
## 🎮 GAME STATE CONTROLLER! 🎯

extends Node2D
class_name GameStateManager

# Game states
enum GameState { MENU, PLAYING, PAUSED, GAME_OVER, VICTORY }

var current_state := GameState.MENU
var is_paused := false
var score := 0
var lives := 3
var time_remaining := 0

# Timer for countdown
var countdown_timer := Timer.new()

signal state_changed(new_state)
signal lives_changed(remaining_lives)
signal game_ended(ended_state)
signal score_changed(new_score)

func _ready() -> void:
	add_to_group("ui_manager")
	_start_game()
	countdown_timer.wait_time = 60.0
	countdown_timer.one_shot = true
	countdown_timer.connect("timeout", _on_game_over)
	add_child(countdown_timer)

func _start_game() -> void:
	current_state = GameState.PLAYING
	state_changed.emit(GameState.PLAYING)
	_time_start()

# Set game state
func set_state(state: GameState) -> void:
	current_state = state
	state_changed.emit(state)

func get_state() -> GameState:
	return current_state

# Start countdown timer
func _time_start() -> void:
	countdown_timer.start()
func _time_end() -> void:
	if current_state == GameState.PLAYING:
		countdown_timer.wait_time = 60.0
		countdown_timer.start()

# Handle time remaining
func _on_timer_timeout() -> void:
	if current_state == GameState.PLAYING:
		set_state(GameState.PAUSED)
		_on_game_over()

# Game over handler
func _on_game_over() -> void:
	state_changed.emit(GameState.GAME_OVER)
	game_ended.emit(GameState.GAME_OVER)

# Increase score
func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)

# Decrease lives
func decrease_lives() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		decrease_lives()
		decrease_lives()
		set_state(GameState.GAME_OVER)

# Is game in progress
func is_game_active() -> bool:
	return current_state == GameState.PLAYING

# Is game paused
func is_paused() -> bool:
	return is_paused

# Pause/Resume
func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		is_paused = true
		state_changed.emit(GameState.PAUSED)

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		is_paused = false
		state_changed.emit(GameState.PLAYING)

# Set victory state
func set_victory() -> void:
	state_changed.emit(GameState.VICTORY)
	game_ended.emit(GameState.VICTORY)
