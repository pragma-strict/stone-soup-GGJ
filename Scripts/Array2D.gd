extends Node

# Wrapper for the array class for use in 2D contexts
class_name Array2D

var array = []
var current_index

func _init(new_arr:Array):
	array = new_arr
	current_index = 0


static func get_diagonal(index:int, dir:IntVector2, size:IntVector2):
	if(dir.x == 1 and dir.y == 1):	# Northeast
		index = get_adjacent(index, Direction.NORTH, size)
		return get_adjacent(index, Direction.EAST, size)
	if(dir.x == 1 and dir.y == -1):	# Southeast
		index = get_adjacent(index, Direction.SOUTH, size)
		return get_adjacent(index, Direction.EAST, size)
	if(dir.x == -1 and dir.y == -1):	# Southwest
		index = get_adjacent(index, Direction.SOUTH, size)
		return get_adjacent(index, Direction.WEST, size)
	if(dir.x == -1 and dir.y == 1):	# Northwest
		index = get_adjacent(index, Direction.NORTH, size)
		return get_adjacent(index, Direction.WEST, size)
	print("Array2D::get_diagonal did a bad thing")
	return null


# Get the index adjacent a given index in the given direction
static func get_adjacent(index:int, dir:int, size:IntVector2):
	var dir_vec = Direction.dir_to_vec(dir)
	if(dir_vec.x == 1):				# East
		if((index + 1) % size.x != 0):
			return index + 1
		return -1
	if(dir_vec.x == -1):			# West
		if(index % size.x != 0):
			return index - 1
		return -1
	if(dir_vec.y == 1):				# North
		if((index + size.x) < (size.x * size.y)):
			return index + size.x
		return -1
	if(dir_vec.y == -1):			# South
		if((index - size.x) >= 0):
			return index - size.x
		return -1
	print("Array2D::get_adjacent did a bad thing")
	return null


# Convert index into coordinate
static func to_coordinate(index:int, size:IntVector2):
	if(index >= 0 and index < (size.x * size.y)):
		return IntVector2.new(index % size.x, floor(index / size.x))
	return null


# Convert coordinate into index
static func to_index(coordinate:IntVector2, size:IntVector2):
	if(coordinate.x * coordinate.y < size.x * size.y):
		return coordinate.y * size.x + coordinate.x
	return null
	
static func to_coordinate_vec2(index:int, size:IntVector2):
	if(index >= 0 and index < (size.x * size.y)):
		return Vector2(index % size.x, floor(index / size.x))
	return null

static func to_coordinate_vec3(index:int, size:IntVector2):
	if(index >= 0 and index < (size.x * size.y)):
		return Vector3(index % size.x, 0, floor(index / size.x))
	return null
