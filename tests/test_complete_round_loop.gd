extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_initial_state_and_player_win()
	await _test_bot_win_and_invalid_balls()
	await _test_pause_and_manual_cancellation()
	await _test_repeated_resets_and_twenty_rounds()
	if failures == 0:
		print("PASS: complete round loop suite, including twenty automatic rounds")
		quit(0)
	else:
		push_error("%d complete-round-loop assertion(s) failed" % failures)
		quit(1)


func _test_initial_state_and_player_win() -> void:
	var main := await _spawn_main()
	main.inter_round_delay = 0.03
	var result_count: Array[int] = [0]
	main.round_ended.connect(func(_winner: int) -> void: result_count[0] += 1)
	_expect(main.round_state == main.RoundState.ACTIVE, "Main starts ACTIVE")
	_throw_at(main.ball, main.bot, Dodgeball.Thrower.HUMAN)
	_expect(main.round_state == main.RoundState.RESOLVING, "human elimination enters RESOLVING")
	_expect(main.accepted_winner == main.RoundWinner.PLAYER, "human elimination records player winner")
	_expect(main.round_result_label.text == "PLAYER WINS" and main.round_result_label.visible, "PLAYER WINS displays immediately")
	_expect(result_count[0] == 1, "human elimination emits one result")
	_expect(_gameplay_is_locked(main), "round result locks player, bot, and ball")
	main._on_bot_eliminated()
	main._on_player_eliminated()
	_expect(main.accepted_winner == main.RoundWinner.PLAYER and result_count[0] == 1, "duplicate eliminations cannot replace or repeat result")
	_expect(not main.round_reset_timer.is_stopped(), "one automatic reset timer remains pending")
	await create_timer(0.06).timeout
	_expect(main.round_state == main.RoundState.ACTIVE, "automatic reset returns to ACTIVE")
	_expect(main.automatic_reset_count == 1, "exactly one automatic reset occurs")
	_expect(_clean_active_state(main), "automatic reset clears result and restores entities")
	await _free_main(main)


func _test_bot_win_and_invalid_balls() -> void:
	var main := await _spawn_main()
	main.inter_round_delay = 0.03
	var result_count: Array[int] = [0]
	main.round_ended.connect(func(_winner: int) -> void: result_count[0] += 1)
	_throw_at(main.ball, main.player, Dodgeball.Thrower.BOT)
	_expect(main.accepted_winner == main.RoundWinner.BOT, "bot throw records bot winner")
	_expect(main.round_result_label.text == "BOT WINS" and result_count[0] == 1, "BOT WINS displays once")
	main.restart_round()
	main.ball.state = Dodgeball.BallState.DEAD
	main.ball._on_body_entered(main.player)
	_expect(main.round_state == main.RoundState.ACTIVE, "dead ball cannot end round")
	main.ball.state = Dodgeball.BallState.AVAILABLE
	main.ball._on_body_entered(main.player)
	_expect(main.round_state == main.RoundState.ACTIVE, "available ball cannot end round")
	_prepare_throw(main.ball, main.player.global_position, Dodgeball.Thrower.BOT)
	main.player.start_catch_window()
	main.ball.global_position = main.player.camera.global_position + Vector3(0.0, 0.0, -1.0)
	main.ball.linear_velocity = Vector3.BACK * 12.0
	_expect(main.player.catch_ball(main.ball), "live bot throw can be caught")
	main.ball._on_body_entered(main.player)
	_expect(main.round_state == main.RoundState.ACTIVE, "caught ball cannot end round")
	await _free_main(main)


func _test_pause_and_manual_cancellation() -> void:
	var main := await _spawn_main()
	main.inter_round_delay = 0.12
	_throw_at(main.ball, main.bot, Dodgeball.Thrower.HUMAN)
	await create_timer(0.03).timeout
	main.open_pause_menu()
	var remaining: float = main.round_reset_timer.time_left
	await create_timer(0.15, true).timeout
	_expect(main.round_state == main.RoundState.RESOLVING, "pause prevents automatic reset")
	_expect(absf(main.round_reset_timer.time_left - remaining) < 0.02, "pause freezes remaining result delay")
	main.close_pause_menu()
	await create_timer(0.15).timeout
	_expect(main.automatic_reset_count == 1 and main.round_state == main.RoundState.ACTIVE, "resume safely completes delayed reset")

	_throw_at(main.ball, main.bot, Dodgeball.Thrower.HUMAN)
	main.restart_round()
	var resets_after_manual: int = main.automatic_reset_count
	await create_timer(0.16).timeout
	_expect(main.round_state == main.RoundState.ACTIVE and main.automatic_reset_count == resets_after_manual, "R-style restart cancels stale automatic reset")

	_throw_at(main.ball, main.bot, Dodgeball.Thrower.HUMAN)
	main.open_pause_menu()
	main._on_menu_restart()
	var resets_after_menu: int = main.automatic_reset_count
	await create_timer(0.16).timeout
	_expect(not paused and main.round_state == main.RoundState.ACTIVE, "menu restart immediately restores ACTIVE")
	_expect(main.automatic_reset_count == resets_after_menu, "menu restart cancels stale automatic reset")
	await _free_main(main)


