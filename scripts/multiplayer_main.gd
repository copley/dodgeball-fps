extends Node3D

const AVATAR_SCENE: PackedScene = preload("res://scenes/net_avatar.tscn")
const BALL_SCENE: PackedScene = preload("res://scenes/net_ball.tscn")

const SLOT_COUNT := 4
const BALL_COUNT := 3
const SERVER_PEER_ID := 1
const DEFAULT_PORT := 9080
const DEFAULT_SERVER_URL := "ws://127.0.0.1:9080"
const MATCH_SECONDS := 180.0
const RESPAWN_SECONDS := 1.25
const SNAPSHOT_INTERVAL := 0.05
const CATCH_SECONDS := 0.24
const PICKUP_RANGE := 2.1
const CATCH_RANGE := 2.35
const MIN_THROW_SPEED := 9.0
const MAX_THROW_SPEED := 22.0
const FULL_CHARGE_SECONDS := 1.0
const INPUT_TIMEOUT_SECONDS := 0.5

@onready var court: Node3D = $Court
@onready var connection_label: Label = $UI/Connection
@onready var score_label: Label = $UI/Score
@onready var timer_label: Label = $UI/Timer
@onready var role_label: Label = $UI/Role
@onready var help_label: Label = $UI/Help

var avatars: Array[NetAvatar] = []
var balls: Array[NetBall] = []
var peer_to_slot: Dictionary = {}
var slot_peer: Array[int] = [-1, -1, -1, -1]
var slot_human: Array[bool] = [false, false, false, false]
var slot_input: Array[Dictionary] = [{}, {}, {}, {}]
var slot_input_age: Array[float] = [0.0, 0.0, 0.0, 0.0]
var slot_last_input_frame: Array[int] = [-1, -1, -1, -1]
var slot_last_throw: Array[bool] = [false, false, false, false]
var slot_last_pickup: Array[bool] = [false, false, false, false]
var slot_last_catch: Array[bool] = [false, false, false, false]
var slot_charge: Array[float] = [0.0, 0.0, 0.0, 0.0]
var slot_catch_remaining: Array[float] = [0.0, 0.0, 0.0, 0.0]
var slot_respawn_remaining: Array[float] = [0.0, 0.0, 0.0, 0.0]
var score: Array[int] = [0, 0]
var match_seconds_remaining: float = MATCH_SECONDS
var snapshot_accumulator: float = 0.0
var local_slot: int = -1
var input_frame: int = 0
var is_server_instance: bool = false
var server_url: String = DEFAULT_SERVER_URL
var server_port: int = DEFAULT_PORT
var connection_ready: bool = false
var network_startup_enabled: bool = true
var websocket_peer: WebSocketMultiplayerPeer


func _ready() -> void:
	_configure_from_arguments()
	_spawn_match_entities()
	if network_startup_enabled:
		_bind_multiplayer_signals()
		if is_server_instance:
			_start_server()
		else:
			_start_client()
	else:
		connection_ready = true
	_update_hud()


func _configure_from_arguments() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--server":
			is_server_instance = true
		elif arg.begins_with("--port="):
			server_port = int(arg.trim_prefix("--port="))
		elif arg.begins_with("--url="):
			var requested_url := arg.trim_prefix("--url=")
			if _is_supported_server_url(requested_url):
				server_url = requested_url
			else:
				push_warning("Ignoring invalid WebSocket server URL: %s" % requested_url)
	if OS.has_feature("web"):
		var browser_url := _browser_server_url()
		if not browser_url.is_empty():
			server_url = browser_url


func _browser_server_url() -> String:
	var value: Variant = JavaScriptBridge.eval(
		"new URLSearchParams(window.location.search).get('server') || ''",
		true
	)
	if value is String and _is_supported_server_url(value):
		return value
	return ""


func _is_supported_server_url(value: String) -> bool:
	return value.begins_with("ws://") or value.begins_with("wss://")


func _bind_multiplayer_signals() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _start_server() -> void:
	websocket_peer = WebSocketMultiplayerPeer.new()
	var error := websocket_peer.create_server(server_port)
	if error != OK:
		connection_label.text = "SERVER ERROR: %s" % error_string(error)
		push_error(connection_label.text)
		return
	multiplayer.multiplayer_peer = websocket_peer
	connection_ready = true
	connection_label.text = "SERVER :%d — 4 bots waiting" % server_port
	role_label.text = "DEDICATED SERVER"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("2v2 dodgeball server listening on ws://0.0.0.0:%d" % server_port)
	print("Match ready: %d bot-filled slots, %d authoritative balls, %.0f second clock" % [SLOT_COUNT, BALL_COUNT, MATCH_SECONDS])


