extends Node


func _ready() -> void:
	call_deferred("_activate_server_authority")


func _activate_server_authority() -> void:
	var match_root := get_parent()
	if match_root != null and bool(match_root.get("is_server_instance")):
		match_root.call("_set_entities_authoritative")
