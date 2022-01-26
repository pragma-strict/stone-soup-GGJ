extends KinematicBody


export(float) var jump_strength = 20.0
export(float) var movement_speed = 5.0
export(float) var gravity = 1.0

var _velocity = Vector3.ZERO
var _snap_vector = Vector3.DOWN
var _move_direction := Vector3.ZERO

func _physics_process(delta: float):	
	# Handle movement
	_move_direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	_move_direction.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	_move_direction = _move_direction.rotated(Vector3.UP, rotation.y).normalized()
	
	_velocity.x = _move_direction.x * movement_speed
	_velocity.z = _move_direction.z * movement_speed
	_velocity.y -= gravity
	
	# Handle jumping
	var just_landed = is_on_floor() and _snap_vector == Vector3.ZERO
	var should_jump = is_on_floor() and Input.is_action_just_pressed("action_jump")
	
	if(should_jump):
		_velocity.y = jump_strength
		_snap_vector = Vector3.ZERO
	elif(just_landed):
		_snap_vector = Vector3.DOWN
	elif(is_on_floor()):
		_velocity.y = 0
	
	# Apply velocity
	_velocity = move_and_slide_with_snap(_velocity, _snap_vector, Vector3.UP)
