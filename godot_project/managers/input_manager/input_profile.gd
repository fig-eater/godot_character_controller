extends Resource
class_name InputProfile

enum {
	# order matters
	COMPOSITE_LEFT  = 0
	COMPOSITE_UP    = 1
	COMPOSITE_RIGHT = 2
	COMPOSITE_DOWN  = 3
}


const _MODIFIERS := PoolStringArray(["alt", "shift", "control", "meta", "command" ])
const _KEY_FIELDS := PoolStringArray(["physical_scancode", "scancode", "unicode"])

export(Array, Resource) var _actions: Array
# Dictionary(InputEvent,Array(InputActionData))
var _input_event_map: Dictionary

func process_input(event:InputEvent)->void:
	if not _input_event_map and _actions:
		_create_input_event_map()

	for ie in _input_event_map:
		if ie.shortcut_match(event):
			var action_list: Array = _input_event_map[ie]
			for action_data in action_list:
				action_data.process_input(event)


func _create_input_event_map()->void:
	for action in _actions:
		if action is InputActionScalar:
			for input in action._inputs:
				var data_list: Array =_input_event_map.get(input, [])
				if not _input_event_map.has(input):
					_input_event_map[input] = data_list
				var data := InputActionData.new()
				data.action = action
				data_list.append(data)
		elif action is InputActionVector:
			var composite_input_arrays: Array = action.get_composite_input_arrays()
			for composite_direction in composite_input_arrays.size():
				for input in composite_input_arrays[composite_direction]:
					var data_list: Array =_input_event_map.get(input, [])
					if not _input_event_map.has(input):
						_input_event_map[input] = data_list
					var data := InputActionCompositeData.new()
					data.composite_direction = composite_direction
					data.action = action
					data_list.append(data)


func save_profile_json(path:String)->int:
	var action_dicts := []

	for action in _actions:
		if action is InputActionScalar:
			var input_dicts := []
			for ie in action._inputs:
				input_dicts.append(_convert_input_event_to_simple_dict(ie))

			action_dicts.append({
				"type": "Scalar",
				"name": action.resource_name,
				"inputs": input_dicts
			})
		elif action is InputActionVector:
			var left_input_dicts := []
			for ie in action._left_inputs:
				left_input_dicts.append(_convert_input_event_to_simple_dict(ie))
			var up_input_dicts := []
			for ie in action._up_inputs:
				up_input_dicts.append(_convert_input_event_to_simple_dict(ie))
			var right_input_dicts := []
			for ie in action._right_inputs:
				right_input_dicts.append(_convert_input_event_to_simple_dict(ie))
			var down_input_dicts := []
			for ie in action._down_inputs:
				down_input_dicts.append(_convert_input_event_to_simple_dict(ie))

			var native_input_dicts := []
			for native_input in action._native_inputs:
				native_input_dicts.append(_convert_input_event_to_simple_dict(native_input, true))

			action_dicts.append({
				"type": "Vector",
				"name": action.resource_name,
				"native_inputs": native_input_dicts,
				"left_inputs": left_input_dicts,
				"up_inputs": up_input_dicts,
				"right_inputs": right_input_dicts,
				"down_inputs": down_input_dicts
			})
		else:
			return ERR_CANT_RESOLVE

	var json_string := JSON.print({"name":  resource_name, "actions": action_dicts}, "\t")

	var f := File.new()
	var err := f.open(path, File.WRITE)
	if err:
		return err
	f.store_string(json_string)
	f.close()

	return OK


