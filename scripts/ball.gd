class_name Dodgeball
extends RigidBody3D

signal picked_up
signal thrown(speed: float)
signal reset

enum BallState {
	AVAILABLE,
	HELD,
	THROWN,
}

@export var reset_height: float = -5.0
@export var reset_horizontal_distance: float = 40.0

var state: int = BallState.AVAILABLE
var spawn_transform: Transform3D
var hold_position: Marker3D


func _ready() -> void:
	sleeping_state_changed.connect(_on_sleeping_state_changed)


func _physics_process(_delta: float) -> void:
	if state == BallState.HELD and is_instance_valid(hold_position):
		global_transform = hold_position.global_transform
	elif (
		global_position.y < reset_height
		or absf(global_position.x) > reset_horizontal_distance
		or absf(global_position.z) > reset_horizontal_distance
	):
		reset_to(spawn_transform)


func _on_sleeping_state_changed() -> void:
	if sleeping and state == BallState.THROWN:
		state = BallState.AVAILABLE


func is_available() -> bool:
	return state == BallState.AVAILABLE


func hold_at(marker: Marker3D) -> void:
	if not is_available():
		return
	state = BallState.HELD
	hold_position = marker
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	picked_up.emit()


func throw(direction: Vector3, speed: float) -> void:
	if state != BallState.HELD:
		return
	global_transform = hold_position.global_transform
	hold_position = null
	state = BallState.THROWN
	freeze = false
	linear_velocity = direction.normalized() * speed
	angular_velocity = Vector3(4.0, 2.0, 1.0)
	thrown.emit(speed)


func reset_to(new_spawn_transform: Transform3D) -> void:
	spawn_transform = new_spawn_transform
	hold_position = null
	state = BallState.AVAILABLE
	freeze = true
	global_transform = spawn_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = false
	sleeping = false
	reset.emit()
