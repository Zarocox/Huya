extends Area2D

@export var room_id: String = "ohm"
@export_file("*.tscn") var target_scene: String = "res://room.tscn"


func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	else:
		Globals.current_room = room_id
		get_tree().change_scene_to_file.call_deferred(target_scene)
