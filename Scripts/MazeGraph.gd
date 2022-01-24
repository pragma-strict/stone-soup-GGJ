extends Node

# A connected graph where all nodes have a maximum degree of 4
class_name MazeGraph

var nodes = []
var edges = []

var size:IntVector2
var num_nodes


# Initialize all nodes and edges to unconnected and unvisited
func _init(_size:IntVector2):
	size = _size
	num_nodes = _size.x * _size.y
	for i in range(num_nodes):
		nodes.push_back( { 'visited' : false } )
		edges.push_back( [-1, -1, -1, -1] )


# Assign edges based on DFS of graph
func generate_DFS(start_index:int):
	if(start_index < 0 or start_index >= num_nodes):
		return
	
	var rng = RandomNumberGenerator.new()
	
	var traversal = [start_index]
	
	while(len(traversal) > 0):
		var current_node = traversal.back()
		visit_node(current_node)
		var found_unvisited_neighbor = false
		
		# Look for an unvisited neighbor to go to next
		for i in range(4):
			var rand_offset = rng.randi_range(0, 4) # inclusive?
			var rand_dir = (i + rand_offset) % 4
			var neighbor = Array2D.get_adjacent(current_node, rand_dir, size)
			
			# If there is a valid neighbor AND it hasn't been visited
			if(neighbor != -1 and !nodes[neighbor]['visited']):
				add_edge(current_node, rand_dir, neighbor)
				traversal.push_back(neighbor)
				found_unvisited_neighbor = true
				break
		
		if(!found_unvisited_neighbor):
			traversal.pop_back()


# Set the visited property of the given node
func visit_node(index:int):
	nodes[index].visited = true


# Create an edge in the given direction
func add_edge(from_index:int, dir, to_index:int):
	edges[from_index][dir] = to_index
	edges[to_index][Direction.get_opposite(dir)] = from_index


# Prints the graph to console
func print_graph():
	for i in range(num_nodes):
		print("Node ", i, " - North: ", edges[i][0], ", East: ", edges[i][1], ", South: ", edges[i][2], ", West: ", edges[i][3])


func graph_to_tile_index(index:int, tilemap_size:IntVector2):
	var coordinate = Array2D.to_coordinate(index, size)
	return (index * 2 + 1) + (tilemap_size.x * (coordinate.y + 1) + coordinate.y)


func node_at(index:int):
	return nodes[index]


func get_edges(index:int):
	return edges[index]


func get_num_nodes():
	return num_nodes
