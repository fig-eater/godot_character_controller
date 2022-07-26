extends InputAction
class_name InputActionVector

# some composite component along side normal vector inputs

export(Array, InputEvent) var _native_inputs: Array
export(Array, InputEvent) var _left_inputs: Array
export(Array, InputEvent) var _up_inputs: Array
export(Array, InputEvent) var _right_inputs: Array
export(Array, InputEvent) var _down_inputs: Array

var _last_input_native: bool = false

func _init():
	value = Vector2()

func get_composite_input_arrays()->Array:
	return [
		# order matters based on input profile composite directions
		_left_inputs,
		_up_inputs,
		_right_inputs,
		_down_inputs
	]

static func process_vector_input(ie:InputEvent)->Vector2:
	# if ie is InputEventJoypadButton:
	# 	return ie.pressure
	# return float(ie.is_pressed())
	return Vector2()