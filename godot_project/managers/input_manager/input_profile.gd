extends Resource
class_name InputProfile

enum {
	# order matters
	COMPOSITE_LEFT  = 0
	COMPOSITE_UP    = 1
	COMPOSITE_RIGHT = 2
	COMPOSITE_DOWN  = 3
}


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
				"type": "InputActionScalar",
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
				"type": "InputActionVector",
				"name": action.resource_name,
				"native_inputs": native_input_dicts,
				"left_inputs": left_input_dicts,
				"up_inputs": up_input_dicts,
				"right_inputs": right_input_dicts,
				"down_inputs": down_input_dicts
			})
		else:
			return ERR_CANT_RESOLVE

	var json_string := JSON.print({
		"name":  resource_name,
		"actions": action_dicts
	}, "\t")

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
		return json_result.error
	if typeof(json_result.result) != TYPE_DICTIONARY:
		return ERR_FILE_UNRECOGNIZED

	var raw_dict: Dictionary = json_result.result
	match raw_dict:
		{"name": var profile_name, "actions": [..]}:
			resource_name = profile_name
			for raw_action in raw_dict.actions:
				match raw_action:
					{"type": "InputActionScalar", "name": var action_name, "inputs": [..]}:
						var action := InputActionScalar.new()
						action.resource_name = action_name
						for ie in raw_action.inputs:
							action._inputs.append(_convert_simple_dict_to_input_event(ie))
					{"type": "InputActionVector", "name": var action_name, "left_inputs": [..], "up_inputs": [..], "right_inputs": [..], "down_inputs": [..], "native_inputs": [..]}:
						var action := InputActionVector.new()
						action.resource_name = action_name
						for ie in raw_action.left_inputs:
							action.left_inputs.append(_convert_simple_dict_to_input_event(ie))
						for ie in raw_action.up_inputs:
							action.up_inputs.append(_convert_simple_dict_to_input_event(ie))
						for ie in raw_action.right_inputs:
							action.right_inputs.append(_convert_simple_dict_to_input_event(ie))
						for ie in raw_action.down_inputs:
							action.down_inputs.append(_convert_simple_dict_to_input_event(ie))
						for ie in raw_action.native_inputs:
							action.native_inputs.append(_convert_simple_dict_to_input_event(ie), true)
					_:
						return ERR_BUG
		_:
			return ERR_BUG

	return OK


static func _convert_input_event_to_simple_dict(ie:InputEvent, allow_native_vec2d_events:bool = false)->Dictionary:
	var ie_dict := {}
	ie_dict["type"] = ie.get_class()
	match ie.get_class():
		"InputEventMouseButton", "InputEventJoypadButton":
			ie_dict["button_index"] = ie.button_index
		"InputEventJoypadMotion":
			ie_dict["axis"] = ie.axis
		"InputEventMouseMotion":
			if not allow_native_vec2d_events:
				assert(ERR_UNAUTHORIZED)
				return {}
		"InputEventKey":
			if ie.physical_scancode:
				ie_dict["physical_scancode"] = ie.physical_scancode
			elif ie.scancode:
				ie_dict["scancode"] = ie.scancode
			else:
				ie_dict["unicode"] = ie.unicode
		_:
			# @todo add all input types
			assert(ERR_UNCONFIGURED)
	return ie_dict


