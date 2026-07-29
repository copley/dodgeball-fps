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
	_expect(InputMap.has_action("toggle_performance"), "F3 diagnostic action exists")
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	var label := main.performance_diagnostics_label as Label
	_expect(label != null and label.visible, "performance overlay is visible by default")
	main._update_performance_diagnostics()
	_expect(label.text.contains("FPS:"), "overlay reports FPS")
	_expect(label.text.contains("Frame:"), "overlay reports frame time")
	_expect(label.text.contains("Physics:"), "overlay reports physics time")
	_expect(label.text.contains("Draw calls:"), "overlay reports draw calls")
	_expect(label.text.contains("Objects:"), "overlay reports rendered objects")
	main._unhandled_input(_action_event("toggle_performance"))
	_expect(not label.visible, "F3 hides the performance overlay")
	main._unhandled_input(_action_event("toggle_performance"))
	_expect(label.visible, "F3 restores the performance overlay")
	_expect(main.player.normal_speed == 7.0, "normal gameplay speed is unchanged")
	_expect(main.player.jump_velocity == 6.5, "jump gameplay value is unchanged")
	_expect(main.get_node_or_null("Court/CourtGraphics") != null, "court design remains present")
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


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
