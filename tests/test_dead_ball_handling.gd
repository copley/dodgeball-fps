extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_new_throw_and_direct_hit()
	await _test_court_surface_contacts()
	await _test_dead_ball_restrictions()
	await _test_dead_ball_availability_and_rethrow()
	await _test_reset_and_entity_counts()
	if failures == 0:
		print("PASS: live and dead ball handling suite")
		quit(0)
	else:
		push_error("%d dead-ball test assertion(s) failed" % failures)
		quit(1)


func _test_new_throw_and_direct_hit() -> void:
	var main := await _spawn_main()
	var ball := main.ball as Dodgeball
	var target := main.target as DodgeballTarget
	var hit_count: Array[int] = [0]
	ball.valid_hit.connect(func(_target: DodgeballTarget) -> void: hit_count[0] += 1)
	_throw_from(ball, Vector3(0.0, 1.0, -6.0), Vector3(0.0, 0.0, -1.0), 16.0)
	_expect(ball.state == Dodgeball.BallState.THROWN, "newly thrown ball is live")
	_expect(await _wait_for_state(ball, Dodgeball.BallState.DEAD), "direct target impact makes ball DEAD")
	_expect(target.is_eliminated, "direct live target impact eliminates")
	_expect(hit_count[0] == 1, "direct live target impact emits exactly one valid hit")
	ball._on_body_entered(target)
	_expect(hit_count[0] == 1, "one throw cannot emit duplicate valid hits")
	await _free_main(main)


func _test_court_surface_contacts() -> void:
	var cases: Array[Dictionary] = [
		{"name": "floor", "position": Vector3(5.0, 2.0, 5.0), "direction": Vector3.DOWN},
		{"name": "ceiling", "position": Vector3(5.0, 4.0, 5.0), "direction": Vector3.UP},
		{"name": "left wall", "position": Vector3(-7.0, 2.0, 5.0), "direction": Vector3.LEFT},
		{"name": "right wall", "position": Vector3(7.0, 2.0, 5.0), "direction": Vector3.RIGHT},
		{"name": "near wall", "position": Vector3(5.0, 2.0, 12.0), "direction": Vector3.BACK},
		{"name": "far wall", "position": Vector3(5.0, 2.0, -12.0), "direction": Vector3.FORWARD},
	]
	for test_case: Dictionary in cases:
		var main := await _spawn_main()
		var ball := main.ball as Dodgeball
		_throw_from(
			ball,
			test_case["position"] as Vector3,
			test_case["direction"] as Vector3,
			18.0
		)
		_expect(
			await _wait_for_state(ball, Dodgeball.BallState.DEAD),
			"%s physics contact makes ball DEAD" % test_case["name"]
		)
		await _free_main(main)


func _test_dead_ball_restrictions() -> void:
	var main := await _spawn_main()
	var player := main.player as PlayerController
	var ball := main.ball as Dodgeball
	var target := main.target as DodgeballTarget
	var target_hit_count: Array[int] = [0]
	ball.valid_hit.connect(func(_target: DodgeballTarget) -> void: target_hit_count[0] += 1)
	_throw_from(ball, Vector3(5.0, 1.5, 5.0), Vector3.DOWN, 12.0)
	_expect(await _wait_for_state(ball, Dodgeball.BallState.DEAD), "floor bounce produces a dead ball")
	ball.seconds_since_throw = 0.0
	ball.global_position = Vector3(0.0, 1.0, -7.0)
	ball.linear_velocity = Vector3(0.0, 0.0, -14.0)
	_expect(await _wait_for_target_contact(ball, target), "moving dead ball physically contacts target")
	_expect(not target.is_eliminated, "bounced ball contacting target does not eliminate")
	_expect(target_hit_count[0] == 0, "dead moving ball emits no valid target hit")
	player.start_catch_window()
	ball.global_position = player.camera.global_position + Vector3(0.0, 0.0, -1.0)
	ball.linear_velocity = Vector3(0.0, 0.0, 8.0)
	_expect(not player.catch_ball(ball), "dead ball cannot be caught")
	_expect(ball.state == Dodgeball.BallState.DEAD, "failed dead-ball catch leaves state DEAD")
	await _free_main(main)


