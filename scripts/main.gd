extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const BALL_SCENE: PackedScene = preload("res://scenes/ball.tscn")
const TARGET_SCENE: PackedScene = preload("res://scenes/target.tscn")

@onready var player_spawn: Marker3D = $Court/SpawnMarkers/PlayerSpawn
@onready var ball_spawn: Marker3D = $Court/SpawnMarkers/BallSpawn
@onready var target_spawn: Marker3D = $Court/SpawnMarkers/TargetSpawn
@onready var round_result_label: Label = $UI/RoundResult
@onready var catch_feedback_label: Label = $UI/CatchFeedback
@onready var dodge_feedback_label: Label = $UI/DodgeFeedback
@onready var pause_overlay: Control = $UI/PauseOverlay
@onready var pause_panel: VBoxContainer = $UI/PauseOverlay/PausePanel
@onready var controls_panel: VBoxContainer = $UI/PauseOverlay/ControlsPanel

var player: PlayerController
var ball: Dodgeball
var target: DodgeballTarget
var target_eliminated: bool = false
var gameplay_mouse_captured: bool = true


func _ready() -> void:
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_transform = player_spawn.global_transform
	player.pickup_requested.connect(_on_pickup_requested)
	player.catch_requested.connect(_on_catch_requested)
	player.catch_window_changed.connect(_on_catch_window_changed)
	player.catch_succeeded.connect(_on_catch_succeeded)
	player.eliminated.connect(_on_player_eliminated)
	player.dodge_availability_changed.connect(_on_dodge_availability_changed)

	ball = BALL_SCENE.instantiate()
	add_child(ball)
	ball.reset_to(ball_spawn.global_transform)
	ball.valid_hit.connect(_on_ball_valid_hit)
	ball.valid_player_hit.connect(_on_ball_valid_player_hit)

	target = TARGET_SCENE.instantiate()
	add_child(target)
	target.global_transform = target_spawn.global_transform
	target.eliminated.connect(_on_target_eliminated)
	$UI/PauseOverlay/PausePanel/Resume.pressed.connect(close_pause_menu)
	$UI/PauseOverlay/PausePanel/RestartRound.pressed.connect(_on_menu_restart)
	$UI/PauseOverlay/PausePanel/Controls.pressed.connect(_show_controls)
	$UI/PauseOverlay/PausePanel/QuitGame.pressed.connect(get_tree().quit)
	$UI/PauseOverlay/ControlsPanel/Back.pressed.connect(_show_pause_options)
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		if get_tree().paused:
			close_pause_menu()
		else:
			open_pause_menu()
		get_viewport().set_input_as_handled()
		return
	if not get_tree().paused and event.is_action_pressed("restart_round"):
		restart_round()
		get_viewport().set_input_as_handled()


func open_pause_menu() -> void:
	pause_overlay.visible = true
	_show_pause_options()
	get_tree().paused = true
	gameplay_mouse_captured = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close_pause_menu() -> void:
	pause_overlay.visible = false
	get_tree().paused = false
	gameplay_mouse_captured = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _show_controls() -> void:
	pause_panel.visible = false
	controls_panel.visible = true


func _show_pause_options() -> void:
	pause_panel.visible = true
	controls_panel.visible = false


func _on_menu_restart() -> void:
	restart_round()
	close_pause_menu()


func restart_round() -> void:
	player.reset_to(player_spawn.global_transform)
	ball.reset_to(ball_spawn.global_transform)
	target.reset_to(target_spawn.global_transform)
	target_eliminated = false
	round_result_label.visible = false
	round_result_label.text = ""
	catch_feedback_label.visible = false
	catch_feedback_label.text = ""
	dodge_feedback_label.visible = false


func _on_dodge_availability_changed(available: bool) -> void:
	dodge_feedback_label.visible = not available

func _on_pickup_requested(player: PlayerController) -> void:
	if player.can_pick_up(ball):
		player.give_ball(ball)


func _on_catch_requested(catching_player: PlayerController) -> void:
	catching_player.catch_ball(ball)


func _on_ball_valid_hit(hit_target: DodgeballTarget) -> void:
	if hit_target == target:
		target.eliminate()


func _on_ball_valid_player_hit(hit_player: PlayerController) -> void:
	if hit_player == player:
		player.eliminate()


func _on_target_eliminated() -> void:
	if target_eliminated:
		return
	target_eliminated = true
	round_result_label.text = "TARGET ELIMINATED"
	round_result_label.visible = true


func _on_player_eliminated() -> void:
	round_result_label.text = "PLAYER ELIMINATED"
	round_result_label.visible = true


func _on_catch_window_changed(active: bool) -> void:
	catch_feedback_label.text = "CATCH WINDOW" if active else ""
	catch_feedback_label.visible = active


func _on_catch_succeeded() -> void:
	catch_feedback_label.text = "CAUGHT!"
	catch_feedback_label.visible = true
	await get_tree().create_timer(0.75).timeout
	if not player.is_catch_window_active():
		catch_feedback_label.visible = false
