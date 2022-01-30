extends KinematicBody

# ================================================================== #
# Basic functionality for making this KinematicBody track the player #
# ================================================================== #

var path = []
var path_node = 0	 # Index of the current position in the path
var next_target = Vector2.ZERO	# The next position to move to
var dir_to_target = Vector2.ZERO
var snap_vector = Vector3.DOWN
var velocity = Vector3.ZERO
var reached_floor = false
var can_see_player = false

export(int) var movement_speed = 4

onready var player = $"../../Player"
onready var labyrinth = get_parent()


func _physics_process(delta):
	if can_see_player:
		velocity = player.get_pos() - global_transform.origin
		velocity.y = 0
		velocity = velocity.normalized() * movement_speed
		
	elif path_node < len(path):	 # If we have a target
		
		next_target = path[path_node]
		dir_to_target = (next_target - Array2D.vec3_to_vec2(global_transform.origin))
		
		if(dir_to_target.length() < 0.5):	# If reached current target
			path_node += 1		# Increment path node
		
		else:
			velocity = Array2D.vec2_to_vec3(dir_to_target.normalized() * movement_speed)
	else:
		velocity = Vector3.ZERO
	
	if(!reached_floor):	# Once the floor is reached all vertical movement stops forever
		if(is_on_floor()):
			reached_floor = true
		else:
			velocity.y = -10
	move_and_slide(velocity, Vector3.UP)	


func generate_path_to_player():
	path = labyrinth.find_path_2d(transform.origin, player.global_transform.origin)
	path_node = 0
#	print(path)
	if(len(path) > 1 and path[1] == next_target):
		path_node += 1
#	labyrinth.render_graph_as_lines()
	update_player_line_of_sight()


func update_player_line_of_sight():
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(transform.origin, player.get_pos(), [self])
	if(result.has('collider')):	
		if(result['collider'] == player and labyrinth.straigh_path_exists(transform.origin, player.get_pos())):
			can_see_player = true	# Only set this true if the enemy is in an unimpeded path
		else:
			can_see_player = false


func _on_Timer_timeout():
	generate_path_to_player()


func _on_Area_body_entered(body):
	if(body == player):
		player.kill()
	
