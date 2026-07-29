extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const BALL_SCENE: PackedScene = preload("res://scenes/ball.tscn")
const TARGET_SCENE: PackedScene = preload("res://scenes/target.tscn")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_successful_catch_and_possession_transfer()
	await _test_failed_timing()
	await _test_front_detection()
	await _test_invalid_state_rejection()
	await _test_duplicate_prevention()
	await _test_t1_to_t4_regressions()
	if failures == 0:
		print("PASS: timed catch and T1-T4 regression suite")
		quit(0)
	else:
		push_error("%d focused test assertion(s) failed" % failures)
		quit(1)


func _spawn_player_and_ball() -> Array[Node]:
	var player: PlayerController = PLAYER_SCENE.instantiate()
	var ball: Dodgeball = BALL_SCENE.instantiate()
	root.add_child(player)
	root.add_child(ball)
	player.global_position = Vector3.ZERO
	ball.reset_to(Transform3D(Basis.IDENTITY, Vector3(0.0, 1.6, -1.5)))
	return [player, ball]


func _make_incoming(ball: Dodgeball, player: PlayerController) -> void:
	var launch_position := player.camera.global_position + Vector3(0.0, 0.0, -1.5)
	ball.launch_from(
		Transform3D(Basis.IDENTITY, launch_position),
		player.camera.global_position - launch_position,
		12.0
	)


func _test_successful_catch_and_possession_transfer() -> void:
	var nodes := _spawn_player_and_ball()
	var player := nodes[0] as PlayerController
	var ball := nodes[1] as Dodgeball
	_make_incoming(ball, player)
	player.start_catch_window()
	_expect(player.catch_ball(ball), "incoming thrown ball is caught during the window")
	_expect(player.held_ball == ball, "successful catch transfers possession")
	_expect(ball.state == Dodgeball.BallState.HELD, "caught ball ends in HELD only")
	_expect(ball.linear_velocity == Vector3.ZERO, "successful catch clears linear velocity")
	_expect(ball.angular_velocity == Vector3.ZERO, "successful catch clears angular velocity")
	_expect(not player.is_eliminated, "successful catch prevents player elimination")
	player.queue_free()
	ball.queue_free()
	await process_frame


func _test_failed_timing() -> void:
	var nodes := _spawn_player_and_ball()
	var player := nodes[0] as PlayerController
	var ball := nodes[1] as Dodgeball
	var early_position := player.camera.global_position + Vector3(0.0, 0.0, -6.0)
	ball.launch_from(
		Transform3D(Basis.IDENTITY, early_position),
		player.camera.global_position - early_position,
		12.0
	)
	player.start_catch_window()
	_expect(not player.catch_ball(ball), "early catch fails before the ball enters range")
	player.catch_seconds_remaining = 0.0
	ball.global_position = player.camera.global_position + Vector3(0.0, 0.0, -1.5)
	_expect(not player.catch_ball(ball), "catch fails after the window closes")
	_expect(ball.state == Dodgeball.BallState.THROWN, "failed timing leaves the ball thrown")
	player.queue_free()
	ball.queue_free()
	await process_frame


func _test_front_detection() -> void:
	var nodes := _spawn_player_and_ball()
	var player := nodes[0] as PlayerController
	var ball := nodes[1] as Dodgeball
	var behind_position := player.camera.global_position + Vector3(0.0, 0.0, 1.5)
	ball.launch_from(
		Transform3D(Basis.IDENTITY, behind_position),
		player.camera.global_position - behind_position,
		12.0
	)
	player.start_catch_window()
	_expect(not player.catch_ball(ball), "incoming ball behind the player cannot be caught")
	player.queue_free()
	ball.queue_free()
	await process_frame


func _test_invalid_state_rejection() -> void:
	var nodes := _spawn_player_and_ball()
	var player := nodes[0] as PlayerController
	var ball := nodes[1] as Dodgeball
	player.start_catch_window()
	_expect(not player.catch_ball(ball), "AVAILABLE ball cannot be caught")
	player.give_ball(ball)
	player.held_ball = null
	player.start_catch_window()
	_expect(not player.catch_ball(ball), "HELD ball cannot be caught")
	player.queue_free()
	ball.queue_free()
	await process_frame


func _test_duplicate_prevention() -> void:
	var nodes := _spawn_player_and_ball()
	var player := nodes[0] as PlayerController
	var ball := nodes[1] as Dodgeball
	var caught_count: Array[int] = [0]
	ball.caught.connect(func() -> void: caught_count[0] += 1)
	_make_incoming(ball, player)
	player.start_catch_window()
	_expect(player.catch_ball(ball), "first catch succeeds")
	_expect(not ball.catch_at(player.ball_hold_position), "caught ball cannot be caught twice")
	_expect(caught_count[0] == 1, "catch signal emits exactly once")
	_expect(not ball.is_thrown(), "ball cannot be THROWN and HELD")
	player.queue_free()
	ball.queue_free()
	await process_frame


func _test_t1_to_t4_regressions() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	_expect(main.get_node_or_null("Court") != null, "T1 main court still loads")
	var player := main.get("player") as PlayerController
	var ball := main.get("ball") as Dodgeball
	var target := main.get("target") as DodgeballTarget
	_expect(player != null and player.camera != null, "T2 player and camera still load")
	ball.reset_to(Transform3D(Basis.IDENTITY, player.global_position))
	_expect(player.can_pick_up(ball), "T3 available ball remains pickup eligible")
	player.give_ball(ball)
	_expect(ball.state == Dodgeball.BallState.HELD, "T3 pickup still holds the ball")
	ball.throw(Vector3.FORWARD, player.minimum_throw_speed)
	_expect(ball.state == Dodgeball.BallState.THROWN, "T3 held ball still throws")
	_expect(is_equal_approx(ball.linear_velocity.length(), player.minimum_throw_speed), "T3 throw speed is preserved")
	main.call("_on_ball_valid_player_hit", player)
	_expect(player.is_eliminated, "uncaught valid player hit still eliminates")
	var elimination_count: Array[int] = [0]
	target.eliminated.connect(func() -> void: elimination_count[0] += 1)
	target.eliminate()
	target.eliminate()
	_expect(target.is_eliminated and elimination_count[0] == 1, "T4 target eliminates exactly once")
	main.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
