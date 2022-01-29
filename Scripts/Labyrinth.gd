extends Node


export(Vector2) var graph_dimensions # How many node wide is the graph?
export(float) var scale
export(int) var max_pathfinding_iterations = 250

export(Dictionary) var tile_scenes = {
	"Path" : PackedScene,
	"Wall" : PackedScene,
	"Door" : PackedScene,
	"Corner" : PackedScene
}

export(Dictionary) var NPC_scenes = {
	"Rolem" : PackedScene
}

onready var line_renderer:ImmediateGeometry = $"../LineRenderer"

var tile_prototypes = {}

var graph

var tiles = []
var tilemap_dimensions
var num_tiles

var rng


# Called when the node enters the scene tree for the first time.
func _ready():
	rng = RandomNumberGenerator.new()
	
	graph_dimensions = IntVector2.new(graph_dimensions.x, graph_dimensions.y)
	graph = MazeGraph.new(graph_dimensions)
	graph.generate_DFS(0)
	tilemap_dimensions = IntVector2.new(graph_dimensions.x * 2 + 1, graph_dimensions.y * 2 + 1)
	num_tiles = tilemap_dimensions.x * tilemap_dimensions.y

	initialize_tile_protos()
	generate_tiles()
	instantiate_all_tiles()
	spawn_at_tile(NPC_scenes['Rolem'], ['Path'])
	render_graph_as_lines()


# Sets up the dictionaries that hold all the data for each type of tile
func initialize_tile_protos():
	var keys = tile_scenes.keys()
	for i in range(len(keys)):
		tile_prototypes[keys[i]] = {
			'type' : keys[i]
		}


# Generates all tiles
func generate_tiles():
	tiles.clear()
	tiles.resize(num_tiles)
	for i in range(graph.num_nodes):
		generate_tiles_from_graph_node(i)


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


func spawn_at_tile(var scene:PackedScene, var tile_types:Array):
	var candidate_tiles = []
	for i in range(len(tiles)):
		if tile_types.has(tiles[i]['type']):
			candidate_tiles.push_back(i)
	var random_tile_index = rng.randi_range(0, len(candidate_tiles))
	var tile_world_pos = get_position_from_tile(random_tile_index)
	add_child(instance_scene(scene, tile_world_pos))


func instance_scene(var scene:PackedScene, var pos:Vector3):
	var scene_instance = scene.instance()
	scene_instance.translate_object_local(pos)
#	scene_instance.rotate_object_local(Vector3(0, 1, 0), rotation * PI/2)
	scene_instance.scale_object_local(Vector3(scale, scale, scale))
	return scene_instance


# Return an array of positions on the way from 'from' to 'to'
func find_path(var from:Vector3, var to:Vector3):
	var path = []
	var from_g_index = get_graph_node_from_position(from)
	var to_g_index = get_graph_node_from_position(to)
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
	pos.x += round(tilemap_dimensions.x / 2) + 0.5
	pos.z += round(tilemap_dimensions.y / 2) + 0.5
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


# Create and add all mesh instances as children
func instantiate_all_tiles():
	for tile in tiles:
		var type = tile['type']
		var scene = tile_scenes[type]
		tile['tile'] = MazeTile.new(type, scene, tile['pos'], tile['rot'])
		add_child(tile['tile'].create_scene_instance(scale))


func get_ground_height():
	return "you picked the wrong function, buddy."


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