func load_profile_json(path:String)->int:
	var f := File.new()
	var err := f.open(path, File.READ)
	if err:
		return err
	var json_string = f.get_as_text()
	f.close()

	var json_result = JSON.parse(json_string)
	if json_result.error:
		print(json_result.error_line, "\n", json_result.error_string)
		return json_result.error
	if typeof(json_result.result) != TYPE_DICTIONARY:
		return ERR_FILE_UNRECOGNIZED

	var raw_dict: Dictionary = json_result.result
	match raw_dict:
		{"name": var profile_name, "actions": [..]}:
			resource_name = profile_name
			for raw_action in raw_dict.actions:
				if "type" in raw_action: raw_action.type = raw_action.type.to_upper()
				var action: InputAction
				match raw_action:
					{"type": "SCALAR", "name": var action_name, "inputs": [..]}:
						action = InputActionScalar.new()
						action.resource_name = action_name
						for ie in raw_action.inputs:
							action._inputs.append(_convert_simple_dict_to_input_event(ie))
					{"type": "VECTOR", "name": var action_name, "left_inputs": [..], "up_inputs": [..], "right_inputs": [..], "down_inputs": [..], "native_inputs": [..]}:
						action = InputActionVector.new()
						action.resource_name = action_name
						for field in ["left_inputs", "up_inputs", "right_inputs", "down_inputs"]:
							for ie in raw_action.get(field):
								action.get("_"+field).append(_convert_simple_dict_to_input_event(ie))
						for ie in raw_action.native_inputs:
							action._native_inputs.append(_convert_simple_dict_to_input_event(ie, true))
					_:
						return ERR_BUG
				_actions.append(action)
		_:
			return ERR_BUG

	return OK

static func _convert_simple_dict_to_input_event(ie_dict:Dictionary, allow_native_vec2d_events:bool = false)->InputEvent:
	var ie: InputEvent
	if "type" in ie_dict: ie_dict.type = ie_dict.type.to_upper()

	match ie_dict:
		{"type": "MOUSEBUTTON", "button_index": var button_index, ..}:
			ie = InputEventMouseButton.new()
			match typeof(button_index):
				TYPE_STRING:
					ie.button_index = ButtonList[button_index]
				TYPE_REAL, TYPE_INT:
					ie.button_index = button_index
				_:
					return null
			for field in _MODIFIERS:
				ie.set(field, ie_dict.get(field,false))
		{"type": "JOYPADBUTTON", "button_index": var button_index}:
			ie = InputEventJoypadButton.new()
			match typeof(button_index):
				TYPE_STRING:
					ie.button_index = JoyStickList.get(button_index.to_upper(), 0)
				TYPE_REAL, TYPE_INT:
					ie.button_index = button_index
				_:
					return null
		{"type": "JOYPADMOTION", "axis": var axis}:
			ie = InputEventJoypadMotion.new()
			match typeof(axis):
				TYPE_STRING:
					ie.axis = JoyAxes.get(axis.to_upper(),0)
				TYPE_REAL, TYPE_INT:
					ie.axis = axis
				_:
					return null
		{"type": "MOUSEMOTION"}:
			if allow_native_vec2d_events:
				ie = InputEventMouseMotion.new()
		{"type": "KEY", ..}:
				ie = InputEventKey.new()
				for field in _MODIFIERS:
					ie.set(field, ie_dict.get(field,false))

				for field in _KEY_FIELDS:
					if field in ie_dict:
						var value = ie_dict.get(field)
						match typeof(value):
							TYPE_STRING:
								var sc := OS.find_scancode_from_string(value.to_upper())
								if sc:
									ie.set(field, sc)
								else:
									assert(false)
									return null
							TYPE_REAL, TYPE_INT: # this should only really be "real"
								ie.set(field, value)
							_:
								assert(false)
								return null
		_:
			# @todo add all input types
			assert(false)
	return ie

static func _convert_input_event_to_simple_dict(ie:InputEvent, allow_native_vec2d_events:bool = false)->Dictionary:
	var ie_dict := {}
	match ie.get_class():
		"InputEventMouseButton":
			ie_dict.type = "MouseButton"
			for field in _MODIFIERS:
				var v: bool = ie.get(field)
				if v:
					ie_dict[field] = v
			continue
		"InputEventJoypadButton":
			ie_dict.type = "JoypadButton"
			ie_dict.button_index = ie.button_index
		"InputEventJoypadMotion":
			ie_dict.type = "JoypadMotion"
			ie_dict.axis = ie.axis
		"InputEventMouseMotion":
			ie_dict.type = "MouseMotion"
			if not allow_native_vec2d_events:
				assert(false)
				return {}
		"InputEventKey":
			ie_dict.type = "Key"
			for field in _KEY_FIELDS:
				if ie.get(field):
					ie_dict[field] = ie.get(field)

			for field in _MODIFIERS:
				var v: bool = ie.get(field)
				if v:
					ie_dict[field] = v
		_:
			# @todo add all input types
			assert(false)
	return ie_dict




class InputActionData:
	extends Reference
	var action:InputActionScalar
	func process_input(event:InputEvent):

		pass


