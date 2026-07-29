extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_spawn_detection_and_pickup()
	await _test_aim_throw_and_identity()
	await _test_hits_catch_and_dead_ball()
	await _test_ten_cycles_pause_and_reset()
	if failures == 0:
		print("PASS: basic ball-playing bot suite, including ten cycles")
		quit(0)
	else:
		push_error("%d bot test assertion(s) failed" % failures)
		quit(1)


func _test_spawn_detection_and_pickup() -> void:
	var main := await _spawn_main()
	var bot := main.bot as BotController
	var ball := main.ball as Dodgeball
	_expect(_count_type(main, PlayerController) == 1, "exactly one player exists")
	_expect(_count_type(main, BotController) == 1, "exactly one bot exists")
	_expect(_count_type(main, Dodgeball) == 1, "exactly one ball exists")
	_expect(
		bot.global_position.distance_to(main.target_spawn.global_position) < 0.2,
		"bot spawns at TargetSpawn"
	)
	var toward_player: Vector3 = (
		(main.player as PlayerController).global_position - bot.global_position
	).normalized()
	_expect((-bot.global_basis.z).dot(toward_player) > 0.99, "bot faces the player at spawn")
	await physics_frame
	_expect(bot.state == BotController.BotState.MOVE_TO_BALL, "bot detects the AVAILABLE ball")
	bot.global_position = ball.global_position + Vector3(0.0, 0.0, 0.8)
	await physics_frame
	_expect(bot.held_ball == ball and ball.state == Dodgeball.BallState.HELD, "bot reaches and picks up the ball")
	for invalid_state: int in [
		Dodgeball.BallState.HELD,
		Dodgeball.BallState.THROWN,
		Dodgeball.BallState.DEAD,
	]:
		bot.held_ball = null
		ball.state = invalid_state
		_expect(not bot.try_pick_up_ball(), "bot rejects ball state %d" % invalid_state)
	await _free_main(main)


func _test_aim_throw_and_identity() -> void:
	var main := await _spawn_main()
	var bot := main.bot as BotController
	var ball := main.ball as Dodgeball
	bot.aim_delay = 0.25
	ball.reset_to(Transform3D(Basis.IDENTITY, bot.global_position + Vector3(0.0, 0.5, -0.8)))
	bot.held_ball = null
	_expect(bot.try_pick_up_ball(), "bot picks up available ball for aiming")
	_expect(bot.state == BotController.BotState.HOLD_BALL, "pickup enters HOLD_BALL")
	bot.transition_to(BotController.BotState.AIM)
	_expect(bot.state == BotController.BotState.AIM, "pickup enters AIM through HOLD_BALL")
	var aim_time := bot.state_seconds_remaining
	bot._physics_process(0.1)
	_expect(
		bot.state == BotController.BotState.AIM
		and bot.state_seconds_remaining < aim_time
		and bot.state_seconds_remaining > 0.0,
		"bot waits through configured aim delay"
	)
	var throw_count: Array[int] = [0]
	bot.ball_thrown.connect(func() -> void: throw_count[0] += 1)
	_expect(await _wait_for_state(bot, BotController.BotState.WAIT_FOR_BALL), "bot throws after aiming")
	_expect(ball.state == Dodgeball.BallState.THROWN, "bot throw transitions HELD to THROWN")
	_expect(ball.current_thrower == Dodgeball.Thrower.BOT, "bot throw records bot identity")
	_expect(
		ball.linear_velocity.normalized().dot(
			(main.player.global_position + Vector3.UP * bot.target_height_offset - ball.global_position).normalized()
		) > 0.95,
		"bot throws toward the player"
	)
	ball._on_body_entered(bot)
	_expect(not bot.is_eliminated and ball.state == Dodgeball.BallState.THROWN, "bot cannot eliminate itself")
	_expect(throw_count[0] == 1, "bot emits one throw action")
	await _free_main(main)


