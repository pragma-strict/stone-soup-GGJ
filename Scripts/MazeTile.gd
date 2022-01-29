extends Node

class_name MazeTile

var type:String
var position:Vector3
var rotation:int
var scene_instance

var packed_scene:PackedScene

func _init(_type:String, _scene:PackedScene, _position:Vector3, _rotation:int):
	type = _type
	packed_scene = _scene
	position = _position
	rotation = _rotation


func create_scene_instance(scale):
	scene_instance = packed_scene.instance()
	scene_instance.translate_object_local(position)
	scene_instance.rotate_object_local(Vector3(0, 1, 0), rotation * PI/2)
	scene_instance.scale_object_local(Vector3(scale, scale, scale))
	return scene_instance


func deactivate():
	scene_instance.get_node("MeshInstance").hide()
	scene_instance.get_node("CollisionShape").disabled = true


func activate():
	scene_instance.get_node("MeshInstance").show()
	scene_instance.get_node("CollisionShape").disabled = false