func _test_repeated_resets_and_twenty_rounds() -> void:
	var main := await _spawn_main()
	for reset_index in 5:
		main.restart_round()
	_expect(_entity_counts_are_one(main), "five manual resets retain one of each entity")
	_expect(main.round_ended.get_connections().size() == 0, "manual resets do not add result connections")
	main.inter_round_delay = 0.001
	var result_count: Array[int] = [0]
	var reset_count: Array[int] = [0]
	main.round_ended.connect(func(_winner: int) -> void: result_count[0] += 1)
	main.round_reset.connect(func() -> void: reset_count[0] += 1)
	for round_index in 20:
		_throw_at(main.ball, main.bot if round_index % 2 == 0 else main.player, Dodgeball.Thrower.HUMAN if round_index % 2 == 0 else Dodgeball.Thrower.BOT)
		_expect(await _wait_for_active(main), "automatic round %d resets" % (round_index + 1))
		_expect(_clean_active_state(main), "automatic round %d restores clean state" % (round_index + 1))
		_expect(_entity_counts_are_one(main), "automatic round %d retains one of each entity" % (round_index + 1))
	_expect(result_count[0] == 20, "twenty rounds emit one result each")
	_expect(reset_count[0] == 20, "twenty rounds perform one reset each")
	_expect(main.automatic_reset_count == 20, "twenty rounds leave no stale automatic timers")
	main.bot.aim_delay = 0.0
	main.ball.reset_to(Transform3D(Basis.IDENTITY, main.bot.global_position + Vector3(0.0, 0.5, -0.7)))
	_expect(await _wait_for_bot_throw(main.bot), "bot retrieves and throws after automatic reset")
	await _free_main(main)


func _throw_at(ball: Dodgeball, target: Node3D, thrower: int) -> void:
	_prepare_throw(ball, target.global_position + Vector3.UP, thrower)
	ball._on_body_entered(target)


func _prepare_throw(ball: Dodgeball, position: Vector3, thrower: int) -> void:
	ball.reset_to(Transform3D(Basis.IDENTITY, position))
	var marker := Marker3D.new()
	root.add_child(marker)
	marker.global_position = position
	ball.hold_at(marker)
	ball.throw(Vector3.FORWARD, 12.0, thrower)
	marker.queue_free()


func _wait_for_active(main: Node3D, frames: int = 30) -> bool:
	for frame in frames:
		if main.round_state == main.RoundState.ACTIVE:
			return true
		await process_frame
	return main.round_state == main.RoundState.ACTIVE


func _wait_for_bot_throw(bot: BotController, frames: int = 120) -> bool:
	for frame in frames:
		if bot.ball != null and bot.ball.state == Dodgeball.BallState.THROWN:
			return true
		await physics_frame
	return false


func _gameplay_is_locked(main: Node3D) -> bool:
	return (
		not main.player.gameplay_enabled
		and not main.bot.gameplay_enabled
		and not main.ball.gameplay_enabled
		and main.ball.current_thrower == Dodgeball.Thrower.NONE
		and main.ball.linear_velocity == Vector3.ZERO
	)


func _clean_active_state(main: Node3D) -> bool:
	return (
		main.round_state == main.RoundState.ACTIVE
		and main.accepted_winner == main.RoundWinner.NONE
		and not main.round_result_label.visible
		and main.player.gameplay_enabled
		and not main.player.is_eliminated
		and main.bot.gameplay_enabled
		and main.bot.is_active
		and not main.bot.is_eliminated
		and main.ball.gameplay_enabled
		and main.ball.state == Dodgeball.BallState.AVAILABLE
		and main.ball.current_thrower == Dodgeball.Thrower.NONE
		and main.ball.hold_position == null
		and main.ball.linear_velocity == Vector3.ZERO
		and main.ball.angular_velocity == Vector3.ZERO
	)


func _entity_counts_are_one(main: Node) -> bool:
	return (
		_count_type(main, PlayerController) == 1
		and _count_type(main, BotController) == 1
		and _count_type(main, Dodgeball) == 1
	)


func _count_type(node: Node, type: Variant) -> int:
	var count := 1 if is_instance_of(node, type) else 0
	for child: Node in node.get_children():
		count += _count_type(child, type)
	return count


func _spawn_main() -> Node3D:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	return main


func _free_main(main: Node3D) -> void:
	if paused:
		paused = false
	main.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
