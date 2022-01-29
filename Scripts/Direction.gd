class_name Direction

enum{
	NORTH,
	EAST,
	SOUTH,
	WEST
}

static func dir_to_vec(dir):
	if(dir == NORTH):
		return IntVector2.new(0, 1)
	if(dir == EAST):
		return IntVector2.new(1, 0)
	if(dir == SOUTH):
		return IntVector2.new(0, -1)
	if(dir == WEST):
		return IntVector2.new(-1, 0)

static func vec_to_dir(vec:IntVector2):
	if(vec.y > 0):
		return NORTH
	if(vec.x > 0):
		return EAST
	if(vec.y < 0):
		return SOUTH
	if(vec.x < 0):
		return WEST
	return null

static func get_opposite(dir):
	if(dir == NORTH):
		return SOUTH
	if(dir == EAST):
		return WEST
	if(dir == SOUTH):
		return NORTH
	if(dir == WEST):
		return EAST

static func as_string(dir):
	match(dir):
		0 : return "NORTH"
		1 : return "EAST"
		2 : return "SOUTH"
		3 : return "WEST"
	return "Invalid input"