func _start_client() -> void:
	websocket_peer = WebSocketMultiplayerPeer.new()
	var error := websocket_peer.create_client(server_url)
	if error != OK:
		connection_label.text = "CONNECT ERROR: %s" % error_string(error)
		return
	multiplayer.multiplayer_peer = websocket_peer
	connection_label.text = "CONNECTING %s" % server_url
	role_label.text = "WAITING FOR SLOT"


func _on_connected_to_server() -> void:
	connection_ready = true
	connection_label.text = "CONNECTED"


func _on_connection_failed() -> void:
	connection_ready = false
	connection_label.text = "CONNECTION FAILED — start server with -- --server"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_server_disconnected() -> void:
	connection_ready = false
	local_slot = -1
	connection_label.text = "SERVER DISCONNECTED"
	role_label.text = "OFFLINE"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_peer_connected(peer_id: int) -> void:
	if not is_server_instance:
		return
	var slot := _first_free_slot()
	if slot < 0:
		print("Rejecting peer %d: match full" % peer_id)
		return
	peer_to_slot[peer_id] = slot
	slot_peer[slot] = peer_id
	slot_human[slot] = true
	slot_input[slot] = {}
	slot_input_age[slot] = 0.0
	slot_last_input_frame[slot] = -1
	assign_slot.rpc_id(peer_id, slot)
	print("Peer %d joined slot %d team %d" % [peer_id, slot, _team_for_slot(slot)])


func _on_peer_disconnected(peer_id: int) -> void:
	if not is_server_instance or not peer_to_slot.has(peer_id):
		return
	var slot: int = int(peer_to_slot[peer_id])
	peer_to_slot.erase(peer_id)
	slot_peer[slot] = -1
	slot_human[slot] = false
	slot_input[slot] = {}
	slot_input_age[slot] = 0.0
	slot_last_input_frame[slot] = -1
	slot_last_throw[slot] = false
	slot_last_pickup[slot] = false
	slot_last_catch[slot] = false
	print("Peer %d left slot %d; bot resumed control" % [peer_id, slot])


func _first_free_slot() -> int:
	for slot in SLOT_COUNT:
		if not slot_human[slot]:
			return slot
	return -1


@rpc("authority", "call_remote", "reliable", 2)
func assign_slot(slot: int) -> void:
	local_slot = slot
	for avatar: NetAvatar in avatars:
		avatar.set_local_player(avatar.slot_id == local_slot)
	role_label.text = "BLUE %d" % (slot + 1) if _team_for_slot(slot) == 0 else "RED %d" % (slot - 1)
	connection_label.text = "CONNECTED — BOT REPLACED"
	print("Assigned local player to %s" % role_label.text)


@rpc("any_peer", "call_remote", "unreliable", 1)
func submit_input(frame: int, input_state: Dictionary) -> void:
	if not is_server_instance:
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if not peer_to_slot.has(peer_id):
		return
	var slot: int = int(peer_to_slot[peer_id])
	if frame <= slot_last_input_frame[slot]:
		return
	slot_last_input_frame[slot] = frame
	slot_input_age[slot] = 0.0
	slot_input[slot] = _sanitize_input(input_state, avatars[slot])


func _sanitize_input(input_state: Dictionary, avatar: NetAvatar) -> Dictionary:
	var move := Vector2.ZERO
	var move_value: Variant = input_state.get("move", Vector2.ZERO)
	if move_value is Vector2:
		move = (move_value as Vector2).limit_length(1.0)
	var yaw_value := float(input_state.get("yaw", avatar.yaw))
	if not is_finite(yaw_value):
		yaw_value = avatar.yaw
	var pitch_value := float(input_state.get("pitch", avatar.pitch))
	if not is_finite(pitch_value):
		pitch_value = avatar.pitch
	return {
		"move": move,
		"yaw": wrapf(yaw_value, -PI, PI),
		"pitch": clampf(pitch_value, deg_to_rad(-85.0), deg_to_rad(85.0)),
		"sprint": bool(input_state.get("sprint", false)),
		"jump": bool(input_state.get("jump", false)),
		"dodge_left": bool(input_state.get("dodge_left", false)),
		"dodge_right": bool(input_state.get("dodge_right", false)),
		"pickup": bool(input_state.get("pickup", false)),
		"catch": bool(input_state.get("catch", false)),
		"throw": bool(input_state.get("throw", false)),
	}


func _neutral_input(avatar: NetAvatar) -> Dictionary:
	return _sanitize_input({}, avatar)