class InputActionCompositeData:
	extends Reference
	var action:InputActionVector

	var composite_direction := COMPOSITE_LEFT
	func process_input(event:InputEvent)->void:
		if event.is_pressed():
			match composite_direction:
				COMPOSITE_LEFT:
					action.value.x = -get_input_value(event)
				COMPOSITE_RIGHT:
					action.value.x = get_input_value(event)
				COMPOSITE_UP:
					action.value.y = -get_input_value(event)
				COMPOSITE_DOWN:
					action.value.y = get_input_value(event)
		else:
			match composite_direction:
				COMPOSITE_LEFT:
					if action.value.x < 0:
						action.value.x = 0
				COMPOSITE_RIGHT:
					if action.value.x > 0:
						action.value.x = 0
				COMPOSITE_UP:
					if action.value.y < 0:
						action.value.y = 0
				COMPOSITE_DOWN:
					if action.value.y > 0:
						action.value.y = 0

	static func get_input_value(ie:InputEvent)->float:
		if ie is InputEventJoypadButton:
			return ie.pressure
		elif ie is InputEventJoypadMotion:
			return ie.axis_value

		# @todo midi input
		return float(ie.is_pressed())


# @todo remove in 4.0 :-)
# in 3.x you cannot access built-in enums as const dictionaries
enum JoyStickList {
	SONY_CIRCLE = JOY_SONY_CIRCLE
	SONY_X = JOY_SONY_X
	SONY_SQUARE = JOY_SONY_SQUARE
	SONY_TRIANGLE = JOY_SONY_TRIANGLE
	XBOX_B = JOY_XBOX_B
	XBOX_A = JOY_XBOX_A
	XBOX_X = JOY_XBOX_X
	XBOX_Y = JOY_XBOX_Y
	DS_A = JOY_DS_A
	DS_B = JOY_DS_B
	DS_X = JOY_DS_X
	DS_Y = JOY_DS_Y
	VR_GRIP = JOY_VR_GRIP
	VR_PAD = JOY_VR_PAD
	VR_TRIGGER = JOY_VR_TRIGGER
	OCULUS_AX = JOY_OCULUS_AX
	OCULUS_BY = JOY_OCULUS_BY
	OCULUS_MENU = JOY_OCULUS_MENU
	OPENVR_MENU = JOY_OPENVR_MENU
	SELECT = JOY_SELECT
	START = JOY_START
	DPAD_UP = JOY_DPAD_UP
	DPAD_DOWN = JOY_DPAD_DOWN
	DPAD_LEFT = JOY_DPAD_LEFT
	DPAD_RIGHT = JOY_DPAD_RIGHT
	GUIDE = JOY_GUIDE
	MISC1 = JOY_MISC1
	PADDLE1 = JOY_PADDLE1
	PADDLE2 = JOY_PADDLE2
	PADDLE3 = JOY_PADDLE3
	PADDLE4 = JOY_PADDLE4
	TOUCHPAD = JOY_TOUCHPAD
	L = JOY_L
	L2 = JOY_L2
	L3 = JOY_L3
	R = JOY_R
	R2 = JOY_R2
	R3 = JOY_R3
	VR_ANALOG_TRIGGER = JOY_VR_ANALOG_TRIGGER
	VR_ANALOG_GRIP = JOY_VR_ANALOG_GRIP
	OPENVR_TOUCHPADX = JOY_OPENVR_TOUCHPADX
	OPENVR_TOUCHPADY = JOY_OPENVR_TOUCHPADY
}

enum JoyAxes {
	LX = JOY_ANALOG_LX
	LY = JOY_ANALOG_LY
	RX = JOY_ANALOG_RX
	RY = JOY_ANALOG_RY
	L2 = JOY_ANALOG_L2
	R2 = JOY_ANALOG_R2
}

enum ButtonList {
	LEFT = BUTTON_LEFT
	RIGHT = BUTTON_RIGHT
	MIDDLE = BUTTON_MIDDLE
	XBUTTON1 = BUTTON_XBUTTON1
	XBUTTON2 = BUTTON_XBUTTON2
	WHEEL_UP = BUTTON_WHEEL_UP
	WHEEL_DOWN = BUTTON_WHEEL_DOWN
	WHEEL_LEFT = BUTTON_WHEEL_LEFT
	WHEEL_RIGHT = BUTTON_WHEEL_RIGHT
}
