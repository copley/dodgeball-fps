class_name PlayerController
extends CharacterBody3D

signal pickup_requested(player: PlayerController)
signal catch_requested(player: PlayerController)
signal catch_window_changed(active: bool)
signal catch_succeeded
signal eliminated

@export var move_speed: float = 7.0
@export var mouse_sensitivity: float = 0.002
@export_range(1.0, 89.0, 1.0) var vertical_look_limit_degrees: float = 85.0
@export var pickup_range: float = 2.0
@export var minimum_throw_speed: float = 8.0
@export var maximum_throw_speed: float = 22.0
@export var full_charge_seconds: float = 1.25
@export var catch_duration: float = 0.25
@export var catch_range: float = 2.25
@export_range(-1.0, 1.0, 0.05) var minimum_incoming_alignment: float = 0.2

@onready var camera: Camera3D = $Camera3D
@onready var ball_hold_position: Marker3D = $Camera3D/BallHoldPosition

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var held_ball: Dodgeball
var charge_seconds: float = 0.0
var catch_seconds_remaining: float = 0.0
var is_eliminated: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if event.is_action_pressed("pickup_ball") and held_ball == null:
		pickup_requested.emit(self)

	if event.is_action_pressed("catch_ball"):
		start_catch_window()

	if event.is_action_pressed("throw_ball") and held_ball != null:
		charge_seconds = 0.0

	if event.is_action_released("throw_ball") and held_ball != null:
		var charge_ratio := clampf(charge_seconds / full_charge_seconds, 0.0, 1.0)
		var throw_speed := lerpf(minimum_throw_speed, maximum_throw_speed, charge_ratio)
		var ball_to_throw := held_ball
		held_ball = null
		charge_seconds = 0.0
		ball_to_throw.throw(-camera.global_basis.z, throw_speed)

	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_apply_mouse_look(event.relative)


func _apply_mouse_look(relative_motion: Vector2) -> void:
	rotate_y(-relative_motion.x * mouse_sensitivity)
	camera.rotation.x = clampf(
		camera.rotation.x - relative_motion.y * mouse_sensitivity,
		deg_to_rad(-vertical_look_limit_degrees),
		deg_to_rad(vertical_look_limit_degrees)
	)


func _physics_process(delta: float) -> void:
	if catch_seconds_remaining > 0.0:
		catch_requested.emit(self)
		catch_seconds_remaining = maxf(catch_seconds_remaining - delta, 0.0)
		if catch_seconds_remaining == 0.0:
			catch_window_changed.emit(false)

	if is_eliminated:
		velocity = Vector3.ZERO
		return

	if held_ball != null and Input.is_action_pressed("throw_ball"):
		charge_seconds = minf(charge_seconds + delta, full_charge_seconds)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_back"
	)
	var movement_direction := (transform.basis * Vector3(
		input_direction.x,
		0.0,
		input_direction.y
	)).normalized()

	velocity.x = movement_direction.x * move_speed
	velocity.z = movement_direction.z * move_speed
	move_and_slide()


func can_pick_up(ball: Dodgeball) -> bool:
	return (
		not is_eliminated
		and held_ball == null
		and ball.is_available()
		and global_position.distance_to(ball.global_position) <= pickup_range
	)


func give_ball(ball: Dodgeball) -> void:
	if held_ball != null:
		return
	held_ball = ball
	charge_seconds = 0.0
	ball.hold_at(ball_hold_position)


func start_catch_window() -> void:
	if is_eliminated or held_ball != null or catch_seconds_remaining > 0.0:
		return
	catch_seconds_remaining = catch_duration
	catch_window_changed.emit(true)


func is_catch_window_active() -> bool:
	return catch_seconds_remaining > 0.0


func can_catch(ball: Dodgeball) -> bool:
	if (
		is_eliminated
		or held_ball != null
		or not is_catch_window_active()
		or not ball.is_thrown()
	):
		return false
	var to_ball := ball.global_position - camera.global_position
	if to_ball.length() > catch_range or to_ball.is_zero_approx():
		return false
	var forward := -camera.global_basis.z
	if forward.dot(to_ball.normalized()) <= 0.0:
		return false
	var ball_to_player := camera.global_position - ball.global_position
	return (
		not ball.linear_velocity.is_zero_approx()
		and ball.linear_velocity.normalized().dot(ball_to_player.normalized())
		>= minimum_incoming_alignment
	)


func catch_ball(ball: Dodgeball) -> bool:
	if not can_catch(ball) or not ball.catch_at(ball_hold_position):
		return false
	held_ball = ball
	charge_seconds = 0.0
	catch_seconds_remaining = 0.0
	catch_window_changed.emit(false)
	catch_succeeded.emit()
	return true


func eliminate() -> void:
	if is_eliminated:
		return
	is_eliminated = true
	catch_seconds_remaining = 0.0
	catch_window_changed.emit(false)
	eliminated.emit()