static func _convert_simple_dict_to_input_event(ie_dict:Dictionary, allow_native_vec2d_events:bool = false)->InputEvent:
	var ie: InputEvent
	match ie_dict:
		{"type": "InputEventMouseButton", "button_index": var button_index, "alt": var alt, "shift": var shift, "control": var control, "meta": var meta, "command": var command}:
			ie = InputEventMouseButton.new()
			ie.button_index = button_index
			ie.alt = bool(alt)
			ie.shift = bool(shift)
			ie.control = bool(control)
			ie.meta = bool(meta)
			ie.command = bool(command)
		{"type": "InputEventJoypadButton", "button_index": var button_index}:
			ie = InputEventJoypadButton.new()
			match typeof(button_index):
				TYPE_STRING:
					ie.button_index = JoyStickList[button_index]
				TYPE_INT:
					ie.button_index = button_index
				_:
					return null
		{"type": "InputEventJoypadMotion", "axis": var axis}:
			ie = InputEventJoypadMotion.new()
			ie.axis = axis
		{"type": "InputEventMouseMotion"}:
			if allow_native_vec2d_events:
				ie = InputEventMouseMotion.new()
		{"type": "InputEventKey", "physical_scancode": var physical_scancode, "alt": var alt, "shift": var shift, "control": var control, "meta": var meta, "command": var command}:
			ie = InputEventKey.new()
			match typeof(physical_scancode):
				TYPE_STRING:
					ie.physical_scancode = KeyList[physical_scancode]
				TYPE_INT:
					ie.physical_scancode = physical_scancode
				_:
					return null
			ie.physical_scancode = physical_scancode
			ie.alt = bool(alt)
			ie.shift = bool(shift)
			ie.control = bool(control)
			ie.meta = bool(meta)
			ie.command = bool(command)
		{"type": "InputEventKey", "scancode": var scancode, "alt": var alt, "shift": var shift, "control": var control, "meta": var meta, "command": var command}:
			ie = InputEventKey.new()
			match typeof(scancode):
				TYPE_STRING:
					ie.scancode = KeyList[scancode]
				TYPE_INT:
					ie.scancode = scancode
				_:
					return null
			ie.alt = bool(alt)
			ie.shift = bool(shift)
			ie.control = bool(control)
			ie.meta = bool(meta)
			ie.command = bool(command)
		{"type": "InputEventKey", "unicode": var unicode, "alt": var alt, "shift": var shift, "control": var control, "meta": var meta, "command": var command}:
			ie = InputEventKey.new()
			ie.unicode = unicode
			ie.alt = bool(alt)
			ie.shift = bool(shift)
			ie.control = bool(control)
			ie.meta = bool(meta)
			ie.command = bool(command)
		_:
			# @todo add all input types
			assert(ERR_UNCONFIGURED)
	return ie


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
enum JoyStickList {
	JOY_BUTTON_0 = 0
	JOY_BUTTON_1 = 1
	JOY_BUTTON_2 = 2
	JOY_BUTTON_3 = 3
	JOY_BUTTON_4 = 4
	JOY_BUTTON_5 = 5
	JOY_BUTTON_6 = 6
	JOY_BUTTON_7 = 7
	JOY_BUTTON_8 = 8
	JOY_BUTTON_9 = 9
	JOY_BUTTON_10 = 10
	JOY_BUTTON_11 = 11
	JOY_BUTTON_12 = 12
	JOY_BUTTON_13 = 13
	JOY_BUTTON_14 = 14
	JOY_BUTTON_15 = 15
	JOY_BUTTON_16 = 16
	JOY_BUTTON_17 = 17
	JOY_BUTTON_18 = 18
	JOY_BUTTON_19 = 19
	JOY_BUTTON_20 = 20
	JOY_BUTTON_21 = 21
	JOY_BUTTON_22 = 22
	JOY_SONY_CIRCLE = 1
	JOY_SONY_X = 0
	JOY_SONY_SQUARE = 2
	JOY_SONY_TRIANGLE = 3
	JOY_XBOX_B = 1
	JOY_XBOX_A = 0
	JOY_XBOX_X = 2
	JOY_XBOX_Y = 3
	JOY_DS_A = 1
	JOY_DS_B = 0
	JOY_DS_X = 3
	JOY_DS_Y = 2
	JOY_VR_GRIP = 2
	JOY_VR_PAD = 14
	JOY_VR_TRIGGER = 15
	JOY_OCULUS_AX = 7
	JOY_OCULUS_BY = 1
	JOY_OCULUS_MENU = 3
	JOY_OPENVR_MENU = 1
	JOY_SELECT = 10
	JOY_START = 11
	JOY_DPAD_UP = 12
	JOY_DPAD_DOWN = 13
	JOY_DPAD_LEFT = 14
	JOY_DPAD_RIGHT = 15
	JOY_GUIDE = 16
	JOY_MISC1 = 17
	JOY_PADDLE1 = 18
	JOY_PADDLE2 = 19
	JOY_PADDLE3 = 20
	JOY_PADDLE4 = 21
	JOY_TOUCHPAD = 22
	JOY_L = 4
	JOY_L2 = 6
	JOY_L3 = 8
	JOY_R = 5
	JOY_R2 = 7
	JOY_R3 = 9
	JOY_AXIS_0 = 0
	JOY_AXIS_1 = 1
	JOY_AXIS_2 = 2
	JOY_AXIS_3 = 3
	JOY_AXIS_4 = 4
	JOY_AXIS_5 = 5
	JOY_AXIS_6 = 6
	JOY_AXIS_7 = 7
	JOY_AXIS_8 = 8
	JOY_AXIS_9 = 9
	JOY_AXIS_MAX = 10
	JOY_ANALOG_LX = 0
	JOY_ANALOG_LY = 1
	JOY_ANALOG_RX = 2
	JOY_ANALOG_RY = 3
	JOY_ANALOG_L2 = 6
	JOY_ANALOG_R2 = 7
	JOY_VR_ANALOG_TRIGGER = 2
	JOY_VR_ANALOG_GRIP = 4
	JOY_OPENVR_TOUCHPADX = 0
	JOY_OPENVR_TOUCHPADY = 1
}

