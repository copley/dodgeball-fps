extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

const REQUIRED_ACTIONS: PackedStringArray = [
	"move_forward", "move_back", "move_left", "move_right", "sprint", "crouch",
	"jump", "throw_ball", "catch_ball", "pickup_ball", "dodge_left",
	"dodge_right", "restart_round", "pause_menu",
]

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_input_map()
	await _test_movement_jump_and_crouch()
	await _test_dodge_and_collision()
	await _test_pause_and_restart()
	await _test_t1_to_t5_5_regressions()
	if failures == 0:
		print("PASS: T6 player actions, pause, reset, and regression suite")
		quit(0)
	else:
		push_error("%d focused test assertion(s) failed" % failures)
		quit(1)


func _test_input_map() -> void:
	for action in REQUIRED_ACTIONS:
		_expect(InputMap.has_action(action), "Input Map contains %s" % action)


func _test_movement_jump_and_crouch() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	var player := main.player as PlayerController
	_expect(is_equal_approx(player.get_movement_speed(false), 7.0), "normal movement speed remains 7.0")
	_expect(is_equal_approx(player.get_movement_speed(true), 10.0), "sprint speed is 10.0")
	_expect(Vector2(1.0, 1.0).normalized().length() <= 1.0, "diagonal movement remains normalized")
	for frame in 8:
		await physics_frame
	_expect(player.is_on_floor(), "player settles on the court floor")
	var grounded_height := player.global_position.y
	player._unhandled_input(_action_event("jump"))
	_expect(player.velocity.y == player.jump_velocity, "Space applies grounded jump velocity")
	player._unhandled_input(_action_event("jump"))
	_expect(player.velocity.y == player.jump_velocity, "second jump while airborne is prevented")
	await physics_frame
	_expect(player.global_position.y > grounded_height, "Space produces upward player movement")
	Input.action_press("crouch")
	player._update_crouch(1.0)
	Input.action_release("crouch")
	var capsule := player.collision_shape.shape as CapsuleShape3D
	_expect(is_equal_approx(capsule.height, player.crouching_height), "crouch lowers collision height")
	var obstruction := StaticBody3D.new()
	var obstruction_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 0.2, 2.0)
	obstruction_shape.shape = box
	obstruction.add_child(obstruction_shape)
	main.add_child(obstruction)
	obstruction.global_position = player.global_position + Vector3(0.0, 1.25, 0.0)
	await physics_frame
	_expect(not player.can_stand_up(), "overhead obstruction prevents standing")
	obstruction.queue_free()
	main.queue_free()
	await process_frame


func _test_dodge_and_collision() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	var player := main.player as PlayerController
	player.rotation.y = 0.0
	_expect(player.start_dodge(-1.0), "left dodge starts")
	_expect(player.dodge_direction.dot(Vector3.LEFT) > 0.99, "left dodge is orientation-relative")
	_expect(not player.start_dodge(-1.0), "active dodge cannot be spammed")
	player.dodge_seconds_remaining = 0.0
	_expect(not player.start_dodge(1.0), "dodge cooldown is enforced")
	player.dodge_cooldown_remaining = 0.0
	_expect(player.start_dodge(1.0), "right dodge starts after cooldown")
	_expect(player.dodge_direction.dot(Vector3.RIGHT) > 0.99, "right dodge is orientation-relative")
	player.global_position = Vector3(9.3, 0.05, 0.0)
	player.dodge_seconds_remaining = player.dodge_duration
	player.dodge_direction = Vector3.RIGHT
	for frame in 20:
		await physics_frame
	_expect(player.global_position.x < 9.7, "CharacterBody dodge does not pass through court wall")
	main.queue_free()
	await process_frame


