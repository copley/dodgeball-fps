extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(
		ProjectSettings.get_setting("physics/common/physics_interpolation", false),
		"physics interpolation is enabled"
	)
	_expect(
		ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d", 0) == 1,
		"2x MSAA is selected"
	)
	_expect(
		is_equal_approx(
			ProjectSettings.get_setting("rendering/scaling_3d/scale", 0.0),
			1.0
		),
		"native 100% render scale is selected"
	)
	_expect(
		ProjectSettings.get_setting("display/window/vsync/vsync_mode", 0) == 1,
		"VSync is enabled"
	)
	_expect(
		ProjectSettings.get_setting(
			"rendering/lights_and_shadows/directional_shadow/size",
			0
		) == 2048,
		"directional shadow quality is moderate"
	)
	_expect(InputMap.has_action("toggle_performance"), "F3 diagnostic action exists")
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	var label := main.performance_diagnostics_label as Label
	_expect(label != null and label.visible, "performance overlay is visible by default")
	main._update_performance_diagnostics()
	_expect(label.text.contains("FPS:"), "overlay reports FPS")
	_expect(label.text.contains("Frame:"), "overlay reports frame time")
	_expect(label.text.contains("Average:"), "overlay reports rolling average frame time")
	_expect(label.text.contains("Maximum:"), "overlay reports rolling maximum frame time")
	_expect(label.text.contains("Physics:"), "overlay reports physics time")
	_expect(label.text.contains("Draw calls:"), "overlay reports draw calls")
	_expect(label.text.contains("Objects:"), "overlay reports rendered objects")
	main._unhandled_input(_action_event("toggle_performance"))
	_expect(not label.visible, "F3 hides the performance overlay")
	main._unhandled_input(_action_event("toggle_performance"))
	_expect(label.visible, "F3 restores the performance overlay")
	_expect(main.player.normal_speed == 7.0, "normal gameplay speed is unchanged")
	_expect(main.player.sprint_speed == 10.0, "sprint gameplay value is unchanged")
	_expect(main.player.jump_velocity == 6.5, "jump gameplay value is unchanged")
	_expect(main.player.dodge_speed == 12.0, "dodge gameplay value is unchanged")
	_expect(main.player.mouse_sensitivity == 0.002, "mouse sensitivity is unchanged")
	_expect(is_equal_approx(main.ball.mass, 0.45), "ball mass is unchanged")
	_expect(is_equal_approx(main.ball.linear_damp, 0.8), "ball damping is unchanged")
	_expect(main.get_node_or_null("Court/CourtGraphics") != null, "court design remains present")
	_test_court_invariants(main)
	_test_render_invariants(main)
	main.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: performance diagnostics and smoothing suite")
		quit(0)
	else:
		push_error("%d performance test assertion(s) failed" % failures)
		quit(1)


func _action_event(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _test_court_invariants(main: Node3D) -> void:
	var court := main.get_node("Court")
	var floor_shape := court.get_node(
		"Geometry/Floor/CollisionShape3D"
	).shape as BoxShape3D
	_expect(floor_shape.size == Vector3(20.0, 0.5, 30.0), "floor collision dimensions are unchanged")
	_expect(
		court.get_node("SpawnMarkers/PlayerSpawn").position == Vector3(0.0, 0.0, 10.0),
		"player spawn transform is unchanged"
	)
	_expect(
		court.get_node("SpawnMarkers/BallSpawn").position == Vector3(0.0, 0.5, 0.0),
		"ball spawn transform is unchanged"
	)
	_expect(
		court.get_node("SpawnMarkers/TargetSpawn").position == Vector3(0.0, 0.0, -10.0),
		"target spawn transform is unchanged"
	)
	var graphics := court.get_node("CourtGraphics")
	_expect(
		graphics.get_node("NearBoundary").position.y >= 0.035,
		"court markings have depth-safe transforms"
	)
	_expect(
		_find_collision_node(graphics) == null,
		"court markings remain collision-free"
	)
	_expect(_count_type(main, PlayerController) == 1, "exactly one player remains")
	_expect(_count_type(main, Dodgeball) == 1, "exactly one ball remains")
	_expect(_count_type(main, DodgeballTarget) == 1, "exactly one target remains")


func _test_render_invariants(main: Node3D) -> void:
	var environment := main.get_node("WorldEnvironment").environment as Environment
	_expect(not environment.ssao_enabled, "SSAO remains disabled")
	_expect(not environment.ssil_enabled, "SSIL remains disabled")
	_expect(not environment.ssr_enabled, "SSR remains disabled")
	_expect(not environment.glow_enabled, "glow remains disabled")
	_expect(not environment.volumetric_fog_enabled, "volumetric fog remains disabled")
	_expect(
		ProjectSettings.get_setting("rendering/anti_aliasing/quality/screen_space_aa", 0) == 0,
		"overlapping screen-space anti-aliasing remains disabled"
	)


func _find_collision_node(node: Node) -> CollisionObject3D:
	if node is CollisionObject3D:
		return node as CollisionObject3D
	for child: Node in node.get_children():
		var collision := _find_collision_node(child)
		if collision != null:
			return collision
	return null


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
