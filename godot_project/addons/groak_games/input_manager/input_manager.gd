extends Node

# AutoLoad InputManager

# @todo remove
const TEST_INPUT_ACTION = preload("res://test_input_action.tres")

enum {
	DEVICE_KEYBOARD = -3
	DEVICE_MOUSE = -2
	DEVICE_EMULATED_TOUCH_MOUSE = -1
}

var profile_map := {}

var profile_directory := "user://input_profiles"
var default_profile:InputProfile

var _players: Dictionary
var _device_to_player_map: Dictionary


func connect_input(player_id, action:String, target:Object, method:String, binds:=[], flags := 0)->int:
	var player: InputPlayer =_players.get(player_id)
	if player:
		return player.profile.connect_input(action, target, method, binds, flags)
	return ERR_DOES_NOT_EXIST

# returns false if player has been created with given id
func create_player(id, input_profile: InputProfile = null, devices: PoolIntArray = [])->bool:
	if _players.has(id):
		return false
	if not input_profile:
		input_profile = default_profile
	input_profile.initialize()
	var input_player = InputPlayer.new()
	_players[id] = input_player
	input_player.id = id
	input_player.profile = input_profile
	input_player.claimed_devices = devices
	for device in devices:
		var device_list: Array =_device_to_player_map.get(device, [])
		if not _device_to_player_map.has(device):
			_device_to_player_map[device] = device_list
		device_list.append(input_player)
	return true

func delete_player(input_player_id)->bool:
	var player: InputPlayer = _players.get(input_player_id)
	if player:
		for device in player.claimed_devices:
			(_device_to_player_map[device] as Array).erase(player.id)
		return _players.erase(input_player_id)
	return false

func claim_device(input_player_id, device:int)->bool:
	var player: InputPlayer = _players.get(input_player_id)
	if player:
		if device in player.claimed_devices:
			return false
		player.claimed_devices.append(device)
		var device_list: Array =_device_to_player_map.get(device, [])
		if not _device_to_player_map.has(device):
			_device_to_player_map[device] = device_list
		device_list.append(player)
	return false

func unclaim_device(input_player_id, device:int)->bool:
	var player: InputPlayer = _players.get(input_player_id)
	if player and device in player.claimed_devices:
		var temp := Array(player.claimed_devices)
		temp.erase(device)
		player.claimed_devices = PoolIntArray(temp)
		_device_to_player_map[device].erase(player)
		return true
	return false

func get_device_players(device)->Array:
	var players: Array = _device_to_player_map.get(device, [])
	var player_ids := []
	for p in players:
		player_ids.append(p.id)
	return player_ids

func save_player_profile(input_player_id)->int:
	var player: InputPlayer = _players.get(input_player_id)
	if player:
		return ResourceSaver.save(profile_directory+"/"+player.profile.resource_name, player.profile)
	return ERR_DOES_NOT_EXIST

func set_player_profile(input_player_id, profile:InputProfile)->bool:
	var player: InputPlayer = _players.get(input_player_id)
	if player:
		player.profile = profile
		return true
	return false

func load_saved_profiles()->void:
	var dir := Directory.new()
	if dir.open(profile_directory) == OK:
		dir.list_dir_begin(true, true)
		var file_name := dir.get_next()
		while file_name:
			if not dir.current_is_dir():
				var profile: InputProfile = ResourceLoader.load(dir.get_current_dir() + "/" + file_name, "InputProfile")
				if profile:
					profile_map[profile.resource_name] = profile
			file_name = dir.get_next()
		dir.list_dir_end()

func _input(event:InputEvent):
	# if event is InputEventJoypadButton:
	# 	print((TEST_INPUT_ACTION._inputs[0] as InputEvent).shortcut_match(event, true))
	# return
	var players
	if event.device or event is InputEventJoypadMotion or event is InputEventJoypadButton:
		players = _device_to_player_map.get(event.device, [])
	elif event is InputEventMouse:
		players = _device_to_player_map.get(DEVICE_MOUSE, [])
	elif event is InputEventKey:
		players = _device_to_player_map.get(DEVICE_KEYBOARD, [])

	for p in players:
		p.profile.process_input(event)



class InputPlayer:
	extends Reference
	var id
	var claimed_devices: PoolIntArray
	var profile



class CompositeAction:
	extends Reference