func _physics_process(delta: float) -> void:
	if is_server_instance:
		_server_tick(delta)
	else:
		_client_tick(delta)


func _client_tick(delta: float) -> void:
	if local_slot < 0 or local_slot >= avatars.size() or not connection_ready:
		return
	var avatar := avatars[local_slot]
	if not avatar.is_alive:
		return
	var input_state := avatar.sample_local_input()
	input_frame += 1
	submit_input.rpc_id(SERVER_PEER_ID, input_frame, input_state)
	avatar.simulate(input_state, delta, true)


func _server_tick(delta: float) -> void:
	match_seconds_remaining = maxf(0.0, match_seconds_remaining - delta)
	if match_seconds_remaining <= 0.0:
		_reset_match()

	for slot in SLOT_COUNT:
		var avatar := avatars[slot]
		if slot_respawn_remaining[slot] > 0.0:
			slot_respawn_remaining[slot] = maxf(0.0, slot_respawn_remaining[slot] - delta)
			if slot_respawn_remaining[slot] <= 0.0:
				avatar.respawn_at(_spawn_for_slot(slot))
			continue
		if not avatar.is_alive:
			continue

		var input_state: Dictionary
		if slot_human[slot]:
			slot_input_age[slot] += delta
			input_state = slot_input[slot] if slot_input_age[slot] <= INPUT_TIMEOUT_SECONDS else _neutral_input(avatar)
		else:
			input_state = _build_bot_input(slot)
		avatar.simulate(input_state, delta, true)
		_process_slot_actions(slot, input_state, delta)

	snapshot_accumulator += delta
	if snapshot_accumulator >= SNAPSHOT_INTERVAL:
		snapshot_accumulator = 0.0
		var snapshot := _build_snapshot()
		for peer_id: int in peer_to_slot:
			if _peer_is_open(peer_id):
				receive_snapshot.rpc_id(peer_id, snapshot)
	_update_hud()


func _peer_is_open(peer_id: int) -> bool:
	if websocket_peer == null:
		return false
	var connection := websocket_peer.get_peer(peer_id)
	return connection != null and connection.get_ready_state() == WebSocketPeer.STATE_OPEN


func _process_slot_actions(slot: int, input_state: Dictionary, delta: float) -> void:
	var avatar := avatars[slot]
	var pickup_now := bool(input_state.get("pickup", false))
	var catch_now := bool(input_state.get("catch", false))
	var throw_now := bool(input_state.get("throw", false))

	if pickup_now and not slot_last_pickup[slot] and avatar.held_ball_id < 0:
		_try_pickup(slot)
	if catch_now and not slot_last_catch[slot] and avatar.held_ball_id < 0:
		slot_catch_remaining[slot] = CATCH_SECONDS
	if slot_catch_remaining[slot] > 0.0:
		slot_catch_remaining[slot] = maxf(0.0, slot_catch_remaining[slot] - delta)
		_try_catch(slot)

	if avatar.held_ball_id >= 0 and throw_now:
		slot_charge[slot] = minf(FULL_CHARGE_SECONDS, slot_charge[slot] + delta)
	if avatar.held_ball_id >= 0 and slot_last_throw[slot] and not throw_now:
		_throw_held_ball(slot)
	elif avatar.held_ball_id < 0:
		slot_charge[slot] = 0.0

	slot_last_pickup[slot] = pickup_now
	slot_last_catch[slot] = catch_now
	slot_last_throw[slot] = throw_now


func _try_pickup(slot: int) -> bool:
	var avatar := avatars[slot]
	var best_ball: NetBall
	var best_distance := INF
	for ball: NetBall in balls:
		if not ball.can_be_picked_up():
			continue
		var distance := avatar.global_position.distance_to(ball.global_position)
		if distance <= PICKUP_RANGE and distance < best_distance:
			best_ball = ball
			best_distance = distance
	if best_ball == null:
		return false
	if best_ball.hold_for(slot, avatar.hold_point):
		avatar.held_ball_id = best_ball.ball_id
		slot_charge[slot] = 0.0
		return true
	return false


func _try_catch(slot: int) -> bool:
	var avatar := avatars[slot]
	for ball: NetBall in balls:
		if ball.state != NetBall.BallState.THROWN or ball.thrower_team == avatar.team_id:
			continue
		var target_point := avatar.global_position + Vector3.UP * 1.2
		var to_avatar := target_point - ball.global_position
		if to_avatar.length() > CATCH_RANGE or ball.linear_velocity.is_zero_approx():
			continue
		if ball.linear_velocity.normalized().dot(to_avatar.normalized()) < 0.25:
			continue
		if ball.catch_for(slot, avatar.hold_point):
			avatar.held_ball_id = ball.ball_id
			slot_charge[slot] = 0.0
			slot_catch_remaining[slot] = 0.0
			return true
	return false


