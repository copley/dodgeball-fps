class_name PlayerController
extends CharacterBody3D

signal pickup_requested(player: PlayerController)

@export var move_speed: float = 7.0
@export var mouse_sensitivity: float = 0.002
@export_range(1.0, 89.0, 1.0) var vertical_look_limit_degrees: float = 85.0
@export var pickup_range: float = 2.0
@export var minimum_throw_speed: float = 8.0
@export var maximum_throw_speed: float = 22.0
@export var full_charge_seconds: float = 1.25

@onready var camera: Camera3D = $Camera3D
@onready var ball_hold_position: Marker3D = $Camera3D/BallHoldPosition

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var held_ball: Dodgeball
var charge_seconds: float = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if event.is_action_pressed("pickup_ball") and held_ball == null:
		pickup_requested.emit(self)

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
		held_ball == null
		and ball.is_available()
		and global_position.distance_to(ball.global_position) <= pickup_range
	)


func give_ball(ball: Dodgeball) -> void:
	if held_ball != null:
		return
	held_ball = ball
	charge_seconds = 0.0
	ball.hold_at(ball_hold_position)