func _test_hits_catch_and_dead_ball() -> void:
	var main := await _spawn_main()
	var player := main.player as PlayerController
	var bot := main.bot as BotController
	var ball := main.ball as Dodgeball
	var bot_eliminations: Array[int] = [0]
	bot.eliminated.connect(func() -> void: bot_eliminations[0] += 1)
	_prepare_throw(ball, bot.global_position + Vector3.UP, Vector3.FORWARD, Dodgeball.Thrower.HUMAN)
	ball._on_body_entered(bot)
	ball._on_body_entered(bot)
	_expect(bot.is_eliminated and bot_eliminations[0] == 1, "human throw eliminates bot exactly once")
	main.restart_round()
	_prepare_throw(ball, player.camera.global_position + Vector3.FORWARD, Vector3.BACK, Dodgeball.Thrower.BOT)
	ball._on_body_entered(player)
	_expect(player.is_eliminated and not bot.is_active, "bot throw eliminates player once and stops bot play")
	ball._on_body_entered(player)
	_expect(player.is_eliminated, "duplicate bot hit does not change elimination")
	main.restart_round()
	_prepare_throw(ball, player.camera.global_position + Vector3(0.0, 0.0, -1.0), Vector3.BACK, Dodgeball.Thrower.BOT)
	player.start_catch_window()
	_expect(player.catch_ball(ball), "player catches a bot throw")
	_expect(player.held_ball == ball and ball.current_thrower == Dodgeball.Thrower.NONE, "catch transfers possession and clears thrower")
	main.restart_round()
	var floor := main.get_node("Court/Geometry/Floor")
	_prepare_throw(ball, Vector3(4.0, 1.0, 4.0), Vector3.DOWN, Dodgeball.Thrower.BOT)
	ball._on_body_entered(floor)
	ball._on_body_entered(player)
	_expect(not player.is_eliminated and not bot.is_eliminated, "bounced or dead ball eliminates neither")
	ball.seconds_since_throw = ball.pickup_grace_seconds
	ball.linear_velocity = Vector3.ZERO
	ball._physics_process(0.0)
	_expect(ball.is_available(), "missed bot throw becomes AVAILABLE after DEAD")
	bot.global_position = ball.global_position + Vector3(0.0, 0.0, 0.8)
	bot.throw_recovery_delay = 0.0
	bot.transition_to(BotController.BotState.SEEK_BALL)
	_expect(await _wait_for_bot_possession(bot, ball), "bot retrieves the available missed throw")
	await _free_main(main)


func _test_ten_cycles_pause_and_reset() -> void:
	var main := await _spawn_main()
	var bot := main.bot as BotController
	var ball := main.ball as Dodgeball
	bot.aim_delay = 0.02
	bot.throw_recovery_delay = 0.02
	var throw_count: Array[int] = [0]
	bot.ball_thrown.connect(func() -> void: throw_count[0] += 1)
	for cycle in 10:
		ball.reset_to(Transform3D(Basis.IDENTITY, bot.global_position + Vector3(0.0, 0.5, -0.7)))
		bot.held_ball = null
		bot.transition_to(BotController.BotState.SEEK_BALL)
		_expect(
			await _wait_for_throw_count(throw_count, cycle + 1),
			"retrieve-and-throw cycle %d completes" % (cycle + 1)
		)
		_expect(_count_type(main, Dodgeball) == 1, "cycle %d retains one ball" % (cycle + 1))
		_expect(ball.current_thrower == Dodgeball.Thrower.BOT, "cycle %d retains bot ownership" % (cycle + 1))
	var timer_before_pause := bot.state_seconds_remaining
	var state_before_pause := bot.state
	main.open_pause_menu()
	await create_timer(0.1, true).timeout
	_expect(
		bot.state == state_before_pause and bot.state_seconds_remaining == timer_before_pause,
		"pause freezes bot state and timer"
	)
	main.close_pause_menu()
	bot.eliminate()
	var eliminated_position := bot.global_position
	await physics_frame
	_expect(bot.global_position.is_equal_approx(eliminated_position), "bot stops acting after elimination")
	for reset_index in 5:
		main.restart_round()
	_expect(_count_type(main, PlayerController) == 1, "five resets retain one player")
	_expect(_count_type(main, BotController) == 1, "five resets retain one bot")
	_expect(_count_type(main, Dodgeball) == 1, "five resets retain one ball")
	_expect(ball.is_available() and ball.current_thrower == Dodgeball.Thrower.NONE, "reset clears ball state and ownership")
	_expect(bot.is_active and not bot.is_eliminated, "reset restores active bot with cleared timers")
	main.open_pause_menu()
	main._on_menu_restart()
	_expect(not paused and bot.is_active and ball.is_available(), "menu restart restores active exchange")
	await _free_main(main)


func _prepare_throw(ball: Dodgeball, position: Vector3, direction: Vector3, thrower: int) -> void:
	ball.reset_to(Transform3D(Basis.IDENTITY, position))
	var marker := Marker3D.new()
	root.add_child(marker)
	marker.global_position = position
	ball.hold_at(marker)
	ball.throw(direction, 12.0, thrower)
	marker.queue_free()


func _wait_for_state(bot: BotController, expected: int, frames: int = 120) -> bool:
	for frame in frames:
		if bot.state == expected:
			return true
		await physics_frame
	return bot.state == expected


func _wait_for_throw_count(count: Array[int], expected: int, frames: int = 120) -> bool:
	for frame in frames:
		if count[0] >= expected:
			return true
		await physics_frame
	return count[0] >= expected


func _wait_for_bot_possession(bot: BotController, ball: Dodgeball, frames: int = 60) -> bool:
	for frame in frames:
		if bot.held_ball == ball:
			return true
		await physics_frame
	return bot.held_ball == ball


func _spawn_main() -> Node3D:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	return main


func _free_main(main: Node3D) -> void:
	main.queue_free()
	await process_frame


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
