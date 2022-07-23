extends Control

export var _2d_scene: PackedScene
export var _3d_scene: PackedScene
export var _2d_demo_button_path: NodePath
export var _3d_demo_button_path: NodePath

func _ready()->void:
	# warning-ignore:RETURN_VALUE_DISCARDED
	get_node(_2d_demo_button_path).connect("pressed",self,"_on_demo_2d_button_pressed")
	# warning-ignore:RETURN_VALUE_DISCARDED
	get_node(_3d_demo_button_path).connect("pressed",self,"_on_demo_3d_button_pressed")

func _on_demo_2d_button_pressed()->void:
	# warning-ignore:RETURN_VALUE_DISCARDED
	get_tree().change_scene_to(_2d_scene)

func _on_demo_3d_button_pressed()->void:
	# warning-ignore:RETURN_VALUE_DISCARDED
	get_tree().change_scene_to(_3d_scene)
