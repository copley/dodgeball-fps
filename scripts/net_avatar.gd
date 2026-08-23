class_name NetAvatar
extends CharacterBody3D

@export var acceleration: float = 32.0
@export var move_speed: float = 7.5
@export var sprint_speed: float = 10.5
@export var jump_velocity: float = 6.5
@export var dodge_speed: float = 12.0
@export var dodge_duration: float = 0.22
@export var dodge_cooldown: float = 0.9
@export var mouse_sensitivity: float = 0.002
@export var standing_camera_height: float = 1.6

@onready var body_mesh: MeshInstance3D = $BodyMesh
@onready var camera: Camera3D = $Head/Camera3D
@onready var hold_point: Marker3D = $Head/Camera3D/HoldPoint
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var slot_id: int = -1
var team_id: int = -1
var is_local_player: bool = false
var is_alive: bool = true
var held_ball_id: int = -1
var yaw: float = 0.0
var pitch: float = 0.0
var dodge_remaining: float = 0.0
var dodge_cooldown_remaining: float = 0.0
var dodge_direction: Vector3 = Vector3.ZERO
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func configure(slot: int, team: int) -> void:
	slot_id = slot
	team_id = team
	name = "Avatar%d" % slot_id
	_apply_team_material()


func set_local_player(enabled: bool) -> void:
	is_local_player = enabled
	camera.current = enabled
	body_mesh.visible = not enabled
	if enabled:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if not is_local_player or not is_alive:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clampf(
			pitch - event.relative.y * mouse_sensitivity,
			deg_to_rad(-85.0),
			deg_to_rad(85.0)
		)
		rotation.y = yaw
		$Head.rotation.x = pitch
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func sample_local_input() -> Dictionary:
	return {
		"move": Input.get_vector("move_left", "move_right", "move_forward", "move_back"),
		"yaw": yaw,
		"pitch": pitch,
		"sprint": Input.is_action_pressed("sprint"),
		"jump": Input.is_action_pressed("jump"),
		"dodge_left": Input.is_action_pressed("dodge_left"),
		"dodge_right": Input.is_action_pressed("dodge_right"),
		"pickup": Input.is_action_pressed("pickup_ball"),
		"catch": Input.is_action_pressed("catch_ball"),
		"throw": Input.is_action_pressed("throw_ball"),
	}


func simulate(input_state: Dictionary, delta: float, enforce_half: bool = true) -> void:
	if not is_alive:
		velocity = Vector3.ZERO
		return
	yaw = wrapf(float(input_state.get("yaw", yaw)), -PI, PI)
	pitch = clampf(
		float(input_state.get("pitch", pitch)),
		deg_to_rad(-85.0),
		deg_to_rad(85.0)
	)
	rotation.y = yaw
	$Head.rotation.x = pitch

	if dodge_cooldown_remaining > 0.0:
		dodge_cooldown_remaining = maxf(0.0, dodge_cooldown_remaining - delta)
	if dodge_remaining > 0.0:
		dodge_remaining = maxf(0.0, dodge_remaining - delta)
		velocity.x = dodge_direction.x * dodge_speed
		velocity.z = dodge_direction.z * dodge_speed
	else:
		var dodge_side := 0.0
		if bool(input_state.get("dodge_left", false)):
			dodge_side = -1.0
		elif bool(input_state.get("dodge_right", false)):
			dodge_side = 1.0
		if dodge_side != 0.0 and dodge_cooldown_remaining <= 0.0:
			dodge_direction = global_basis.x * dodge_side
			dodge_direction.y = 0.0
			dodge_direction = dodge_direction.normalized()
			dodge_remaining = dodge_duration
			dodge_cooldown_remaining = dodge_cooldown

		var move_input: Vector2 = input_state.get("move", Vector2.ZERO)
		move_input = move_input.limit_length(1.0)
		var move_direction := (transform.basis * Vector3(move_input.x, 0.0, move_input.y)).normalized()
		var target_speed := sprint_speed if bool(input_state.get("sprint", false)) else move_speed
		var target_velocity := move_direction * target_speed
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif bool(input_state.get("jump", false)) and velocity.y <= 0.0:
		velocity.y = jump_velocity
	elif velocity.y < 0.0:
		velocity.y = 0.0

	move_and_slide()
	if enforce_half:
		var p := global_position
		if team_id == 0:
			p.z = clampf(p.z, 0.65, 12.5)
		else:
			p.z = clampf(p.z, -12.5, -0.65)
		global_position = p


func set_alive(alive: bool) -> void:
	is_alive = alive
	collision_layer = 2 if alive else 0
	collision_mask = 7 if alive else 0
	body_mesh.visible = alive and not is_local_player
	if not alive:
		velocity = Vector3.ZERO
		held_ball_id = -1


func respawn_at(spawn_transform: Transform3D) -> void:
	global_transform = spawn_transform
	reset_physics_interpolation()
	velocity = Vector3.ZERO
	dodge_remaining = 0.0
	dodge_cooldown_remaining = 0.0
	held_ball_id = -1
	set_alive(true)
	if team_id == 0:
		yaw = PI
	else:
		yaw = 0.0
	rotation.y = yaw
	pitch = 0.0
	$Head.rotation.x = 0.0


func apply_snapshot(position_value: Vector3, velocity_value: Vector3, yaw_value: float, pitch_value: float, alive: bool, held_ball: int) -> void:
	var authoritative := Transform3D(global_basis, position_value)
	if is_local_player:
		global_position = global_position.lerp(position_value, 0.35)
		velocity = velocity_value
	else:
		global_transform = authoritative
		velocity = velocity_value
		yaw = yaw_value
	pitch = pitch_value
	if not is_local_player:
		rotation.y = yaw
		$Head.rotation.x = pitch
	held_ball_id = held_ball
	set_alive(alive)


func view_direction() -> Vector3:
	return -$Head/Camera3D.global_basis.z


func _apply_team_material() -> void:
	if not is_node_ready():
		return
	var material := StandardMaterial3D.new()
	material.roughness = 0.8
	material.albedo_color = Color(0.08, 0.52, 0.95, 1.0) if team_id == 0 else Color(0.95, 0.18, 0.24, 1.0)
	body_mesh.material_override = material