func _throw_held_ball(slot: int) -> bool:
	var avatar := avatars[slot]
	var ball_id := avatar.held_ball_id
	if ball_id < 0 or ball_id >= balls.size():
		return false
	var speed := lerpf(MIN_THROW_SPEED, MAX_THROW_SPEED, clampf(slot_charge[slot] / FULL_CHARGE_SECONDS, 0.0, 1.0))
	var direction := avatar.view_direction()
	var success := balls[ball_id].throw_from(slot, avatar.team_id, direction, speed)
	if success:
		avatar.held_ball_id = -1
		slot_charge[slot] = 0.0
	return success


func _build_bot_input(slot: int) -> Dictionary:
	var avatar := avatars[slot]
	var result := {
		"move": Vector2.ZERO,
		"yaw": avatar.yaw,
		"pitch": 0.0,
		"sprint": true,
		"jump": false,
		"dodge_left": false,
		"dodge_right": false,
		"pickup": false,
		"catch": false,
		"throw": false,
	}
	var opponent := _nearest_living_opponent(slot)
	if opponent != null:
		var aim_vector := (opponent.global_position + Vector3.UP * 1.15) - (avatar.global_position + Vector3.UP * 1.4)
		if aim_vector.length() > 0.01:
			var aim_direction := aim_vector.normalized()
			result["yaw"] = atan2(-aim_direction.x, -aim_direction.z)
			result["pitch"] = asin(clampf(aim_direction.y, -0.8, 0.8))

	if avatar.held_ball_id >= 0:
		result["throw"] = slot_charge[slot] < 0.55
		return result

	for ball: NetBall in balls:
		if ball.state == NetBall.BallState.THROWN and ball.thrower_team != avatar.team_id:
			var to_avatar := (avatar.global_position + Vector3.UP) - ball.global_position
			if to_avatar.length() < 3.0 and not ball.linear_velocity.is_zero_approx() and ball.linear_velocity.normalized().dot(to_avatar.normalized()) > 0.35:
				result["catch"] = true
				if to_avatar.length() > 1.8:
					result["dodge_left"] = ((slot + int(match_seconds_remaining * 10.0)) % 2) == 0
					result["dodge_right"] = not result["dodge_left"]
				return result

	var target_ball := _nearest_available_ball(avatar.global_position)
	if target_ball != null:
		var offset := target_ball.global_position - avatar.global_position
		var flat := Vector3(offset.x, 0.0, offset.z)
		if flat.length() <= PICKUP_RANGE:
			result["pickup"] = true
		else:
			var direction := flat.normalized()
			result["yaw"] = atan2(-direction.x, -direction.z)
			var basis := Basis(Vector3.UP, float(result["yaw"]))
			result["move"] = Vector2(direction.dot(basis.x), direction.dot(basis.z))
	return result


func _nearest_available_ball(origin: Vector3) -> NetBall:
	var result: NetBall
	var best := INF
	for ball: NetBall in balls:
		if not ball.can_be_picked_up():
			continue
		var distance := origin.distance_squared_to(ball.global_position)
		if distance < best:
			best = distance
			result = ball
	return result


func _nearest_living_opponent(slot: int) -> NetAvatar:
	var source := avatars[slot]
	var result: NetAvatar
	var best := INF
	for candidate: NetAvatar in avatars:
		if candidate.team_id == source.team_id or not candidate.is_alive:
			continue
		var distance := source.global_position.distance_squared_to(candidate.global_position)
		if distance < best:
			best = distance
			result = candidate
	return result


func _on_authoritative_player_hit(_ball_id: int, victim_slot: int, _thrower_slot: int, thrower_team: int) -> void:
	if not is_server_instance or victim_slot < 0 or victim_slot >= avatars.size():
		return
	var victim := avatars[victim_slot]
	if not victim.is_alive or victim.team_id == thrower_team:
		return
	score[thrower_team] += 1
	if victim.held_ball_id >= 0 and victim.held_ball_id < balls.size():
		var held := balls[victim.held_ball_id]
		held.reset_to(held.spawn_transform)
	victim.held_ball_id = -1
	victim.set_alive(false)
	slot_respawn_remaining[victim_slot] = RESPAWN_SECONDS
	slot_charge[victim_slot] = 0.0
	slot_catch_remaining[victim_slot] = 0.0


