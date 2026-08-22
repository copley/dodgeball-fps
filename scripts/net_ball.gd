class_name NetBall
extends RigidBody3D

signal authoritative_player_hit(ball_id: int, victim_slot: int, thrower_slot: int, thrower_team: int)

enum BallState {
	AVAILABLE,
	HELD,
	THROWN,
	DEAD,
}

@export var pickup_grace_seconds: float = 0.3
@export var pickup_speed_threshold: float = 1.4

var ball_id: int = -1
var state: int = BallState.AVAILABLE
var holder_slot: int = -1
var thrower_slot: int = -1
var thrower_team: int = -1
var hold_point: Marker3D
var spawn_transform: Transform3D
var seconds_since_throw: float = 0.0
var authoritative: bool = false
var hit_consumed: bool = false


func configure(id_value: int, is_authority_value: bool) -> void:
	ball_id = id_value
	authoritative = is_authority_value
	name = "Ball%d" % ball_id
	freeze = not authoritative


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if not authoritative:
		return
	if state == BallState.HELD:
		if is_instance_valid(hold_point):
			global_transform = hold_point.global_transform
		else:
			make_available()
		return
	if state == BallState.THROWN or state == BallState.DEAD:
		seconds_since_throw += delta
	if (
		state == BallState.DEAD
		and seconds_since_throw >= pickup_grace_seconds
		and (sleeping or linear_velocity.length() <= pickup_speed_threshold)
	):
		make_available()
	if global_position.y < -5.0 or absf(global_position.x) > 40.0 or absf(global_position.z) > 40.0:
		reset_to(spawn_transform)


func _on_body_entered(body: Node) -> void:
	if not authoritative or state != BallState.THROWN:
		return
	if body.is_in_group("dead_ball_surface"):
		make_dead()
		return
	if body is NetAvatar:
		var avatar := body as NetAvatar
		if hit_consumed or not avatar.is_alive:
			return
		if avatar.slot_id == thrower_slot or avatar.team_id == thrower_team:
			return
		hit_consumed = true
		var victim := avatar.slot_id
		var source_slot := thrower_slot
		var source_team := thrower_team
		make_dead()
		authoritative_player_hit.emit(ball_id, victim, source_slot, source_team)


func can_be_picked_up() -> bool:
	return state == BallState.AVAILABLE


func hold_for(slot: int, marker: Marker3D) -> bool:
	if not authoritative or state != BallState.AVAILABLE:
		return false
	state = BallState.HELD
	holder_slot = slot
	thrower_slot = -1
	thrower_team = -1
	hold_point = marker
	seconds_since_throw = 0.0
	hit_consumed = false
	freeze = true
	collision_layer = 0
	collision_mask = 0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = marker.global_transform
	reset_physics_interpolation()
	return true


func catch_for(slot: int, marker: Marker3D) -> bool:
	if not authoritative or state != BallState.THROWN:
		return false
	state = BallState.HELD
	holder_slot = slot
	thrower_slot = -1
	thrower_team = -1
	hold_point = marker
	seconds_since_throw = 0.0
	hit_consumed = false
	freeze = true
	collision_layer = 0
	collision_mask = 0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = marker.global_transform
	reset_physics_interpolation()
	return true


func throw_from(slot: int, team: int, direction: Vector3, speed: float) -> bool:
	if not authoritative or state != BallState.HELD or holder_slot != slot:
		return false
	if is_instance_valid(hold_point):
		global_transform = hold_point.global_transform
	reset_physics_interpolation()
	state = BallState.THROWN
	holder_slot = -1
	thrower_slot = slot
	thrower_team = team
	hold_point = null
	seconds_since_throw = 0.0
	hit_consumed = false
	freeze = false
	sleeping = false
	collision_layer = 4
	collision_mask = 3
	linear_velocity = direction.normalized() * speed
	angular_velocity = Vector3(4.0, 2.0, 1.0)
	return true


func make_dead() -> void:
	if state == BallState.HELD:
		return
	state = BallState.DEAD
	holder_slot = -1
	thrower_slot = -1
	thrower_team = -1
	hold_point = null
	seconds_since_throw = 0.0
	collision_layer = 4
	collision_mask = 3


func make_available() -> void:
	state = BallState.AVAILABLE
	holder_slot = -1
	thrower_slot = -1
	thrower_team = -1
	hold_point = null
	seconds_since_throw = 0.0
	hit_consumed = false
	freeze = false if authoritative else true
	collision_layer = 4
	collision_mask = 3


func reset_to(value: Transform3D) -> void:
	spawn_transform = value
	state = BallState.AVAILABLE
	holder_slot = -1
	thrower_slot = -1
	thrower_team = -1
	hold_point = null
	seconds_since_throw = 0.0
	hit_consumed = false
	freeze = true
	global_transform = spawn_transform
	reset_physics_interpolation()
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	collision_layer = 4
	collision_mask = 3
	freeze = false if authoritative else true


func apply_snapshot(position_value: Vector3, velocity_value: Vector3, state_value: int, holder_value: int, thrower_slot_value: int, thrower_team_value: int) -> void:
	if authoritative:
		return
	state = state_value
	holder_slot = holder_value
	thrower_slot = thrower_slot_value
	thrower_team = thrower_team_value
	global_position = global_position.lerp(position_value, 0.55)
	linear_velocity = velocity_value
	freeze = true
