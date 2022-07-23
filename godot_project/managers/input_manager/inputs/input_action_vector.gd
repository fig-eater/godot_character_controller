extends InputAction
class_name InputActionVector

# some composite component along side normal vector inputs

export(Array, InputEvent) var _left_composite_inputs: Array
export(Array, InputEvent) var _up_composite_inputs: Array
export(Array, InputEvent) var _right_composite_inputs: Array
export(Array, InputEvent) var _down_composite_inputs: Array


func get_composite_input_arrays()->Array:
	return [
		# order matters based on input profile composite directions
		_left_composite_inputs,
		_up_composite_inputs,
		_right_composite_inputs,
		_down_composite_inputs
	]

static func process_vector_input(ie:InputEvent)->Vector2:
	# if ie is InputEventJoypadButton:
	# 	return ie.pressure
	# return float(ie.is_pressed())
	return Vector2()