extends ResourceFormatSaver
class_name ResourceFormatSaverJSONInputProfile

func get_recognized_extensions(resource: Resource)->PoolStringArray:
	if resource is InputProfile:
		return PoolStringArray([".json"])
	return PoolStringArray()

func recognize(resource: Resource)->bool:
	return resource is InputProfile

func save(path: String, resource: Resource, flags: int)->int:
	if not recognize(resource):
		return ERR_INVALID_DATA
	var action_dicts := []
	for action in resource._actions:
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

	var json_string := JSON.print({"name":  resource.resource_name, "actions": action_dicts}, "\t")
	var f := File.new()
	var err := f.open(path, File.WRITE)
	if err:
		return err
	f.store_string(json_string)
	f.close()
	return OK





static func _convert_input_event_to_simple_dict(ie:InputEvent, allow_native_vec2d_events:bool = false)->Dictionary:
	var ie_dict := {}
	match ie.get_class():
		"InputEventMouseButton":
			ie_dict.type = "MouseButton"
			for field in JsonInputProfileUtil.MODIFIERS:
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
			for field in JsonInputProfileUtil.KEY_FIELDS:
				if ie.get(field):
					ie_dict[field] = ie.get(field)

			for field in JsonInputProfileUtil.MODIFIERS:
				var v: bool = ie.get(field)
				if v:
					ie_dict[field] = v
		_:
			# @todo add all input types
			assert(false)
	return ie_dict

