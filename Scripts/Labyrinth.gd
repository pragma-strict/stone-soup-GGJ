extends Node

class_name Labyrinth

export(Vector2) var graph_dimensions # How many node wide is the graph?
export(float) var scale
export(int) var max_pathfinding_iterations = 250

export(Dictionary) var tile_scenes = {
	"Path" : PackedScene,
	"Wall" : PackedScene,
	"Door" : PackedScene,
	"Corner" : PackedScene,
	"Boundary" : PackedScene
}

export(Dictionary) var NPC_scenes = {
	"Rolem" : PackedScene
}

onready var line_renderer:ImmediateGeometry = $"../LineRenderer"

var tile_prototypes = {}

var graph:MazeGraph
var rng

var tiles = []
var tilemap_dimensions
var num_tiles
var ground_height = 15

# A list of the children (walls and corners) that need to be toggled during day and night
var dynamic_types = ['Wall', 'Corner']
var dynamic_children = []

var sanctum_graph_bounds = [IntVector2.new(18, 18), IntVector2.new(22, 22)]
var sanctum_tile_bounds = []
var b1_graph_bounds = [IntVector2.new(13, 13), IntVector2.new(27, 27)]
var b1_tile_bounds = []
var b2_graph_bounds = [IntVector2.new(6, 6), IntVector2.new(34, 34)]
var b2_tile_bounds = []
var b3_graph_bounds = [IntVector2.new(0, 0), IntVector2.new(40, 40)]
var b3_tile_bounds = []


# Called when the node enters the scene tree for the first time.
func _ready():
	rng = RandomNumberGenerator.new()
	rng.randomize()
	
	graph_dimensions = IntVector2.new(graph_dimensions.x, graph_dimensions.y)
	graph = MazeGraph.new(graph_dimensions)
	tilemap_dimensions = IntVector2.new(graph_dimensions.x * 2 + 1, graph_dimensions.y * 2 + 1)
	num_tiles = tilemap_dimensions.x * tilemap_dimensions.y
	
	# Generate tile coordinates of boundaries based on their graph coordinates
	sanctum_tile_bounds.push_back(graph_to_tile_coordinates(sanctum_graph_bounds[0]))
	sanctum_tile_bounds.push_back(graph_to_tile_coordinates(sanctum_graph_bounds[1]))
	sanctum_tile_bounds[0].add(IntVector2.new(-1, -1))
	sanctum_tile_bounds[1].add(IntVector2.new(1, 1))
	b1_tile_bounds.push_back(graph_to_tile_coordinates(b1_graph_bounds[0]))
	b1_tile_bounds.push_back(graph_to_tile_coordinates(b1_graph_bounds[1]))
	b2_tile_bounds.push_back(graph_to_tile_coordinates(b2_graph_bounds[0]))
	b2_tile_bounds.push_back(graph_to_tile_coordinates(b2_graph_bounds[1]))
	b3_tile_bounds.push_back(graph_to_tile_coordinates(b3_graph_bounds[0]))
	b3_tile_bounds.push_back(graph_to_tile_coordinates(b3_graph_bounds[1]))
	
	# Embed disconnected sections in the graph
	graph.embed_disconnected_rect(b3_graph_bounds[0], b3_graph_bounds[1])
	graph.embed_disconnected_rect(b2_graph_bounds[0], b2_graph_bounds[1])
	graph.embed_disconnected_rect(b1_graph_bounds[0], b1_graph_bounds[1])
	graph.embed_disconnected_rect(sanctum_graph_bounds[0], sanctum_graph_bounds[1])
	embed_doors_into_graph()
	
	# Generate the graph from specified origin points
	graph.generate_DFS(IntVector2.new(sanctum_graph_bounds[0].x -1, sanctum_graph_bounds[0].y -1))
	graph.generate_DFS(IntVector2.new(b1_graph_bounds[0].x -1, b1_graph_bounds[0].y -1))
	graph.generate_DFS(IntVector2.new(b2_graph_bounds[0].x -1, b2_graph_bounds[0].y -1))
	graph.clear_all_node_properties()

	# Generate the tiles from the graph
	initialize_tile_protos()
	generate_tiles_from_graph()
	embed_doors_into_tilemap()
	
	# Embed some special tiles to account for boundaries and sanctum
	embed_sanctum_protos()
	embed_rect(b1_tile_bounds[0], b1_tile_bounds[1], "Empty")
	embed_rect(b2_tile_bounds[0], b2_tile_bounds[1], "Empty")
	embed_rect(b3_tile_bounds[0], b3_tile_bounds[1], "Empty")
	
	# Actually spawn the tiles
	instantiate_all_tiles()
	
	# Spawn enemies
