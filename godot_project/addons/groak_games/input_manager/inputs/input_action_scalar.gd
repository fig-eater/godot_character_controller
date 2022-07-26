extends InputAction
class_name InputActionScalar


export(Array, InputEvent) var _inputs := []



func process_input(event:InputEvent)->void:
	pass


func _init():
	value = 0.0

