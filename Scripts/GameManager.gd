extends Node

var day_env = preload("res://Environment Settings/day_env.tres")
var night_env = preload("res://Environment Settings/night_env.tres")
var twilight_env = preload("res://Environment Settings/twilight_env.tres")

var environment_node
var time = DAY
var can_update_time = true
var is_mouse_captured = false

enum{
	DAY,
	NIGHT,
	TWILIGHT
}


func _ready():
	environment_node = get_node("WorldEnvironment")


func _input(event):
	if (event is InputEventMouseButton):
		is_mouse_captured = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
	if(Input.is_action_pressed("move_up")):
		toggle_day_night()
			
	if (Input.is_action_pressed("ui_fullscreen")):
		OS.window_fullscreen = !OS.window_fullscreen
	
	if (Input.is_key_pressed(KEY_ESCAPE)):
		get_tree().quit()


func toggle_day_night():
	if(time == DAY):
		set_time(NIGHT)
	elif(time == NIGHT):
		set_time(DAY)


func set_time(new_time):
	if(can_update_time):
		var is_time_valid = false
		if(new_time == DAY):
			time = DAY
			environment_node.environment = day_env
			is_time_valid = true
		elif(new_time == NIGHT):
			time = NIGHT
			environment_node.environment = night_env
			is_time_valid = true
		elif(new_time == TWILIGHT):
			time = TWILIGHT
			environment_node.environment = twilight_env
			is_time_valid = true
		if(is_time_valid):
			can_update_time = false
			yield(get_tree().create_timer(1.0), "timeout")
			can_update_time = true