enum ButtonList {
	BUTTON_LEFT = 1
	BUTTON_RIGHT = 2
	BUTTON_MIDDLE = 3
	BUTTON_XBUTTON1 = 8
	BUTTON_XBUTTON2 = 9
	BUTTON_WHEEL_UP = 4
	BUTTON_WHEEL_DOWN = 5
	BUTTON_WHEEL_LEFT = 6
	BUTTON_WHEEL_RIGHT = 7
	BUTTON_MASK_LEFT = 1
	BUTTON_MASK_RIGHT = 2
	BUTTON_MASK_MIDDLE = 4
	BUTTON_MASK_XBUTTON1 = 128
	BUTTON_MASK_XBUTTON2 = 256
}

enum KeyList {
	KEY_ESCAPE = 16777217
	KEY_TAB = 16777218
	KEY_BACKTAB = 16777219
	KEY_BACKSPACE = 16777220
	KEY_ENTER = 16777221
	KEY_KP_ENTER = 16777222
	KEY_INSERT = 16777223
	KEY_DELETE = 16777224
	KEY_PAUSE = 16777225
	KEY_PRINT = 16777226
	KEY_SYSREQ = 16777227
	KEY_CLEAR = 16777228
	KEY_HOME = 16777229
	KEY_END = 16777230
	KEY_LEFT = 16777231
	KEY_UP = 16777232
	KEY_RIGHT = 16777233
	KEY_DOWN = 16777234
	KEY_PAGEUP = 16777235
	KEY_PAGEDOWN = 16777236
	KEY_SHIFT = 16777237
	KEY_CONTROL = 16777238
	KEY_META = 16777239
	KEY_ALT = 16777240
	KEY_CAPSLOCK = 16777241
	KEY_NUMLOCK = 16777242
	KEY_SCROLLLOCK = 16777243
	KEY_F1 = 16777244
	KEY_F2 = 16777245
	KEY_F3 = 16777246
	KEY_F4 = 16777247
	KEY_F5 = 16777248
	KEY_F6 = 16777249
	KEY_F7 = 16777250
	KEY_F8 = 16777251
	KEY_F9 = 16777252
	KEY_F10 = 16777253
	KEY_F11 = 16777254
	KEY_F12 = 16777255
	KEY_F13 = 16777256
	KEY_F14 = 16777257
	KEY_F15 = 16777258
	KEY_F16 = 16777259
	KEY_KP_MULTIPLY = 16777345
	KEY_KP_DIVIDE = 16777346
	KEY_KP_SUBTRACT = 16777347
	KEY_KP_PERIOD = 16777348
	KEY_KP_ADD = 16777349
	KEY_KP_0 = 16777350
	KEY_KP_1 = 16777351
	KEY_KP_2 = 16777352
	KEY_KP_3 = 16777353
	KEY_KP_4 = 16777354
	KEY_KP_5 = 16777355
	KEY_KP_6 = 16777356
	KEY_KP_7 = 16777357
	KEY_KP_8 = 16777358
	KEY_KP_9 = 16777359
	KEY_SUPER_L = 16777260
	KEY_SUPER_R = 16777261
	KEY_MENU = 16777262
	KEY_HYPER_L = 16777263
	KEY_HYPER_R = 16777264
	KEY_HELP = 16777265
	KEY_DIRECTION_L = 16777266
	KEY_DIRECTION_R = 16777267
	KEY_BACK = 16777280
	KEY_FORWARD = 16777281
	KEY_STOP = 16777282
	KEY_REFRESH = 16777283
	KEY_VOLUMEDOWN = 16777284
	KEY_VOLUMEMUTE = 16777285
	KEY_VOLUMEUP = 16777286
	KEY_BASSBOOST = 16777287
	KEY_BASSUP = 16777288
	KEY_BASSDOWN = 16777289
	KEY_TREBLEUP = 16777290
	KEY_TREBLEDOWN = 16777291
	KEY_MEDIAPLAY = 16777292
	KEY_MEDIASTOP = 16777293
	KEY_MEDIAPREVIOUS = 16777294
	KEY_MEDIANEXT = 16777295
	KEY_MEDIARECORD = 16777296
	KEY_HOMEPAGE = 16777297
	KEY_FAVORITES = 16777298
	KEY_SEARCH = 16777299
	KEY_STANDBY = 16777300
	KEY_OPENURL = 16777301
	KEY_LAUNCHMAIL = 16777302
	KEY_LAUNCHMEDIA = 16777303
	KEY_LAUNCH0 = 16777304
	KEY_LAUNCH1 = 16777305
	KEY_LAUNCH2 = 16777306
	KEY_LAUNCH3 = 16777307
	KEY_LAUNCH4 = 16777308
	KEY_LAUNCH5 = 16777309
	KEY_LAUNCH6 = 16777310
	KEY_LAUNCH7 = 16777311
	KEY_LAUNCH8 = 16777312
	KEY_LAUNCH9 = 16777313
	KEY_LAUNCHA = 16777314
	KEY_LAUNCHB = 16777315
	KEY_LAUNCHC = 16777316
	KEY_LAUNCHD = 16777317
	KEY_LAUNCHE = 16777318
	KEY_LAUNCHF = 16777319
	KEY_UNKNOWN = 33554431
	KEY_SPACE = 32
	KEY_EXCLAM = 33
	KEY_QUOTEDBL = 34
	KEY_NUMBERSIGN = 35
	KEY_DOLLAR = 36
	KEY_PERCENT = 37
	KEY_AMPERSAND = 38
	KEY_APOSTROPHE = 39
	KEY_PARENLEFT = 40
	KEY_PARENRIGHT = 41
	KEY_ASTERISK = 42
	KEY_PLUS = 43
	KEY_COMMA = 44
	KEY_MINUS = 45
	KEY_PERIOD = 46
	KEY_SLASH = 47
	KEY_0 = 48
	KEY_1 = 49
	KEY_2 = 50
	KEY_3 = 51
	KEY_4 = 52
	KEY_5 = 53
	KEY_6 = 54
	KEY_7 = 55
	KEY_8 = 56
	KEY_9 = 57
	KEY_COLON = 58
	KEY_SEMICOLON = 59
	KEY_LESS = 60
	KEY_EQUAL = 61
	KEY_GREATER = 62
	KEY_QUESTION = 63
	KEY_AT = 64
	KEY_A = 65
	KEY_B = 66
	KEY_C = 67
	KEY_D = 68
	KEY_E = 69
	KEY_F = 70
	KEY_G = 71
	KEY_H = 72
	KEY_I = 73
	KEY_J = 74
	KEY_K = 75
	KEY_L = 76
	KEY_M = 77
	KEY_N = 78
	KEY_O = 79
	KEY_P = 80
	KEY_Q = 81
	KEY_R = 82
	KEY_S = 83
	KEY_T = 84
	KEY_U = 85
	KEY_V = 86
	KEY_W = 87
	KEY_X = 88
	KEY_Y = 89
	KEY_Z = 90
	KEY_BRACKETLEFT = 91
	KEY_BACKSLASH = 92
	KEY_BRACKETRIGHT = 93
	KEY_ASCIICIRCUM = 94
	KEY_UNDERSCORE = 95
	KEY_QUOTELEFT = 96
	KEY_BRACELEFT = 123
	KEY_BAR = 124
	KEY_BRACERIGHT = 125
	KEY_ASCIITILDE = 126
	KEY_NOBREAKSPACE = 160
	KEY_EXCLAMDOWN = 161
	KEY_CENT = 162
	KEY_STERLING = 163
	KEY_CURRENCY = 164
	KEY_YEN = 165
	KEY_BROKENBAR = 166
	KEY_SECTION = 167
	KEY_DIAERESIS = 168
	KEY_COPYRIGHT = 169
	KEY_ORDFEMININE = 170
	KEY_GUILLEMOTLEFT = 171
	KEY_NOTSIGN = 172
	KEY_HYPHEN = 173
	KEY_REGISTERED = 174
	KEY_MACRON = 175
	KEY_DEGREE = 176
	KEY_PLUSMINUS = 177
	KEY_TWOSUPERIOR = 178
	KEY_THREESUPERIOR = 179
	KEY_ACUTE = 180
	KEY_MU = 181
	KEY_PARAGRAPH = 182
	KEY_PERIODCENTERED = 183
	KEY_CEDILLA = 184
	KEY_ONESUPERIOR = 185
	KEY_MASCULINE = 186
	KEY_GUILLEMOTRIGHT = 187
	KEY_ONEQUARTER = 188
	KEY_ONEHALF = 189
	KEY_THREEQUARTERS = 190
	KEY_QUESTIONDOWN = 191
	KEY_AGRAVE = 192
	KEY_AACUTE = 193
	KEY_ACIRCUMFLEX = 194
	KEY_ATILDE = 195
	KEY_ADIAERESIS = 196
	KEY_ARING = 197
	KEY_AE = 198
	KEY_CCEDILLA = 199
	KEY_EGRAVE = 200
	KEY_EACUTE = 201
	KEY_ECIRCUMFLEX = 202
	KEY_EDIAERESIS = 203
	KEY_IGRAVE = 204
	KEY_IACUTE = 205
	KEY_ICIRCUMFLEX = 206
	KEY_IDIAERESIS = 207
	KEY_ETH = 208
	KEY_NTILDE = 209
	KEY_OGRAVE = 210
	KEY_OACUTE = 211
	KEY_OCIRCUMFLEX = 212
	KEY_OTILDE = 213
	KEY_ODIAERESIS = 214
	KEY_MULTIPLY = 215
	KEY_OOBLIQUE = 216
	KEY_UGRAVE = 217
	KEY_UACUTE = 218
	KEY_UCIRCUMFLEX = 219
	KEY_UDIAERESIS = 220
	KEY_YACUTE = 221
	KEY_THORN = 222
	KEY_SSHARP = 223
	KEY_DIVISION = 247
	KEY_YDIAERESIS = 255
}




