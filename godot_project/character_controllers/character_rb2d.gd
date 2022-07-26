extends RigidBody2D
class_name CharacterRB2D
var input_profile

func _ready()->void:
	input_profile = load("/home/frog/dev/guide/godot_character_controller/godot_project/test_profile.json")
	print(InputManager.create_player(0, input_profile, [InputManager.DEVICE_KEYBOARD, InputManager.DEVICE_MOUSE, 0]))
	print(InputManager.connect_input(0, "gameplay_move", self, "_on_gameplay_move"))


var move_value:Vector2

func _physics_process(delta:float):
	linear_velocity = move_value * delta * 2000

func _on_gameplay_move(value)->void:
	print(value)
	move_value = value


