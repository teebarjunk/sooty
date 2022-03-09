@tool
extends Node

var config := ConfigFile.new()

func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
	
	if config.load("res://config.cfg") != OK:
		push_error("Couldn't load config.cfg.")
	else:
		print("CONFIG", config.get_sections())
	
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		set_process(false)
	
	if Input.is_action_just_pressed("reload_scene"):
		get_tree().reload_current_scene()
		
	elif Input.is_action_just_pressed("quick_save"):
		return
		SaveManager.save_to_slot("test")
#		var file_path = "user://quick_save.scn"
#		var scene = PackedScene.new()
#		get_tree().current_scene.set_meta("STATE", State._get_changed_states())
#		scene.pack(get_tree().current_scene)
#		ResourceSaver.save(file_path, scene, ResourceSaver.FLAG_COMPRESS)
#		get_viewport().set_input_as_handled()
#		print("Quick saved to: %s." % file_path)
		
	elif Input.is_action_just_pressed("quick_load"):
		return
#		var file_path := "user://quick_save.scn"
#		get_tree().change_scene_to(load(file_path))
#		await get_tree().process_frame
#		State._load_state(get_tree().current_scene.get_meta("STATE"))
#		print("Quick loaded from: %s." % file_path)
#		print("S", get_tree().get_first_node_in_group("sooty_stack").stack._stack)
