extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const BALL_SCENE: PackedScene = preload("res://scenes/ball.tscn")
const TARGET_SCENE: PackedScene = preload("res://scenes/target.tscn")

@onready var player_spawn: Marker3D = $Court/SpawnMarkers/PlayerSpawn
@onready var ball_spawn: Marker3D = $Court/SpawnMarkers/BallSpawn
@onready var target_spawn: Marker3D = $Court/SpawnMarkers/TargetSpawn
@onready var round_result_label: Label = $UI/RoundResult

var ball: Dodgeball
var target: DodgeballTarget
var target_eliminated: bool = false


func _ready() -> void:
	var player: PlayerController = PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_transform = player_spawn.global_transform
	player.pickup_requested.connect(_on_pickup_requested)

	ball = BALL_SCENE.instantiate()
	add_child(ball)
	ball.reset_to(ball_spawn.global_transform)
	ball.valid_hit.connect(_on_ball_valid_hit)

	target = TARGET_SCENE.instantiate()
	add_child(target)
	target.global_transform = target_spawn.global_transform
	target.eliminated.connect(_on_target_eliminated)


func _on_pickup_requested(player: PlayerController) -> void:
	if player.can_pick_up(ball):
		player.give_ball(ball)


func _on_ball_valid_hit(hit_target: DodgeballTarget) -> void:
	if hit_target == target:
		target.eliminate()


func _on_target_eliminated() -> void:
	if target_eliminated:
		return
	target_eliminated = true
	round_result_label.text = "TARGET ELIMINATED"
	round_result_label.visible = true
