extends SceneTree

const MULTIPLAYER_SCENE: PackedScene = preload("res://scenes/multiplayer_main.tscn")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_match_bootstrap_and_input_validation()
	await _test_movement_pickup_charge_catch_and_dodge()
	await _test_hits_respawn_and_match_reset()
	await _test_bot_fill_simulation()
	if failures == 0:
		print("PASS: authoritative 2v2 multiplayer slice suite")
		quit(0)
	else:
		push_error("%d multiplayer-slice assertion(s) failed" % failures)
		quit(1)


func _test_match_bootstrap_and_input_validation() -> void:
	var match_root := await _spawn_offline_server()
	_expect(match_root.avatars.size() == 4, "exactly four fixed player slots exist")
	_expect(match_root.balls.size() == 3, "exactly three dodgeballs exist")
	_expect(match_root.slot_human == [false, false, false, false], "all empty slots start under bot control")
	_expect(
		match_root.avatars[0].team_id == 0
		and match_root.avatars[1].team_id == 0
		and match_root.avatars[2].team_id == 1
		and match_root.avatars[3].team_id == 1,
		"Blue 1, Blue 2, Red 1, Red 2 team identities are fixed"
	)
	var ball_ids: Dictionary = {}
	for ball: NetBall in match_root.balls:
		ball_ids[ball.ball_id] = true
		_expect(ball.authoritative and not ball.freeze, "ball %d starts with server-authoritative physics" % ball.ball_id)
	_expect(ball_ids.size() == 3, "ball identifiers are unique")
	_expect(match_root.score == [0, 0], "team score starts at zero")
	_expect(match_root.match_seconds_remaining > 179.9, "match clock starts at three minutes")

	var sanitized: Dictionary = match_root._sanitize_input({
		"move": Vector2(30.0, -40.0),
		"yaw": 99.0,
		"pitch": 99.0,
		"sprint": true,
		"jump": true,
		"pickup": true,
	}, match_root.avatars[0])
	_expect((sanitized["move"] as Vector2).length() <= 1.0001, "server clamps client movement intent")
	_expect(absf(float(sanitized["yaw"])) <= PI, "server wraps client yaw")
	_expect(absf(float(sanitized["pitch"])) <= deg_to_rad(85.0), "server clamps client pitch")
	_expect(bool(sanitized["sprint"]) and bool(sanitized["pickup"]), "allowed action intent survives sanitization")
	await _free_match(match_root)


func _test_movement_pickup_charge_catch_and_dodge() -> void:
	var match_root := await _spawn_offline_server()
	var blue_one: NetAvatar = match_root.avatars[0]
	var red_one: NetAvatar = match_root.avatars[2]
	var movement: Dictionary = match_root._neutral_input(blue_one)
	movement["move"] = Vector2(0.0, 1.0)
	for frame in 180:
		blue_one.simulate(movement, 1.0 / 60.0, true)
	_expect(blue_one.global_position.z >= 0.649, "Blue movement remains on the Blue half")

	var dodge_input: Dictionary = match_root._neutral_input(blue_one)
	dodge_input["dodge_left"] = true
	blue_one.simulate(dodge_input, 1.0 / 60.0, true)
	var first_cooldown := blue_one.dodge_cooldown_remaining
	blue_one.simulate(dodge_input, 1.0 / 60.0, true)
	_expect(first_cooldown > 0.0 and blue_one.dodge_cooldown_remaining < first_cooldown, "lateral dodge starts once and observes cooldown")

	var quick_ball: NetBall = match_root.balls[0]
	quick_ball.reset_to(Transform3D(Basis.IDENTITY, blue_one.global_position + Vector3(0.0, 0.5, 0.5)))
	_expect(match_root._try_pickup(0), "E-style pickup acquires a nearby available ball")
	_expect(blue_one.held_ball_id == quick_ball.ball_id and quick_ball.holder_slot == 0, "possession is unambiguous")
	match_root.slot_charge[0] = 0.0
	_expect(match_root._throw_held_ball(0), "quick-release throw succeeds")
	var quick_speed := quick_ball.linear_velocity.length()

	var charged_ball: NetBall = match_root.balls[1]
	charged_ball.reset_to(Transform3D(Basis.IDENTITY, blue_one.global_position + Vector3(0.0, 0.5, 0.5)))
	_expect(match_root._try_pickup(0), "player can pick up again after releasing the first ball")
	match_root.slot_charge[0] = match_root.FULL_CHARGE_SECONDS
	_expect(match_root._throw_held_ball(0), "fully charged throw succeeds")
	var charged_speed := charged_ball.linear_velocity.length()
	_expect(charged_speed > quick_speed + 10.0, "short and full charges create meaningfully different velocities")

	quick_ball.reset_to(quick_ball.spawn_transform)
	charged_ball.reset_to(charged_ball.spawn_transform)
	var catch_ball: NetBall = match_root.balls[2]
	catch_ball.reset_to(Transform3D(Basis.IDENTITY, red_one.hold_point.global_position))
	_expect(catch_ball.hold_for(2, red_one.hold_point), "opponent takes possession for catch test")
	red_one.held_ball_id = catch_ball.ball_id
	var incoming_direction := (blue_one.global_position + Vector3.UP * 1.2 - catch_ball.global_position).normalized()
	_expect(catch_ball.throw_from(2, 1, incoming_direction, 14.0), "opponent releases a live incoming throw")
	red_one.held_ball_id = -1
	catch_ball.global_position = blue_one.global_position + Vector3.UP * 1.2 - incoming_direction * 1.0
	catch_ball.linear_velocity = incoming_direction * 14.0
	_expect(match_root._try_catch(0), "RMB-style timed catch transfers an incoming opposing ball")
	_expect(blue_one.held_ball_id == catch_ball.ball_id and catch_ball.holder_slot == 0, "successful catch transfers possession to one holder")
	await _free_match(match_root)


