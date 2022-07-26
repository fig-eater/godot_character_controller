extends Resource
class_name InputProfile


const _INPUT_SIGNAL_PREFIX = "INPUT_SIGNAL_"
enum {
	# order matters
	COMPOSITE_LEFT  = 0
	COMPOSITE_UP    = 1
	COMPOSITE_RIGHT = 2
	COMPOSITE_DOWN  = 3
	NATIVE_VECTOR2
}

export(Array, Resource) var _actions: Array
# Dictionary(InputEvent,Array(InputActionData))
var _input_event_map: Dictionary
var _initialized := false

func is_initialized()->bool:
	return _initialized

func initialize()->void:
	if _initialized:
		return
	_create_input_event_map()
	_initialized = true


func connect_input(action:String, target:Object, method:String, binds:=[], flags := 0)->int:
	return connect(_INPUT_SIGNAL_PREFIX+action, target, method, binds, flags)

func process_input(event:InputEvent)->void:
	if _initialized:
		for ie in _input_event_map:
			if ie.shortcut_match(event):
				var action_list: Array = _input_event_map[ie]
				for action_data in action_list:
					emit_signal(_INPUT_SIGNAL_PREFIX+action_data.action.resource_name, action_data.process_input(event))

func _create_input_event_map()->void:
	for action in _actions:
		print("signal added! ", _INPUT_SIGNAL_PREFIX+action.resource_name)
		add_user_signal(_INPUT_SIGNAL_PREFIX+action.resource_name)
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

class InputActionData:
	extends Reference
	var action:InputActionScalar
	func process_input(event:InputEvent):

		pass


class InputActionCompositeData:
	extends Reference
	var action:InputActionVector

	var composite_direction := COMPOSITE_LEFT
	func process_input(event:InputEvent):
		if event is InputEventMouseMotion:
			action.value = get_input_value(event)
		elif event.is_pressed():
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
		return action.value

	static func get_input_value(ie:InputEvent)->float:
		if ie is InputEventJoypadButton:
			return ie.pressure if ie.pressure else float(ie.is_pressed())
		elif ie is InputEventJoypadMotion:
			return ie.axis_value

		# @todo midi input
		return float(ie.is_pressed())
