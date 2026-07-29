class_name DodgeballTarget
extends StaticBody3D

signal eliminated

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var is_eliminated: bool = false


func eliminate() -> void:
	if is_eliminated:
		return
	is_eliminated = true
	collision_shape.set_deferred("disabled", true)
	mesh.material_override = _create_eliminated_material()
	eliminated.emit()


func _create_eliminated_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.18, 0.2, 1.0)
	material.roughness = 0.9
	return material
