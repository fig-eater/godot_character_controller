extends Node

func _ready():
	var iek := InputEventKey.new()
	iek.scancode = KEY_A
	print(JSON.print(iek))