#	spawn_at_random_tile(NPC_scenes['Rolem'], ['Path'])
	spawn_at_tile(NPC_scenes['Rolem'], IntVector2.new(35, 39))


# Sets up the dictionaries that hold all the data for each type of tile
func initialize_tile_protos():
	var keys = tile_scenes.keys()
	for i in range(len(keys)):
		tile_prototypes[keys[i]] = {
			'type' : keys[i]
		}
	tile_prototypes['Empty'] = {
		'type' : 'Empty'
	}


# Generates all tiles
func generate_tiles_from_graph():
	tiles.clear()
	tiles.resize(num_tiles)
	for i in range(graph.num_nodes):
		generate_tiles_from_graph_node(i)	


func embed_sanctum_protos():
	var s_begin = sanctum_tile_bounds[0]
	var s_end = sanctum_tile_bounds[1]
	embed_rect(s_begin, s_end, "Empty")
	for i in range(5):
		s_begin.add(IntVector2.new(1, 1))
		s_end.add(IntVector2.new(-1, -1))
		embed_rect(s_begin, s_end, "Empty")


func embed_doors_into_graph():
	# West doors
	graph.embed_connected_line(IntVector2.new(0, 20), IntVector2.new(1, 20))
	graph.embed_connected_line(IntVector2.new(5, 20), IntVector2.new(7, 20))
	graph.embed_connected_line(IntVector2.new(12, 20), IntVector2.new(14, 20))
	
	# East doors
	graph.embed_connected_line(IntVector2.new(40, 20), IntVector2.new(39, 20))
	graph.embed_connected_line(IntVector2.new(35, 20), IntVector2.new(33, 20))
	graph.embed_connected_line(IntVector2.new(28, 20), IntVector2.new(26, 20))
	
	# North doors
	graph.embed_connected_line(IntVector2.new(20, 0), IntVector2.new(20, 1))
	graph.embed_connected_line(IntVector2.new(20, 5), IntVector2.new(20, 7))
	graph.embed_connected_line(IntVector2.new(20, 12), IntVector2.new(20, 14))
	
	# South doors
	graph.embed_connected_line(IntVector2.new(20, 40), IntVector2.new(20, 39))
	graph.embed_connected_line(IntVector2.new(20, 35), IntVector2.new(20, 33))
	graph.embed_connected_line(IntVector2.new(20, 28), IntVector2.new(20, 26))	


func embed_doors_into_tilemap():
	embed_line(IntVector2.new(41, 0), IntVector2.new(41, 1), 'Empty')
	embed_line(IntVector2.new(41, 81), IntVector2.new(41, 82), 'Empty')
	embed_line(IntVector2.new(0, 41), IntVector2.new(1, 41), 'Empty')
	embed_line(IntVector2.new(81, 41), IntVector2.new(82, 41), 'Empty')


# Generates all 9 tiles in the kernel of a single graph node
func generate_tiles_from_graph_node(node_index:int):
	var tile_index = graph_to_tile_index(node_index)
	
	# Collect protos for clarity
	var corner_proto = 'Corner'
	var path_proto = 'Path'
	var wall_proto = 'Wall'
	var door_proto = 'Door'
	
	# Get tile indices
	var corner_tl = Array2D.get_diagonal(tile_index, IntVector2.new(-1, 1), tilemap_dimensions)
	var corner_tr = Array2D.get_diagonal(tile_index, IntVector2.new(1, 1), tilemap_dimensions)
	var corner_bl = Array2D.get_diagonal(tile_index, IntVector2.new(-1, -1), tilemap_dimensions)
	var corner_br = Array2D.get_diagonal(tile_index, IntVector2.new(1, -1), tilemap_dimensions)
	
	var north = Array2D.get_adjacent(tile_index, Direction.NORTH, tilemap_dimensions)
	var east = Array2D.get_adjacent(tile_index, Direction.EAST, tilemap_dimensions)
	var south = Array2D.get_adjacent(tile_index, Direction.SOUTH, tilemap_dimensions)
	var west = Array2D.get_adjacent(tile_index, Direction.WEST, tilemap_dimensions)

	# Generate corners
	generate_tile(corner_tl, corner_proto, 0) 	# Top left
	generate_tile(corner_tr, corner_proto, 0) 	# Top right
	generate_tile(corner_bl, corner_proto, 0) 	# Bottom left
	generate_tile(corner_br, corner_proto, 0) 	# Bottom right
	
	# Generate center
	generate_tile(tile_index, path_proto, 0)
	
	# Generate connections
	var edges = graph.get_edges(node_index)
	if(edges[Direction.NORTH] == -1):
		generate_tile(north, wall_proto, Direction.NORTH)
	else:
		generate_tile(north, door_proto, Direction.NORTH)

	if(edges[Direction.EAST] == -1):
		generate_tile(east, wall_proto, Direction.EAST)
	else:
		generate_tile(east, door_proto, Direction.EAST)

	if(edges[Direction.SOUTH] == -1):
		generate_tile(south, wall_proto, Direction.SOUTH)
	else:
		generate_tile(south, door_proto, Direction.SOUTH)

	if(edges[Direction.WEST] == -1):
		generate_tile(west, wall_proto, Direction.WEST)
	else:
		generate_tile(west, door_proto, Direction.WEST)	