func _reset_match() -> void:
	score = [0, 0]
	match_seconds_remaining = MATCH_SECONDS
	for slot in SLOT_COUNT:
		avatars[slot].respawn_at(_spawn_for_slot(slot))
		slot_respawn_remaining[slot] = 0.0
		slot_charge[slot] = 0.0
		slot_catch_remaining[slot] = 0.0
		slot_last_throw[slot] = false
		slot_last_pickup[slot] = false
		slot_last_catch[slot] = false
	for ball_index in BALL_COUNT:
		balls[ball_index].reset_to(_ball_spawn(ball_index))


func _spawn_match_entities() -> void:
	for slot in SLOT_COUNT:
		var avatar := AVATAR_SCENE.instantiate() as NetAvatar
		add_child(avatar)
		avatar.configure(slot, _team_for_slot(slot))
		avatar.respawn_at(_spawn_for_slot(slot))
		avatars.append(avatar)
	for ball_index in BALL_COUNT:
		var ball := BALL_SCENE.instantiate() as NetBall
		add_child(ball)
		ball.configure(ball_index, is_server_instance)
		ball.reset_to(_ball_spawn(ball_index))
		ball.authoritative_player_hit.connect(_on_authoritative_player_hit)
		balls.append(ball)


func _spawn_for_slot(slot: int) -> Transform3D:
	var x := -3.0 if slot % 2 == 0 else 3.0
	var z := 10.0 if _team_for_slot(slot) == 0 else -10.0
	var basis := Basis(Vector3.UP, PI if _team_for_slot(slot) == 0 else 0.0)
	return Transform3D(basis, Vector3(x, 0.05, z))


func _ball_spawn(ball_index: int) -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(float(ball_index - 1) * 3.0, 0.55, 0.0))


func _team_for_slot(slot: int) -> int:
	return 0 if slot < 2 else 1


func _build_snapshot() -> Dictionary:
	var avatar_data: Array = []
	for avatar: NetAvatar in avatars:
		avatar_data.append({
			"p": avatar.global_position,
			"v": avatar.velocity,
			"yaw": avatar.yaw,
			"pitch": avatar.pitch,
			"alive": avatar.is_alive,
			"held": avatar.held_ball_id,
			"human": slot_human[avatar.slot_id],
		})
	var ball_data: Array = []
	for ball: NetBall in balls:
		ball_data.append({
			"p": ball.global_position,
			"v": ball.linear_velocity,
			"state": ball.state,
			"holder": ball.holder_slot,
			"thrower": ball.thrower_slot,
			"thrower_team": ball.thrower_team,
		})
	return {
		"avatars": avatar_data,
		"balls": ball_data,
		"score": score,
		"time": match_seconds_remaining,
	}


@rpc("authority", "call_remote", "unreliable", 1)
func receive_snapshot(snapshot: Dictionary) -> void:
	if is_server_instance:
		return
	var avatar_data: Array = snapshot.get("avatars", [])
	for index in mini(avatar_data.size(), avatars.size()):
		var data: Dictionary = avatar_data[index]
		avatars[index].apply_snapshot(
			data.get("p", avatars[index].global_position),
			data.get("v", Vector3.ZERO),
			float(data.get("yaw", 0.0)),
			float(data.get("pitch", 0.0)),
			bool(data.get("alive", true)),
			int(data.get("held", -1))
		)
	var ball_data: Array = snapshot.get("balls", [])
	for index in mini(ball_data.size(), balls.size()):
		var data: Dictionary = ball_data[index]
		balls[index].apply_snapshot(
			data.get("p", balls[index].global_position),
			data.get("v", Vector3.ZERO),
			int(data.get("state", NetBall.BallState.AVAILABLE)),
			int(data.get("holder", -1)),
			int(data.get("thrower", -1)),
			int(data.get("thrower_team", -1))
		)
	var score_data: Array = snapshot.get("score", [0, 0])
	if score_data.size() >= 2:
		score[0] = int(score_data[0])
		score[1] = int(score_data[1])
	match_seconds_remaining = float(snapshot.get("time", match_seconds_remaining))
	_update_hud()


func _update_hud() -> void:
	score_label.text = "BLUE  %d  —  %d  RED" % [score[0], score[1]]
	var seconds := maxi(0, int(ceil(match_seconds_remaining)))
	timer_label.text = "%d:%02d" % [seconds / 60, seconds % 60]
	if is_server_instance:
		var humans := 0
		for value: bool in slot_human:
			if value:
				humans += 1
		connection_label.text = "SERVER :%d — %d human / %d bot" % [server_port, humans, SLOT_COUNT - humans]
	help_label.text = "WASD move  |  Shift sprint  |  Space jump  |  E pick up  |  Hold/release LMB throw  |  RMB catch  |  Q/F dodge"
