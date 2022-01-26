extends Node

class_name MazeTileBase

var type:String
var position:Vector3
var rotation:int
var mesh:Mesh
var mesh_instance:MeshInstance

var packed_scene:PackedScene

func _init(_type:String, _scene:PackedScene, _position:Vector3, _rotation:int):
	type = _type
	packed_scene = _scene
	position = _position
	rotation = _rotation


func create_scene_instance(scale):
	var scene = packed_scene.instance()
	scene.translate_object_local(position)
	scene.rotate_object_local(Vector3(0, 1, 0), rotation * PI/2)
	scene.scale_object_local(Vector3(scale, scale, scale))
	return scene


func create_mesh_instance(scale):
	mesh_instance = MeshInstance.new()
	mesh_instance.mesh = mesh
	mesh_instance.translate_object_local(position)
	mesh_instance.rotate_object_local(Vector3(0, 1, 0), rotation * PI/2)
	mesh_instance.scale_object_local(Vector3(scale, scale, scale))
	return mesh_instance


func deactivate():
	mesh_instance.hide()

func activate():
	mesh_instance.show()
