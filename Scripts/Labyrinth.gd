extends Node


export(Vector2) var graph_dimensions # How many node wide is the graph?
export(float) var scale

export(Dictionary) var tile_scenes = {
	"Path" : PackedScene,
	"Wall" : PackedScene,
	"Door" : PackedScene,
	"Corner" : PackedScene
}

export(Dictionary) var tile_meshes = {
	"Path" : Mesh,
	"Wall" : Mesh,
	"Door" : Mesh,
	"Corner" : Mesh
}

var tile_prototypes = {}

var graph

var tiles = []
var tilemap_dimensions
var num_tiles


# Called when the node enters the scene tree for the first time.
func _ready():
	graph_dimensions = IntVector2.new(graph_dimensions.x, graph_dimensions.y)
	graph = MazeGraph.new(graph_dimensions)
	graph.generate_DFS(0)
	tilemap_dimensions = IntVector2.new(graph_dimensions.x * 2 + 1, graph_dimensions.y * 2 + 1)
	num_tiles = tilemap_dimensions.x * tilemap_dimensions.y

	initialize_tile_protos()
	generate_tiles()
	instantiate_all_tiles()


# Sets up the dictionaries that hold all the data for each type of tile
func initialize_tile_protos():
	var keys = tile_meshes.keys()
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
	var tile_index = graph.graph_to_tile_index(node_index, tilemap_dimensions)
	
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
	var position = Array2D.to_coordinate_vec3(index, tilemap_dimensions)
	position.x -= round(tilemap_dimensions.x / 2)
	position.z -= round(tilemap_dimensions.y / 2)
	position *= scale
	tiles[index] = {
		'type' : type,
		'pos' : position,
		'rot' : rot,
		'tile' : null	 # This will be replaced with a MazeTileBase object
	}


# Create and add all mesh instances as children
func instantiate_all_tiles():
	for tile in tiles:
		var type = tile['type']
		var scene = tile_scenes[type]
		tile['tile'] = MazeTileBase.new(type, scene, tile['pos'], tile['rot'])
		add_child(tile['tile'].create_scene_instance(scale))


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
