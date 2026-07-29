extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const BALL_SCENE: PackedScene = preload("res://scenes/ball.tscn")

@onready var player_spawn: Marker3D = $Court/SpawnMarkers/PlayerSpawn
@onready var ball_spawn: Marker3D = $Court/SpawnMarkers/BallSpawn

var ball: Dodgeball


func _ready() -> void:
	var player: PlayerController = PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_transform = player_spawn.global_transform
	player.pickup_requested.connect(_on_pickup_requested)

	ball = BALL_SCENE.instantiate()
	add_child(ball)
	ball.reset_to(ball_spawn.global_transform)


func _on_pickup_requested(player: PlayerController) -> void:
	if player.can_pick_up(ball):
		player.give_ball(ball)