# Generates a single tile
func generate_tile(index:int, type:String, rot:int):
	tiles[index] = {
		'type' : type,
		'pos' : get_position_from_tile(index),
		'rot' : rot,
		'tile' : null	 # This will be replaced with a MazeTileBase object
	}


# Set a rectangle of tiles to a certain type.
func embed_rect(start:IntVector2, end:IntVector2, type:String):
	embed_line(start, IntVector2.new(end.x, start.y), type)
	embed_line(start, IntVector2.new(start.x, end.y), type)
	embed_line(IntVector2.new(end.x, start.y), end, type)
	embed_line(IntVector2.new(start.x, end.y), end, type)


# Set a line of tiles to a certain type. Line cannot be diagonal. Call before tile instantiation!
func embed_line(start:IntVector2, end:IntVector2, type:String):
	if(start.x != end.x and start.y != end.y):
		return
	var current_index = Array2D.to_index(start, tilemap_dimensions)
	var target_index = Array2D.to_index(end, tilemap_dimensions)
	var dir = (IntVector2.new(end.x - start.x, end.y - start.y)).normalize()
	tiles[current_index]['type'] = type
	var iter = 0
	while(current_index != target_index and iter < 100):
		current_index = Array2D.get_adjacent(current_index, Direction.vec_to_dir(dir), tilemap_dimensions)
		tiles[current_index]['type'] = type
		iter += 1
	if(iter > 90):
		print("iter limit")


func spawn_at_random_tile(var scene:PackedScene, var tile_types:Array):
	var candidate_tiles = []
	for i in range(len(tiles)):
		if tile_types.has(tiles[i]['type']):
			candidate_tiles.push_back(i)
	var random_tile_index = candidate_tiles[rng.randi_range(0, len(candidate_tiles))]
	var tile_world_pos = get_position_from_tile(random_tile_index)
	print("Spawning rolem at tile: ", Array2D.to_coordinate(random_tile_index, tilemap_dimensions).to_string(), " from a list of ", len(candidate_tiles), " options")
	print("Spawning Rolem at position: ", tile_world_pos)
	add_child(instance_scene(scene, tile_world_pos))


func spawn_at_tile(var scene:PackedScene, var tile_coordinates:IntVector2):
	var tile_index = Array2D.to_index(tile_coordinates, tilemap_dimensions)
	var tile_world_pos = get_position_from_tile(tile_index)
	tile_world_pos.y = ground_height
	add_child(instance_scene(scene, tile_world_pos))


func instance_scene(var scene:PackedScene, var pos:Vector3):
	var scene_instance = scene.instance()
	scene_instance.global_transform.origin = pos
#	scene_instance.rotate_object_local(Vector3(0, 1, 0), rotation * PI/2)
	scene_instance.scale_object_local(Vector3(scale, scale, scale))
#	scene_instance.global_transform = scene_instance.global_transform.scaled(Vector3(scale, scale, scale))
	return scene_instance


# Return an array of positions on the way from 'from' to 'to'
func find_path(var from:Vector3, var to:Vector3):
	var path = []
	var from_g_index = get_graph_node_from_position(from)
	var to_g_index = get_graph_node_from_position(to)
#	print("Finding path from ", Array2D.to_coordinate(from_g_index, graph_dimensions).to_string(), " to ", Array2D.to_coordinate(to_g_index, graph_dimensions).to_string())
	var index_path = graph.find_path(from_g_index, to_g_index, max_pathfinding_iterations)
	for i in range(len(index_path)):
		path.push_back(get_position_from_graph_node(index_path[len(index_path) - i -1]))
	return path


func find_path_2d(var from:Vector3, var to:Vector3):
	var path_3d = find_path(from, to)
	var path_2d = []
	for pos in path_3d:
		path_2d.push_back(Vector2(pos.x, pos.z))
	return path_2d


func straigh_path_exists(var from:Vector3, var to:Vector3):
	var from_g_index = get_graph_node_from_position(from)
	var to_g_index = get_graph_node_from_position(to)
	return graph.is_straight_line_path(from_g_index, to_g_index)


