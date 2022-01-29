
# ===================================================================== #
# A bunch of helper functions for using arrays to store 2D spatial data #
# ===================================================================== #


class_name Array2D


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
#		return IntVector2.new(clamp(index % size.x, 0, size.x -1), clamp(floor(index / size.x), 0, size.y -1))
	return null


# Convert coordinate into index
static func to_index(coordinate:IntVector2, size:IntVector2):
	if(coordinate.x * coordinate.y < size.x * size.y):
		return clamp(coordinate.y * size.x + coordinate.x, 0, size.x * size.y -1)
	return null


static func to_coordinate_vec2(index:int, size:IntVector2):
	if(index >= 0 and index < (size.x * size.y)):
		return Vector2(index % size.x, floor(index / size.x))
	return null


static func to_coordinate_vec3(index:int, size:IntVector2):
	if(index >= 0 and index < (size.x * size.y)):
		return Vector3(index % size.x, 0, floor(index / size.x))
	return null


# Remove the vertical component of the vector
static func vec3_to_vec2(v:Vector3):
	return Vector2(v.x, v.z)


# Add the vertical component as 0
static func vec2_to_vec3(v:Vector2):
	return Vector3(v.x, 0, v.y)
