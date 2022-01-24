extends Node

class_name MazeTileBase

var type:String
var position:Vector3
var rotation:int
var mesh:Mesh
var mesh_instance:MeshInstance


func _init(_type:String, _mesh:Mesh, _position:Vector3, _rotation:int):
	mesh = _mesh
	position = _position
	rotation = _rotation


func create_mesh_instance():
	mesh_instance = MeshInstance.new()
	mesh_instance.mesh = mesh
	mesh_instance.translate_object_local(position)
	mesh_instance.rotate_object_local(Vector3(0, 1, 0), rotation * PI/2)
	return mesh_instance