func _test_hits_respawn_and_match_reset() -> void:
	var match_root := await _spawn_offline_server()
	var ball: NetBall = match_root.balls[0]
	var blue_one: NetAvatar = match_root.avatars[0]
	var blue_two: NetAvatar = match_root.avatars[1]
	var red_one: NetAvatar = match_root.avatars[2]
	_prepare_throw(ball, blue_one, 0, 0, Vector3.FORWARD)
	ball._on_body_entered(red_one)
	ball._on_body_entered(red_one)
	_expect(match_root.score == [1, 0], "one opposing live-ball hit scores exactly once")
	_expect(not red_one.is_alive, "valid opposing hit eliminates the victim")

	var friendly_ball: NetBall = match_root.balls[1]
	_prepare_throw(friendly_ball, blue_one, 0, 0, Vector3.FORWARD)
	friendly_ball._on_body_entered(blue_two)
	_expect(match_root.score == [1, 0] and blue_two.is_alive, "friendly hit neither scores nor eliminates")

	var dead_ball: NetBall = match_root.balls[2]
	_prepare_throw(dead_ball, blue_one, 0, 0, Vector3.FORWARD)
	dead_ball._on_body_entered(match_root.get_node("Court/Geometry/Floor"))
	dead_ball._on_body_entered(match_root.avatars[3])
	_expect(dead_ball.state == NetBall.BallState.DEAD and match_root.score == [1, 0], "dead-surface contact neutralizes later hits")

	match_root.slot_respawn_remaining[2] = 0.001
	match_root._server_tick(0.01)
	_expect(red_one.is_alive and red_one.global_position.distance_to(match_root._spawn_for_slot(2).origin) < 0.1, "eliminated player respawns at the fixed slot spawn")

	match_root.score[0] = 4
	match_root.score[1] = 3
	match_root.match_seconds_remaining = 0.001
	match_root._server_tick(0.01)
	_expect(match_root.score == [0, 0], "expired three-minute match resets both team scores")
	_expect(is_equal_approx(match_root.match_seconds_remaining, match_root.MATCH_SECONDS), "expired match resets the clock")
	_expect(_all_players_alive(match_root) and _all_balls_available(match_root), "match reset restores all players and balls")
	await _free_match(match_root)


func _test_bot_fill_simulation() -> void:
	var match_root := await _spawn_offline_server()
	match_root.slot_human[0] = true
	match_root.slot_input[0] = match_root._neutral_input(match_root.avatars[0])
	var saw_bot_throw := false
	for frame in 360:
		match_root._server_tick(1.0 / 60.0)
		for ball: NetBall in match_root.balls:
			if ball.state == NetBall.BallState.THROWN and ball.thrower_slot > 0:
				saw_bot_throw = true
		if saw_bot_throw:
			break
		await physics_frame
	_expect(saw_bot_throw, "bots retrieve, charge, aim, and throw while a human occupies another slot")
	_expect(match_root.avatars.size() == 4 and match_root.balls.size() == 3, "human and bots coexist without duplicate participants or balls")
	_expect(_ownership_is_consistent(match_root), "bot simulation retains consistent ball ownership")
	await _free_match(match_root)


func _prepare_throw(ball: NetBall, holder: NetAvatar, slot: int, team: int, direction: Vector3) -> void:
	ball.reset_to(Transform3D(Basis.IDENTITY, holder.hold_point.global_position))
	ball.hold_for(slot, holder.hold_point)
	holder.held_ball_id = ball.ball_id
	ball.throw_from(slot, team, direction, 14.0)
	holder.held_ball_id = -1


func _all_players_alive(match_root: Node3D) -> bool:
	for avatar: NetAvatar in match_root.avatars:
		if not avatar.is_alive or avatar.held_ball_id != -1:
			return false
	return true


func _all_balls_available(match_root: Node3D) -> bool:
	for ball: NetBall in match_root.balls:
		if ball.state != NetBall.BallState.AVAILABLE or ball.holder_slot != -1:
			return false
	return true


func _ownership_is_consistent(match_root: Node3D) -> bool:
	var held_by_slot: Dictionary = {}
	for ball: NetBall in match_root.balls:
		if ball.state != NetBall.BallState.HELD:
			continue
		if held_by_slot.has(ball.holder_slot):
			return false
		held_by_slot[ball.holder_slot] = ball.ball_id
		if match_root.avatars[ball.holder_slot].held_ball_id != ball.ball_id:
			return false
	for avatar: NetAvatar in match_root.avatars:
		if avatar.held_ball_id >= 0 and not held_by_slot.has(avatar.slot_id):
			return false
	return true


func _spawn_offline_server() -> Node3D:
	var match_root := MULTIPLAYER_SCENE.instantiate()
	match_root.network_startup_enabled = false
	match_root.is_server_instance = true
	root.add_child(match_root)
	await process_frame
	match_root.set_physics_process(false)
	return match_root


func _free_match(match_root: Node3D) -> void:
	match_root.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
