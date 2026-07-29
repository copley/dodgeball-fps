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
@onready var performance_diagnostics_label: Label = $UI/PerformanceDiagnostics
@onready var pause_overlay: Control = $UI/PauseOverlay
@onready var pause_panel: VBoxContainer = $UI/PauseOverlay/PausePanel
@onready var controls_panel: VBoxContainer = $UI/PauseOverlay/ControlsPanel

var player: PlayerController
var ball: Dodgeball
var target: DodgeballTarget
var target_eliminated: bool = false
var gameplay_mouse_captured: bool = true
var diagnostics_seconds_until_update: float = 0.0
var frame_time_samples: Array[float] = []

const DIAGNOSTICS_UPDATE_INTERVAL: float = 0.25
const DIAGNOSTICS_ROLLING_SAMPLE_COUNT: int = 120


func _ready() -> void:
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.reset_to(player_spawn.global_transform)
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
	target.reset_to(target_spawn.global_transform)
	target.eliminated.connect(_on_target_eliminated)
	$UI/PauseOverlay/PausePanel/Resume.pressed.connect(close_pause_menu)
	$UI/PauseOverlay/PausePanel/RestartRound.pressed.connect(_on_menu_restart)
	$UI/PauseOverlay/PausePanel/Controls.pressed.connect(_show_controls)
	$UI/PauseOverlay/PausePanel/QuitGame.pressed.connect(get_tree().quit)
	$UI/PauseOverlay/ControlsPanel/Back.pressed.connect(_show_pause_options)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_update_performance_diagnostics()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_performance"):
		performance_diagnostics_label.visible = not performance_diagnostics_label.visible
		get_viewport().set_input_as_handled()
		return
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


func _process(delta: float) -> void:
	frame_time_samples.push_back(delta * 1000.0)
	if frame_time_samples.size() > DIAGNOSTICS_ROLLING_SAMPLE_COUNT:
		frame_time_samples.pop_front()
	diagnostics_seconds_until_update -= delta
	if diagnostics_seconds_until_update <= 0.0:
		_update_performance_diagnostics()
		diagnostics_seconds_until_update = DIAGNOSTICS_UPDATE_INTERVAL


func _update_performance_diagnostics() -> void:
	var current_frame_time_ms: float = (
		float(frame_time_samples.back())
		if not frame_time_samples.is_empty()
		else Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	)
	var average_frame_time_ms := 0.0
	var maximum_frame_time_ms := 0.0
	for sample: float in frame_time_samples:
		average_frame_time_ms += sample
		maximum_frame_time_ms = maxf(maximum_frame_time_ms, sample)
	if frame_time_samples.is_empty():
		average_frame_time_ms = current_frame_time_ms
		maximum_frame_time_ms = current_frame_time_ms
	else:
		average_frame_time_ms /= frame_time_samples.size()
	performance_diagnostics_label.text = (
		(
			"FPS: %d\nFrame: %.2f ms\nAverage: %.2f ms\nMaximum: %.2f ms"
			+ "\nPhysics: %.2f ms\nDraw calls: %d\nObjects: %d"
		)
		% [
			Engine.get_frames_per_second(),
			current_frame_time_ms,
			average_frame_time_ms,
			maximum_frame_time_ms,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
			int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		]
	)


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