func _test_pause_and_restart() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	var player := main.player as PlayerController
	var ball := main.ball as Dodgeball
	var bot := main.bot as BotController
	main._unhandled_input(_action_event("pause_menu"))
	_expect(paused, "Escape pause path pauses SceneTree")
	_expect(main.pause_overlay.visible, "pause overlay opens")
	_expect(not main.gameplay_mouse_captured and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "pause releases mouse")
	var paused_ball_position := ball.global_position
	ball.linear_velocity = Vector3(5.0, 0.0, 0.0)
	await create_timer(0.1, true).timeout
	_expect(ball.global_position.is_equal_approx(paused_ball_position), "ball physics stops while paused")
	_expect(not player.start_dodge(-1.0), "gameplay action is blocked while paused")
	player.global_position = Vector3(3.0, 2.0, 4.0)
	main._unhandled_input(_action_event("restart_round"))
	_expect(player.global_position.is_equal_approx(Vector3(3.0, 2.0, 4.0)), "R does not restart through pause menu")
	main._unhandled_input(_action_event("pause_menu"))
	_expect(not paused, "Escape resume path unpauses SceneTree")
	_expect(main.gameplay_mouse_captured, "resume requests mouse recapture")
	player.camera.rotation.x = 0.5
	player.is_eliminated = true
	player.is_crouching = true
	player.dodge_cooldown_remaining = 1.0
	player.catch_seconds_remaining = 1.0
	bot.eliminate()
	main._unhandled_input(_action_event("restart_round"))
	for reset_index in 4:
		main.restart_round()
	_expect(player.global_transform.is_equal_approx(main.player_spawn.global_transform), "R reset restores PlayerSpawn")
	_expect(player.velocity == Vector3.ZERO and player.camera.rotation == Vector3.ZERO, "reset clears velocity and camera pitch")
	_expect(not player.is_eliminated and not player.is_crouching, "reset clears elimination and crouch")
	_expect(player.dodge_cooldown_remaining == 0.0 and player.catch_seconds_remaining == 0.0, "reset clears dodge and catch")
	_expect(ball.state == Dodgeball.BallState.AVAILABLE, "reset restores ball AVAILABLE")
	_expect(ball.global_transform.is_equal_approx(main.ball_spawn.global_transform), "reset restores BallSpawn")
	_expect(
		not bot.is_eliminated
		and bot.global_position.is_equal_approx(main.target_spawn.global_position),
		"reset restores active bot"
	)
	_expect(not main.round_result_label.visible and not main.catch_feedback_label.visible, "reset clears feedback")
	_expect(_count_entities(main, "player") == 1, "five resets leave one player")
	_expect(_count_entities(main, "ball") == 1, "five resets leave one ball")
	_expect(_count_entities(main, "bot") == 1, "five resets leave one bot")
	main.open_pause_menu()
	main._on_menu_restart()
	_expect(not paused and not main.pause_overlay.visible, "menu Restart Round resets and resumes")
	main.queue_free()
	await process_frame


func _action_event(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _test_t1_to_t5_5_regressions() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	var player := main.player as PlayerController
	var ball := main.ball as Dodgeball
	var bot := main.bot as BotController
	_expect(main.get_node_or_null("Court/CourtGraphics") != null, "painted court graphics remain")
	_expect(player.camera != null, "first-person camera remains")
	ball.reset_to(Transform3D(Basis.IDENTITY, player.global_position))
	_expect(player.can_pick_up(ball), "pickup remains available")
	player.give_ball(ball)
	ball.throw(Vector3.FORWARD, player.minimum_throw_speed)
	_expect(ball.is_thrown(), "charged throwing path remains")
	var eliminated_count: Array[int] = [0]
	bot.eliminated.connect(func() -> void: eliminated_count[0] += 1)
	bot.eliminate()
	bot.eliminate()
	_expect(eliminated_count[0] == 1, "bot elimination is single-fire")
	player.reset_to(main.player_spawn.global_transform)
	ball.reset_to(Transform3D(Basis.IDENTITY, player.camera.global_position + Vector3(0.0, 0.0, -1.0)))
	var marker := Marker3D.new()
	main.add_child(marker)
	marker.global_position = ball.global_position
	ball.hold_at(marker)
	ball.throw(player.camera.global_position - ball.global_position, 12.0)
	player.start_catch_window()
	_expect(player.catch_ball(ball), "timed catch remains functional")
	main.queue_free()
	await process_frame


func _count_entities(parent: Node, entity_type: String) -> int:
	var count := 0
	for child in parent.get_children():
		if (
			(entity_type == "player" and child is PlayerController)
			or (entity_type == "ball" and child is Dodgeball)
			or (entity_type == "bot" and child is BotController)
		):
			count += 1
	return count


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
