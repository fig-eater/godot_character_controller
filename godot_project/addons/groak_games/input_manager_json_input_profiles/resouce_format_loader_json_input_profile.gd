tool
extends ResourceFormatLoader
class_name ResourceFormatLoaderJSONInputProfile

# @todo	 remove these comments

# func get_dependencies(path: String, add_types: String)->void:
# 	pass


# func rename_dependencies(path: String, renames: String)->int:
# 	return OK


# func get_resource_type(path: String)->String:
# 	return "Resource"


func get_recognized_extensions()->PoolStringArray:
	return PoolStringArray(["json"])

func handles_type(typename: String)->bool:
	return typename == "InputProfile"

func load(path: String, original_path: String):
	var f := File.new()
	var err := f.open(original_path, File.READ)
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

	var input_profile := InputProfile.new()
	var raw_dict: Dictionary = json_result.result
	match raw_dict:
		{"name": var profile_name, "actions": [..]}:
			input_profile.resource_name = profile_name
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
				input_profile._actions.append(action)
		_:
			return ERR_BUG
	return input_profile


static func _convert_simple_dict_to_input_event(ie_dict:Dictionary, allow_native_vec2d_events:bool = false)->InputEvent:
	var ie: InputEvent
	if "type" in ie_dict: ie_dict.type = ie_dict.type.to_upper()

	match ie_dict:
		{"type": "MOUSEBUTTON", "button_index": var button_index, ..}:
			ie = InputEventMouseButton.new()
			match typeof(button_index):
				TYPE_STRING:
					ie.button_index = JsonInputProfileUtil.ButtonList.get(button_index.to_upper(), 0) # @todo handle invalid?
				TYPE_REAL, TYPE_INT:
					ie.button_index = button_index
				_:
					return null
			for field in JsonInputProfileUtil.MODIFIERS:
				ie.set(field, ie_dict.get(field,false))
		{"type": "JOYPADBUTTON", "button_index": var button_index}:
			ie = InputEventJoypadButton.new()
			match typeof(button_index):
				TYPE_STRING:
					ie.button_index = JsonInputProfileUtil.JoyStickList.get(button_index.to_upper(), 0) # @todo handle invalid?
				TYPE_REAL, TYPE_INT:
					ie.button_index = button_index
				_:
					return null
		{"type": "JOYPADMOTION", "axis": var axis}:
			ie = InputEventJoypadMotion.new()
			match typeof(axis):
				TYPE_STRING:
					ie.axis = JsonInputProfileUtil.JoyAxes.get(axis.to_upper(), 0) # @todo handle invalid?
				TYPE_REAL, TYPE_INT:
					ie.axis = axis
				_:
					return null
		{"type": "MOUSEMOTION"}:
			if allow_native_vec2d_events:
				ie = InputEventMouseMotion.new()
		{"type": "KEY", ..}:
				ie = InputEventKey.new()
				for field in JsonInputProfileUtil.MODIFIERS:
					ie.set(field, ie_dict.get(field,false))

				for field in JsonInputProfileUtil.KEY_FIELDS:
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