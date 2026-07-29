extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const BALL_SCENE: PackedScene = preload("res://scenes/ball.tscn")
const TARGET_SCENE: PackedScene = preload("res://scenes/target.tscn")

@onready var player_spawn: Marker3D = $Court/SpawnMarkers/PlayerSpawn
@onready var ball_spawn: Marker3D = $Court/SpawnMarkers/BallSpawn
@onready var target_spawn: Marker3D = $Court/SpawnMarkers/TargetSpawn
@onready var round_result_label: Label = $UI/RoundResult
@onready var catch_feedback_label: Label = $UI/CatchFeedback

var player: PlayerController
var ball: Dodgeball
var target: DodgeballTarget
var target_eliminated: bool = false


func _ready() -> void:
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_transform = player_spawn.global_transform
	player.pickup_requested.connect(_on_pickup_requested)
	player.catch_requested.connect(_on_catch_requested)
	player.catch_window_changed.connect(_on_catch_window_changed)
	player.catch_succeeded.connect(_on_catch_succeeded)
	player.eliminated.connect(_on_player_eliminated)

	ball = BALL_SCENE.instantiate()
	add_child(ball)
	ball.reset_to(ball_spawn.global_transform)
	ball.valid_hit.connect(_on_ball_valid_hit)
	ball.valid_player_hit.connect(_on_ball_valid_player_hit)

	target = TARGET_SCENE.instantiate()
	add_child(target)
	target.global_transform = target_spawn.global_transform
	target.eliminated.connect(_on_target_eliminated)

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
