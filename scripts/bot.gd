class_name BotController
extends CharacterBody3D

signal eliminated
signal ball_thrown

enum BotState {
	SEEK_BALL,
	MOVE_TO_BALL,
	HOLD_BALL,
	AIM,
	THROW,
	WAIT_FOR_BALL,
	ELIMINATED,
}

@export var movement_speed: float = 5.0
@export var acceleration: float = 20.0
@export var pickup_range: float = 1.25
@export var aim_delay: float = 0.6
@export var throw_speed: float = 14.0
@export var throw_recovery_delay: float = 0.35
@export var target_height_offset: float = 1.1
@export var aim_error: float = 0.0

@onready var hold_position: Marker3D = $HoldPosition
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var mesh: MeshInstance3D = $MeshInstance3D

var state: int = BotState.SEEK_BALL
var ball: Dodgeball
var player: PlayerController
var held_ball: Dodgeball
var state_seconds_remaining: float = 0.0
var is_eliminated: bool = false
var is_active: bool = true
var gameplay_enabled: bool = true
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var active_material: Material


func _ready() -> void:
	active_material = mesh.material_override


func configure(game_ball: Dodgeball, human_player: PlayerController) -> void:
	ball = game_ball
	player = human_player


func _physics_process(delta: float) -> void:
	if not gameplay_enabled or not is_active or is_eliminated:
		velocity = Vector3.ZERO
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y <= 0.0:
		velocity.y = 0.0

	match state:
		BotState.SEEK_BALL:
			_stop_horizontal()
			if is_instance_valid(ball) and ball.is_available():
				transition_to(BotState.MOVE_TO_BALL)
		BotState.MOVE_TO_BALL:
			_move_to_ball(delta)
		BotState.HOLD_BALL:
			_stop_horizontal()
			transition_to(BotState.AIM)
		BotState.AIM:
			_stop_horizontal()
			_face_player()
			state_seconds_remaining = maxf(state_seconds_remaining - delta, 0.0)
			if state_seconds_remaining == 0.0:
				transition_to(BotState.THROW)
		BotState.THROW:
			_stop_horizontal()
			_throw_at_player()
			transition_to(BotState.WAIT_FOR_BALL)
		BotState.WAIT_FOR_BALL:
			_stop_horizontal()
			state_seconds_remaining = maxf(state_seconds_remaining - delta, 0.0)
			if state_seconds_remaining == 0.0 and ball.is_available():
				transition_to(BotState.SEEK_BALL)
	move_and_slide()


func transition_to(next_state: int) -> void:
	if is_eliminated and next_state != BotState.ELIMINATED:
		return
	state = next_state
	if state == BotState.AIM:
		state_seconds_remaining = aim_delay
	elif state == BotState.WAIT_FOR_BALL:
		state_seconds_remaining = throw_recovery_delay


func _move_to_ball(delta: float) -> void:
	if not ball.is_available():
		_stop_horizontal()
		transition_to(BotState.WAIT_FOR_BALL)
		return
	var offset := ball.global_position - global_position
	var horizontal_offset := Vector3(offset.x, 0.0, offset.z)
	if horizontal_offset.length() <= pickup_range:
		_stop_horizontal()
		try_pick_up_ball()
		return
	var direction := horizontal_offset.normalized()
	velocity.x = move_toward(velocity.x, direction.x * movement_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * movement_speed, acceleration * delta)
	look_at(global_position + direction, Vector3.UP)


func try_pick_up_ball() -> bool:
	if (
		not is_active
		or not gameplay_enabled
		or is_eliminated
		or held_ball != null
		or not is_instance_valid(ball)
		or not ball.is_available()
		or global_position.distance_to(ball.global_position) > pickup_range + 0.5
	):
		return false
	ball.hold_at(hold_position)
	if ball.state != Dodgeball.BallState.HELD:
		return false
	held_ball = ball
	transition_to(BotState.HOLD_BALL)
	return true


func _face_player() -> void:
	if not is_instance_valid(player):
		return
	var target := player.global_position
	target.y = global_position.y
	if not target.is_equal_approx(global_position):
		look_at(target, Vector3.UP)


func _throw_at_player() -> bool:
	if held_ball == null or not is_instance_valid(player):
		return false
	var target := player.global_position + Vector3.UP * target_height_offset
	target.x += aim_error
	var direction := target - hold_position.global_position
	var ball_to_throw := held_ball
	held_ball = null
	ball_to_throw.throw(direction, throw_speed, Dodgeball.Thrower.BOT)
	ball_thrown.emit()
	return true


func _stop_horizontal() -> void:
	velocity.x = move_toward(velocity.x, 0.0, acceleration * get_physics_process_delta_time())
	velocity.z = move_toward(velocity.z, 0.0, acceleration * get_physics_process_delta_time())


func stop_play() -> void:
	is_active = false
	velocity = Vector3.ZERO


func eliminate() -> void:
	if is_eliminated:
		return
	is_eliminated = true
	is_active = false
	held_ball = null
	velocity = Vector3.ZERO
	transition_to(BotState.ELIMINATED)
	mesh.material_override = _create_eliminated_material()
	eliminated.emit()


func reset_to(new_spawn_transform: Transform3D) -> void:
	global_transform = new_spawn_transform
	reset_physics_interpolation()
	velocity = Vector3.ZERO
	held_ball = null
	state_seconds_remaining = 0.0
	is_eliminated = false
	is_active = true
	gameplay_enabled = true
	state = BotState.SEEK_BALL
	mesh.material_override = active_material
	_face_player()


func set_gameplay_enabled(enabled: bool) -> void:
	gameplay_enabled = enabled
	if enabled:
		is_active = not is_eliminated
		return
	is_active = false
	held_ball = null
	state_seconds_remaining = 0.0
	velocity = Vector3.ZERO


func _create_eliminated_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.18, 0.2, 1.0)
	material.roughness = 0.9
	return material
