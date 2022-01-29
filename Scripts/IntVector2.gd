extends Node

class_name IntVector2

var x
var y

func _init(new_x:int, new_y:int):
	x = new_x
	y = new_y

func add(other:IntVector2):
	x += other.x
	y += other.y

func print_vec():
	print("x: ", x, ", y: ", y)

func to_string():
	return (str("[x: ", x, ", y: ", y, "]"))

func to_vec3():
	return Vector3(x, 0, y)

static func addTo(to:IntVector2, from:IntVector2):
	to.x += from.x
	to.y += from.y
