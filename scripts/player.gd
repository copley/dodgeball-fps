class_name PlayerController
extends CharacterBody3D

signal pickup_requested(player: PlayerController)
signal catch_requested(player: PlayerController)
signal catch_window_changed(active: bool)
signal catch_succeeded
signal eliminated
signal dodge_availability_changed(available: bool)

@export var acceleration: float = 30.0
@export var normal_speed: float = 7.0
@export var sprint_speed: float = 10.0
@export_range(0.0, 1.0, 0.05) var air_control: float = 0.35
@export var jump_velocity: float = 6.5
@export var standing_height: float = 1.8
@export var crouching_height: float = 1.1
@export var crouch_transition_speed: float = 7.0
@export var dodge_speed: float = 12.0
@export var dodge_distance: float = 3.0
@export var dodge_duration: float = 0.25
@export var dodge_cooldown: float = 1.0
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
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var held_ball: Dodgeball
var charge_seconds: float = 0.0
var catch_seconds_remaining: float = 0.0
var is_eliminated: bool = false
var is_crouching: bool = false
var dodge_seconds_remaining: float = 0.0
var dodge_cooldown_remaining: float = 0.0
var dodge_direction: Vector3 = Vector3.ZERO

const STANDING_CAMERA_HEIGHT: float = 1.6


func _ready() -> void:
	collision_shape.shape = collision_shape.shape.duplicate()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or is_eliminated:
		return

	if event.is_action_pressed("pickup_ball") and held_ball == null:
		pickup_requested.emit(self)

	if event.is_action_pressed("catch_ball"):
		start_catch_window()

	if event.is_action_pressed("jump"):
		try_jump()

	if event.is_action_pressed("dodge_left"):
		start_dodge(-1.0)
	elif event.is_action_pressed("dodge_right"):
		start_dodge(1.0)

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

	_update_crouch(delta)
	if dodge_cooldown_remaining > 0.0:
		dodge_cooldown_remaining = maxf(dodge_cooldown_remaining - delta, 0.0)
		if dodge_cooldown_remaining == 0.0:
			dodge_availability_changed.emit(true)

	if held_ball != null and Input.is_action_pressed("throw_ball"):
		charge_seconds = minf(charge_seconds + delta, full_charge_seconds)

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif velocity.y <= 0.0:
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

	if dodge_seconds_remaining > 0.0:
		velocity.x = dodge_direction.x * effective_dodge_speed()
		velocity.z = dodge_direction.z * effective_dodge_speed()
		dodge_seconds_remaining = maxf(dodge_seconds_remaining - delta, 0.0)
	else:
		var speed := get_movement_speed(Input.is_action_pressed("sprint"))
		var target_velocity := movement_direction * speed
		var control := 1.0 if is_on_floor() else air_control
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * control * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * control * delta)
	move_and_slide()


func effective_dodge_speed() -> float:
	if dodge_duration <= 0.0:
		return dodge_speed
	return minf(dodge_speed, dodge_distance / dodge_duration)


func get_movement_speed(wants_sprint: bool) -> float:
	return sprint_speed if wants_sprint and not is_crouching else normal_speed


func try_jump() -> bool:
	if is_eliminated or is_crouching or not is_on_floor() or velocity.y > 0.0:
		return false
	velocity.y = jump_velocity
	return true


func start_dodge(side: float) -> bool:
	if (
		get_tree().paused
		or is_eliminated
		or dodge_seconds_remaining > 0.0
		or dodge_cooldown_remaining > 0.0
	):
		return false
	dodge_direction = global_basis.x * signf(side)
	dodge_direction.y = 0.0
	dodge_direction = dodge_direction.normalized()
	dodge_seconds_remaining = dodge_duration
	dodge_cooldown_remaining = dodge_cooldown
	dodge_availability_changed.emit(false)
	return true


func _update_crouch(delta: float) -> void:
	var wants_crouch := Input.is_action_pressed("crouch")
	if wants_crouch:
		is_crouching = true
	else:
		is_crouching = not can_stand_up()
	var target_height := crouching_height if is_crouching else standing_height
	var capsule := collision_shape.shape as CapsuleShape3D
	capsule.height = move_toward(capsule.height, target_height, crouch_transition_speed * delta)
	collision_shape.position.y = capsule.height * 0.5
	var camera_ratio := capsule.height / standing_height
	camera.position.y = STANDING_CAMERA_HEIGHT * camera_ratio


func can_stand_up() -> bool:
	if not is_inside_tree():
		return true
	var capsule := CapsuleShape3D.new()
	var current_capsule := collision_shape.shape as CapsuleShape3D
	capsule.radius = current_capsule.radius
	capsule.height = standing_height
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = global_transform.translated_local(
		Vector3.UP * (standing_height * 0.5 + 0.01)
	)
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func reset_to(new_spawn_transform: Transform3D) -> void:
	held_ball = null
	charge_seconds = 0.0
	catch_seconds_remaining = 0.0
	is_eliminated = false
	is_crouching = false
	dodge_seconds_remaining = 0.0
	dodge_cooldown_remaining = 0.0
	dodge_direction = Vector3.ZERO
	velocity = Vector3.ZERO
	global_transform = new_spawn_transform
	camera.rotation = Vector3.ZERO
	camera.position.y = STANDING_CAMERA_HEIGHT
	var capsule := collision_shape.shape as CapsuleShape3D
	capsule.height = standing_height
	collision_shape.position.y = standing_height * 0.5
	catch_window_changed.emit(false)
	dodge_availability_changed.emit(true)


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
