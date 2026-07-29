extends CharacterBody3D

@export var move_speed: float = 7.0
@export var mouse_sensitivity: float = 0.002
@export_range(1.0, 89.0, 1.0) var vertical_look_limit_degrees: float = 85.0

@onready var camera: Camera3D = $Camera3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

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
