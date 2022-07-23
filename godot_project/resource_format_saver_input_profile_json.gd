extends ResourceFormatSaver
class_name ResourceFormatSaverInputProfileJSON

func recognize(resource: Resource)->bool:
	return resource is InputProfile

func get_recognized_extensions(resource: Resource)->PoolStringArray:
	#if resource is InputProfile:

	return PoolStringArray()


func on_gameplay_move(input:Vector2):

	pass