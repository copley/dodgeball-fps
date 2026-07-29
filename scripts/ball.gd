class_name Dodgeball
extends RigidBody3D

signal picked_up
signal thrown(speed: float)
signal caught
signal valid_hit(target: DodgeballTarget)
signal valid_player_hit(player: PlayerController)
signal valid_bot_hit(bot: BotController)
signal reset

enum BallState {
	AVAILABLE,
	HELD,
	THROWN,
	DEAD,
	CAUGHT,
}

enum Thrower {
	NONE,
	HUMAN,
	BOT,
}

@export var reset_height: float = -5.0
@export var reset_horizontal_distance: float = 40.0
@export var pickup_grace_seconds: float = 0.35
@export var pickup_speed_threshold: float = 1.5

var state: int = BallState.AVAILABLE
var spawn_transform: Transform3D
var hold_position: Marker3D
var seconds_since_throw: float = 0.0
var valid_hit_emitted_for_throw: bool = false
var current_thrower: int = Thrower.NONE
var gameplay_enabled: bool = true

const PHYSICAL_COLLISION_LAYER: int = 4
const PHYSICAL_COLLISION_MASK: int = 11


func _ready() -> void:
	sleeping_state_changed.connect(_on_sleeping_state_changed)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if not gameplay_enabled:
		return
	if state == BallState.HELD and is_instance_valid(hold_position):
		global_transform = hold_position.global_transform
	else:
		if state == BallState.THROWN or state == BallState.DEAD:
			seconds_since_throw += delta
			if (
				state == BallState.DEAD
				and seconds_since_throw >= pickup_grace_seconds
				and (sleeping or linear_velocity.length() <= pickup_speed_threshold)
			):
				state = BallState.AVAILABLE
				current_thrower = Thrower.NONE
		if (
			global_position.y < reset_height
			or absf(global_position.x) > reset_horizontal_distance
			or absf(global_position.z) > reset_horizontal_distance
		):
			reset_to(spawn_transform)


func _on_sleeping_state_changed() -> void:
	if (
		sleeping
		and state == BallState.DEAD
		and seconds_since_throw >= pickup_grace_seconds
	):
		state = BallState.AVAILABLE
		current_thrower = Thrower.NONE


func _on_body_entered(body: Node) -> void:
	if not gameplay_enabled:
		return
	if state == BallState.THROWN and body.is_in_group("dead_ball_surface"):
		state = BallState.DEAD
		current_thrower = Thrower.NONE
		return
	if (
		state != BallState.THROWN
		or valid_hit_emitted_for_throw
		or linear_velocity.length() <= pickup_speed_threshold
	):
		return
	if body is DodgeballTarget:
		valid_hit_emitted_for_throw = true
		state = BallState.DEAD
		current_thrower = Thrower.NONE
		valid_hit.emit(body as DodgeballTarget)
	elif body is PlayerController and current_thrower != Thrower.HUMAN:
		valid_hit_emitted_for_throw = true
		state = BallState.DEAD
		current_thrower = Thrower.NONE
		valid_player_hit.emit(body as PlayerController)
	elif body is BotController and current_thrower != Thrower.BOT:
		valid_hit_emitted_for_throw = true
		state = BallState.DEAD
		current_thrower = Thrower.NONE
		valid_bot_hit.emit(body as BotController)


func is_available() -> bool:
	return state == BallState.AVAILABLE


func is_thrown() -> bool:
	return state == BallState.THROWN


func is_dead() -> bool:
	return state == BallState.DEAD


func hold_at(marker: Marker3D) -> void:
	if not gameplay_enabled or not is_available():
		return
	state = BallState.HELD
	current_thrower = Thrower.NONE
	hold_position = marker
	global_transform = marker.global_transform
	reset_physics_interpolation()
	seconds_since_throw = 0.0
	freeze = true
	sleeping = false
	collision_layer = 0
	collision_mask = 0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	picked_up.emit()


func catch_at(marker: Marker3D) -> bool:
	if not gameplay_enabled or state != BallState.THROWN:
		return false
	state = BallState.CAUGHT
	current_thrower = Thrower.NONE
	hold_position = marker
	seconds_since_throw = 0.0
	freeze = true
	sleeping = false
	collision_layer = 0
	collision_mask = 0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	caught.emit()
	state = BallState.HELD
	global_transform = marker.global_transform
	reset_physics_interpolation()
	return true


func throw(direction: Vector3, speed: float, thrower: int = Thrower.NONE) -> void:
	if not gameplay_enabled or state != BallState.HELD:
		return
	global_transform = hold_position.global_transform
	reset_physics_interpolation()
	hold_position = null
	state = BallState.THROWN
	current_thrower = thrower
	seconds_since_throw = 0.0
	valid_hit_emitted_for_throw = false
	collision_layer = PHYSICAL_COLLISION_LAYER
	collision_mask = PHYSICAL_COLLISION_MASK
	freeze = false
	sleeping = false
	linear_velocity = direction.normalized() * speed
	angular_velocity = Vector3(4.0, 2.0, 1.0)
	thrown.emit(speed)


func reset_to(new_spawn_transform: Transform3D) -> void:
	spawn_transform = new_spawn_transform
	hold_position = null
	state = BallState.AVAILABLE
	seconds_since_throw = 0.0
	valid_hit_emitted_for_throw = false
	current_thrower = Thrower.NONE
	gameplay_enabled = true
	freeze = true
	sleeping = false
	collision_layer = PHYSICAL_COLLISION_LAYER
	collision_mask = PHYSICAL_COLLISION_MASK
	global_transform = spawn_transform
	reset_physics_interpolation()
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = false
	reset.emit()


func neutralize() -> void:
	gameplay_enabled = false
	hold_position = null
	state = BallState.DEAD
	current_thrower = Thrower.NONE
	valid_hit_emitted_for_throw = true
	seconds_since_throw = 0.0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true
