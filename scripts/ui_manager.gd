## UI Manager Script
## Score, health, timer, game over screen
## 🎨 UI CONTROLLER! 🎯

extends CanvasLayer
class_name UIManager

# UI Nodes
@onready var score_label: Label = $UI/HUD/ScoreLabel
@onready var lives_label: Label = $UI/HUD/LivesLabel
@onready var timer_label: Label = $UI/HUD/TimerLabel
@onready var game_over_panel: ColorRect = $UI/GameOverPanel/ColorRect
@onready var game_over_label: Label = $UI/GameOverPanel/GameOverLabel
@onready var restart_button: Button = $UI/GameOverPanel/RestartButton

# References
@onready var game_state_manager: GameStateManager = $UI/GameStateManager

var is_paused := false

func _ready() -> void:
	# Setup UI nodes
	setup_labels()
	setup_buttons()
	
	# Start with blank panels
	hide_game_over()
	
	# Connect state changes
	if game_state_manager:
		game_state_manager.state_changed.connect(_on_state_changed)
		game_state_manager.score_changed.connect(_on_score_changed)
		game_state_manager.lives_changed.connect(_on_lives_changed)
		game_state_manager.game_ended.connect(_on_game_ended)

# Setup score and health labels
func setup_labels() -> void:
	if score_label:
		score_label.text = "Score: 0"
	if lives_label:
		lives_label.text = "Lives: 3"
	if timer_label:
		timer_label.text = "Time: 60"

# Setup restart button
func setup_buttons() -> void:
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)

# Show game over screen
func show_game_over(message: String = "GAME OVER") -> void:
	if game_over_panel:
		game_over_panel.visible = true
	if game_over_label:
		game_over_label.text = message

# Hide game over screen
func hide_game_over() -> void:
	if game_over_panel:
		game_over_panel.visible = false
	if restart_button:
		restart_button.visible = false

func _on_state_changed(state: GameStateManager.GameState) -> void:
	match state:
		GameStateManager.GameState.MENU:
			if game_over_panel:
				game_over_panel.visible = false
			if game_over_label:
				game_over_label.text = "BOMBERMAN"
			if restart_button:
				restart_button.visible = true

		GameStateManager.GameState.PLAYING:
			if game_over_panel:
				game_over_panel.visible = false
			if restart_button:
				restart_button.visible = false

		GameStateManager.GameState.PAUSED:
			if game_over_panel:
				game_over_panel.visible = true
			if game_over_label:
				game_over_label.text = "PAUSED"

		GameStateManager.GameState.GAME_OVER:
			if game_over_panel:
				game_over_panel.visible = true
			if game_over_label:
				game_over_label.text = "GAME OVER"

			if restart_button:
				restart_button.visible = true

		GameStateManager.GameState.VICTORY:
			if game_over_panel:
				game_over_panel.visible = true
			if game_over_label:
				game_over_label.text = "VICTORY! 🎉"

func _on_score_changed(score: int) -> void:
	if score_label:
		score_label.text = "Score: {}".format(score)

func _on_lives_changed(lives: int) -> void:
	if lives_label:
		lives_label.text = "Lives: {}".format(lives)

# Re-enable UI
func enable_ui() -> void:
	is_paused = false
	_hide_game_over_panel()

func _hide_game_over_panel() -> void:
	if game_over_panel:
		game_over_panel.visible = false

func _on_restart_pressed() -> void:
	# Restart game - emit signal to main scene
	pass