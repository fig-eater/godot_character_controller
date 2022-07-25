extends Node

var cool_profile := InputProfile.new()

func _ready():
	print(cool_profile.load_profile_json("/home/frog/dev/guide/godot_character_controller/godot_project/test_profile2.json"))

	cool_profile.save_profile_json("/home/frog/dev/guide/godot_character_controller/godot_project/test_profile3.json")
