extends KinematicBody


export(float) var jump_strength = 20.0
export(float) var movement_speed = 5.0
export(float) var gravity = 1.0
export(float) var torch_ignition_time = 1.0
export(float) var torch_burn_duration = 5.0

onready var labyrinth = get_node("../Labyrinth")
onready var camera = $"PlayerCam"
onready var debug_cam = get_node("../DebugCam/DebugCam")
onready var resin_label = $"CollectResinLabel"
onready var death_label = $"DeathLabel"
onready var ray = $"PlayerCam/RayCast"
onready var torch = $"PlayerCam/Torch"
onready var footstep_player = $"AudioPlayer"

var is_alive = true
var is_debug_cam_active = false
var is_looking_at_resin = false
var resin_tile = null
var has_fuel = false
var is_igniting = false
var is_torch_lit = false
var ignition_cancelled = false
var is_playing_footstep_audio = false

var _velocity = Vector3.ZERO
var _snap_vector = Vector3.DOWN
var _move_direction := Vector3.ZERO

func _ready():
	torch.get_node("torch/resin").hide()
	torch.get_node("TorchLight").light_energy = 0
	torch.get_node("TorchFlames").emitting = false


func _input(event):
	if(!is_alive):
		return
	if(Input.is_action_just_pressed("c")):
		is_debug_cam_active = !is_debug_cam_active
		debug_cam.set_current(is_debug_cam_active)
		debug_cam.enabled = is_debug_cam_active
	if(Input.is_action_just_pressed("interact")):
		if(is_looking_at_resin):
			take_fuel()
	if(Input.is_action_pressed("mouse_down")):
		if(!is_igniting and !is_torch_lit):
			ignite()
	if(Input.is_action_just_released("mouse_down")):
		if(is_igniting):
			ignition_cancelled = true


func _physics_process(_delta: float):	
	if(is_debug_cam_active or !is_alive):
		return
		
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
	
	var h_vel = Vector2(_velocity.x, _velocity.z)
	
	if(h_vel.length() > 0.2):
		if(!is_playing_footstep_audio):
			is_playing_footstep_audio = true
			footstep_player.play()
	else:
		if(is_playing_footstep_audio):
			is_playing_footstep_audio = false
			footstep_player.stop()
	update_ui()


func ignite():
	if(has_fuel):
		is_igniting = true
		$"AnimationPlayer".play("Black Light Grow")
		yield(get_tree().create_timer(torch_ignition_time), "timeout")
		if(!ignition_cancelled):
			is_torch_lit = true
			has_fuel = false
			get_parent().set_night()
			torch.get_node("TorchFlames").emitting = true
			$"AnimationPlayer".play("Torch Particles")
			$"AnimationPlayer".play("Torch Burn")
			yield(get_tree().create_timer(torch_burn_duration), "timeout")
			torch.get_node("TorchFlames").emitting = false
			get_parent().set_day()
			set_day()
			is_torch_lit = false
		ignition_cancelled = false
		is_igniting = false	


func take_fuel():
	resin_tile.take_resin()
	has_fuel = true
	torch.get_node("torch/resin").show()
	$"AnimationPlayer".play("Torch Take Resin")


func set_day():
	torch.get_node("torch/resin").hide()


func update_ui():
	var collider = ray.get_collider()
	if(collider):
		# Looking at tile
		resin_tile = collider.get_parent()
		if(!is_looking_at_resin and resin_tile.has_resin):	# Has resin
			is_looking_at_resin = true
			resin_label.visible = true
		if(is_looking_at_resin and !resin_tile.has_resin):	# Doesn't have resin
			is_looking_at_resin = false
			resin_label.visible = false
	else:
		# Not even looking at tile
		if(is_looking_at_resin):
			is_looking_at_resin = false
			resin_label.visible = false


func get_pos():
	return global_transform.origin


func kill():
	is_alive = false
	camera.enabled = false
	$"AnimationPlayer".play("Death Cam")
	yield(get_tree().create_timer(5), "timeout")
	death_label.visible = true
