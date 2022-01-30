
# A connected graph where all nodes have a maximum degree of 4
class_name MazeGraph

var nodes = []	# These are actually 
var edges = []

var size:IntVector2
var num_nodes
var rng


# Initialize all nodes and edges to unconnected and unvisited
func _init(_size:IntVector2):
	rng = RandomNumberGenerator.new()
	rng.randomize()
	size = _size
	num_nodes = _size.x * _size.y
	for _i in range(num_nodes):
		nodes.push_back( { 'visited' : false, 'parent' : -1 } )
		edges.push_back( [-1, -1, -1, -1] )


# Assign edges to this graph based a DFS
func generate_DFS(origin_coordinates:IntVector2):
	var start_index = Array2D.to_index(origin_coordinates, size)
	if not is_valid_index(start_index):
		return
	
	var traversal = [start_index]
	
	while(len(traversal) > 0):
		var current_node = traversal.back()
		visit_node(current_node)
		var found_unvisited_neighbor = false
		
		# Look for an unvisited neighbor to go to next
		var rand_offset = rng.randi_range(0, 3) # Inclusive
		for dir in range(4):
			var rand_dir = (dir + rand_offset) % 4
			var neighbor = Array2D.get_adjacent(current_node, rand_dir, size)
			if(is_valid_index(neighbor) and !is_node_visited(neighbor)):
				create_edge(current_node, rand_dir)
				traversal.push_back(neighbor)
				found_unvisited_neighbor = true
				break
		
		if(!found_unvisited_neighbor):
			traversal.pop_back()
	
#	unvisit_all_nodes()
	return


# Reserve a of cells as unconnected and visited. Call before tile generation!
func embed_disconnected_line(start:IntVector2, end:IntVector2):
	if(start.x != end.x and start.y != end.y):
		return
	var current_index = Array2D.to_index(start, size)
	var target_index = Array2D.to_index(end, size)
	var dir = (IntVector2.new(end.x - start.x, end.y - start.y)).normalize()
#	nodes[current_index]
	while(current_index != target_index):
		current_index = Array2D.get_adjacent(current_index, Direction.vec_to_dir(dir), size)
		visit_node(current_index)


# Reserve a hollow rectangle of cells as unconnected and visited. Call before generation!
func embed_disconnected_rect(start:IntVector2, end:IntVector2):
	embed_disconnected_line(start, IntVector2.new(end.x, start.y))
	embed_disconnected_line(start, IntVector2.new(start.x, end.y))
	embed_disconnected_line(IntVector2.new(end.x, start.y), end)
	embed_disconnected_line(IntVector2.new(start.x, end.y), end)


func embed_connected_line(start:IntVector2, end:IntVector2):
	if(start.x != end.x and start.y != end.y):
		return
	var current_index = Array2D.to_index(start, size)
	var target_index = Array2D.to_index(end, size)
	var dir = (IntVector2.new(end.x - start.x, end.y - start.y)).normalize()
	while(current_index != target_index):
		create_edge(current_index, Direction.vec_to_dir(dir))	# This is going to go one too far
		current_index = Array2D.get_adjacent(current_index, Direction.vec_to_dir(dir), size)


# Return an ordered list of indices to visit in the traversal from start->end
func find_path(start_index:int, end_index:int, max_iterations:int):
	if(!is_valid_index(start_index) or !is_valid_index(end_index)):
		return []
	
	var queue = [start_index]
	var iterations = 0
	var found_target = false
	
	while(!queue.empty() and iterations < max_iterations):
		var current_index = queue.pop_front()
		visit_node(current_index)
		
		if(current_index == end_index):	# Found the target
			found_target = true
			break
		
		var neighbors = get_unvisited_connected_neighbors(current_index)
		for n in neighbors:
			visit_node(n)
			set_node_parent(n, current_index)
			queue.push_back(n)
		
		iterations += 1
	
	if(found_target):
		var path = backtrack_from(end_index)
		clear_all_node_properties()
		return path
	return []


