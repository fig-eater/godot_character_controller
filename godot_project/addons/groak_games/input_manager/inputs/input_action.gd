extends Resource
class_name InputAction

var prev_value

var value

var _event_handlers := []

func process_input(event:InputEvent)->void:
	pass

func get_value():
	pass

func get_scalar()->float:
	return 0.0

func get_vector()->Vector2:
	return Vector2()