func get_tile_from_position(var pos):
	pos /= scale
	pos.x += round(tilemap_dimensions.x / 2) + 0.0
	pos.z += round(tilemap_dimensions.y / 2) + 0.0
	return Array2D.to_index(IntVector2.new(pos.x, pos.z), tilemap_dimensions)


# This should really return a Vector2
func get_position_from_tile(var tile_index:int):
	var position = Array2D.to_coordinate_vec3(tile_index, tilemap_dimensions)
	position.x -= round(tilemap_dimensions.x / 2) - 0.5
	position.y = 0
	position.z -= round(tilemap_dimensions.y / 2) - 0.5
	position *= scale
	return position


func get_graph_node_from_position(var pos):
	return tile_to_graph_index(get_tile_from_position(pos))


func get_position_from_graph_node(var node_index:int):
	return get_position_from_tile(graph_to_tile_index(node_index))


# Convert a graph index into a maze tile index
func graph_to_tile_index(index:int):
	var gr_coordinate = Array2D.to_coordinate(index, graph_dimensions)
	var tile_coordinate = IntVector2.new(1 + gr_coordinate.x * 2, 1 + gr_coordinate.y * 2)
	return Array2D.to_index(tile_coordinate, tilemap_dimensions)


# Convert a maze tile index into a graph index
func tile_to_graph_index(index:int):
	var tile_coordinate = Array2D.to_coordinate(index, tilemap_dimensions)
	var gr_coordinate = IntVector2.new(floor( (tile_coordinate.x - 1) /2), floor( (tile_coordinate.y - 1) /2))
	return Array2D.to_index(gr_coordinate, graph_dimensions)


func graph_to_tile_coordinates(coords:IntVector2):
	var graph_index = Array2D.to_index(coords, graph_dimensions)
	var tile_index = graph_to_tile_index(graph_index)
	return Array2D.to_coordinate(tile_index, tilemap_dimensions)


func tile_to_graph_coordinates(coords:IntVector2):
	var tile_index = Array2D.to_index(coords, tilemap_dimensions)
	var graph_index = tile_to_graph_index(tile_index)
	return Array2D.to_coordinate(graph_index, graph_dimensions)


# Create and add all mesh instances as children
func instantiate_all_tiles():
	for tile in tiles:
		var type = tile['type']
		if(type != 'Empty'):	# Don't spawn anything for the empty tiles
			var scene = tile_scenes[type]
			tile['tile'] = MazeTile.new(type, scene, tile['pos'], tile['rot'])
			var instance = tile['tile'].create_scene_instance(scale)
			if(dynamic_types.has(type)):
				dynamic_children.push_back(instance)
			add_child(instance)


func set_night():
	var current_tile = 0
	while (true):
		var count = 0
		while(count < 150):
			if(current_tile == len(dynamic_children)):
				return
			dynamic_children[current_tile].get_node("MeshInstance").hide()
			dynamic_children[current_tile].get_node("CollisionShape").disabled = true
			count += 1
			current_tile += 1
		yield(get_tree().create_timer(0.01), "timeout")


func set_day():
	var current_tile = 0
	while (true):
		var count = 0
		while(count < 25):
			if(current_tile == len(dynamic_children)):
				return
			dynamic_children[current_tile].get_node("MeshInstance").show()
			dynamic_children[current_tile].get_node("CollisionShape").disabled = false
			count += 1
			current_tile += 1
		yield(get_tree().create_timer(0.01), "timeout")


func deactivate_tiles(types:Array):
	for tile in tiles:
		if(types.has(tile['type'])):
			tile['tile'].deactivate()


func activate_tiles(types:Array):
	for tile in tiles:
		if(types.has(tile['type'])):
			tile['tile'].activate()


func print_tiles():
	for i in range(len(tiles)):
		if(tiles[i] == null):
			print("Tile ", i, " - null ")
		else:
			print("Tile ", i, " - Type: ", tiles[i]['proto']['type'])


func print_types_matrix():
	print(len(tiles))
	for i in range(tilemap_dimensions.y):
		var output = ""
		for j in range(tilemap_dimensions.x):
			output += tiles[tilemap_dimensions.x * i + j]['proto']['type'] + "   "
		print(output)


func render_graph_as_lines():
	line_renderer.clear()
	line_renderer.begin(Mesh.PRIMITIVE_LINES)
	for node in range(len(graph.nodes)):
		var neighbors = graph.get_neighbors(node)
		for neighbor in neighbors:
			var p1 = get_position_from_graph_node(node)
			var p2 = get_position_from_graph_node(neighbor)
			p1.y += 2.5
			p2.y += 2.5
			line_renderer.set_color(Color.aqua)
			line_renderer.add_vertex(p1)
			line_renderer.add_vertex(p2)
	line_renderer.end()