# Return a list of nodes indices, starting with index, each the parent of the previous
func backtrack_from(index:int):
	var path = []
	while(has_parent(index)):
		path.push_back(get_node_parent(index))
		index = path[len(path) -1]
	return path


# Return true if there is a straight path between two indices
func is_straight_line_path(from:int, to:int):
	if(from == to):
		return true
	
	var from_vec = Array2D.to_coordinate(from, size)
	var to_vec = Array2D.to_coordinate(to, size)
	
	if(from_vec.x != to_vec.x and from_vec.y != to_vec.y):
		return false
	
	var dir
	print("From: ", from_vec.to_string(), ", to: ", to_vec.to_string())
	if(from_vec.y != to_vec.y):
		if(from_vec.y < to_vec.y):
			dir = Direction.NORTH
		else:
			dir = Direction.SOUTH
			
	if(from_vec.x != to_vec.x):
		if(from_vec.x < to_vec.x):
			dir = Direction.EAST
		else:
			dir = Direction.WEST
	
	var iter = 0
	while(iter < 100):
		from = get_neighbor(from, dir)
		if(from == to):
			return true
		elif(from == -1):
			return false
		iter += 1
	print("Tracking out of range - returning false")


# Create an edge in the given direction
func create_edge(from_index:int, dir):
	var to_index = Array2D.get_adjacent(from_index, dir, size)
	edges[from_index][dir] = to_index
	edges[to_index][Direction.get_opposite(dir)] = from_index


# Prints the graph to console
func print_graph():
	for i in range(num_nodes):
		print("Node ", i, " - North: ", edges[i][0], ", East: ", edges[i][1], ", South: ", edges[i][2], ", West: ", edges[i][3])





# ====================== #
# Basic helper functions #
# ====================== #

func is_valid_index(index:int):
	if(index < 0 or index >= num_nodes):
		return false
	return true


func is_node_visited(index:int):
	if nodes[index]['visited']:
		return true
	return false


func visit_node(index:int): # Set the visited property of the given node
	nodes[index].visited = true


func unvisit_all_nodes():	# Mark all nodes as not visited
	for node in nodes:
		node['visited'] = false


func get_unvisited_connected_neighbors(index:int):
	var neighbors = []
	var candidate
	for dir in range(4):
		candidate = edges[index][dir]
		if(is_valid_index(candidate) and !is_node_visited(candidate)):
			neighbors.push_back(candidate)
	return neighbors


func get_random_connected_neighbors(index:int):
	var neighbors = []
	var candidate
	for dir in range(4):
		var rand_offset = rng.randi_range(0, 3) # Inclusive
		var rand_dir = (dir + rand_offset) % 4
		candidate = edges[index][rand_dir]
		if(is_valid_index(candidate)):
			neighbors.push_back(candidate)
	return neighbors


func has_neighbor(index:int, dir:int): # True if there is a connected neighbor in the given direction
	if(edges[index][dir] != -1):
		return true
	return false


func get_neighbor(index:int, dir:int): # Return the neighbor in the given direction
	return edges[index][dir]


func get_neighbors(index:int):
	var neighbors = []
	var candidate
	for dir in range(4):
		candidate = edges[index][dir]
		if(is_valid_index(candidate)):
			neighbors.push_back(candidate)
	return neighbors


func set_node_parent(child:int, parent:int):
	nodes[child]['parent'] = parent


func get_node_parent(child:int):
	return nodes[child]['parent']


func has_parent(child:int):
	if(nodes[child]['parent'] == -1):
		return false
	return true


func clear_all_node_properties():
	for node in nodes:
		node['visited'] = false
		node['parent'] = -1


func node_at(index:int):
	return nodes[index]


func get_edges(index:int):
	return edges[index]


func clear_node(index:int):	# Remove all edges from a node
	edges[index] = [-1, -1, -1, -1]


func remove_edge(index:int, dir:int):
	edges[index][dir] = -1


func get_num_nodes():
	return num_nodes