func _test_dead_ball_availability_and_rethrow() -> void:
	var main := await _spawn_main()
	var player := main.player as PlayerController
	var ball := main.ball as Dodgeball
	_throw_from(ball, Vector3(5.0, 1.5, 5.0), Vector3.DOWN, 12.0)
	_expect(await _wait_for_state(ball, Dodgeball.BallState.DEAD), "surface contact prepares availability checks")
	ball.seconds_since_throw = ball.pickup_grace_seconds
	ball.linear_velocity = Vector3.ZERO
	await physics_frame
	_expect(ball.state == Dodgeball.BallState.AVAILABLE, "slow dead ball becomes AVAILABLE")
	_throw_from(ball, Vector3(5.0, 1.5, 5.0), Vector3.DOWN, 12.0)
	_expect(await _wait_for_state(ball, Dodgeball.BallState.DEAD), "second surface contact prepares sleep check")
	ball.seconds_since_throw = ball.pickup_grace_seconds
	ball.sleeping = true
	await physics_frame
	_expect(ball.state == Dodgeball.BallState.AVAILABLE, "sleeping dead ball becomes AVAILABLE")
	ball.reset_to(Transform3D(Basis.IDENTITY, player.global_position + Vector3(0.0, 0.5, 0.0)))
	ball.linear_velocity = Vector3.ONE
	ball.angular_velocity = Vector3.ONE
	player.give_ball(ball)
	_expect(ball.state == Dodgeball.BallState.HELD, "available ball can be picked up")
	_expect(ball.linear_velocity == Vector3.ZERO and ball.angular_velocity == Vector3.ZERO, "pickup clears velocity")
	ball.throw(Vector3.FORWARD, player.minimum_throw_speed)
	_expect(ball.state == Dodgeball.BallState.THROWN, "pickup then throw restores live status")
	await _free_main(main)


func _test_reset_and_entity_counts() -> void:
	var main := await _spawn_main()
	var ball := main.ball as Dodgeball
	_throw_from(ball, Vector3(5.0, 1.5, 5.0), Vector3.DOWN, 12.0)
	await _wait_for_state(ball, Dodgeball.BallState.DEAD)
	ball.valid_hit_emitted_for_throw = true
	for reset_index in 5:
		main.restart_round()
	_expect(ball.state == Dodgeball.BallState.AVAILABLE, "reset restores AVAILABLE status")
	_expect(ball.global_transform.is_equal_approx(main.ball_spawn.global_transform), "reset restores BallSpawn")
	_expect(ball.linear_velocity == Vector3.ZERO and ball.angular_velocity == Vector3.ZERO, "reset clears velocity")
	_expect(not ball.valid_hit_emitted_for_throw, "reset clears valid-hit flag")
	_expect(_count_type(main, PlayerController) == 1, "five resets retain one player")
	_expect(_count_type(main, Dodgeball) == 1, "five resets retain one ball")
	_expect(_count_type(main, DodgeballTarget) == 1, "five resets retain one target")
	await _free_main(main)


func _spawn_main() -> Node3D:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	return main


func _free_main(main: Node3D) -> void:
	main.queue_free()
	await process_frame


func _throw_from(ball: Dodgeball, position: Vector3, direction: Vector3, speed: float) -> void:
	ball.reset_to(Transform3D(Basis.IDENTITY, position))
	var marker := Marker3D.new()
	root.add_child(marker)
	marker.global_position = position
	ball.hold_at(marker)
	ball.throw(direction, speed)
	marker.queue_free()


func _wait_for_state(ball: Dodgeball, expected_state: int, frames: int = 180) -> bool:
	for frame in frames:
		if ball.state == expected_state:
			return true
		await physics_frame
	return ball.state == expected_state


func _wait_for_target_contact(ball: Dodgeball, target: DodgeballTarget, frames: int = 120) -> bool:
	for frame in frames:
		if ball.global_position.distance_to(target.global_position + Vector3.UP) < 1.0:
			return true
		await physics_frame
	return false


func _count_type(node: Node, type: Variant) -> int:
	var count := 1 if is_instance_of(node, type) else 0
	for child: Node in node.get_children():
		count += _count_type(child, type)
	return count


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
