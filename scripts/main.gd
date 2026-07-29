extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")

@onready var player_spawn: Marker3D = $Court/SpawnMarkers/PlayerSpawn


func _ready() -> void:
	var player: CharacterBody3D = PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_transform = player_spawn.global_transform
