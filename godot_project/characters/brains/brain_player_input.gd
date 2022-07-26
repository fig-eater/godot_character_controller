extends Brain

var input_profile
onready var character: Node = get_parent() if not character else character

func _ready():
	input_profile = load("/home/frog/dev/guide/godot_character_controller/godot_project/test_profile.json")
	print(InputManager.create_player(0, input_profile, [InputManager.DEVICE_KEYBOARD, InputManager.DEVICE_MOUSE, 0]))
	print(InputManager.connect_input(0, "gameplay_move", self, "_on_gameplay_move"))


func _on_gameplay_move(value:Vector2)->void:
	pass
