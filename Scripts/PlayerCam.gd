extends Camera

onready var Player = get_parent()


## Increase this value to give a slower turn speed
const CAMERA_TURN_SPEED = 200

func _ready():
	set_process_input(true)

func look_updown_rotation(rotation = 0):
	var toReturn = self.get_rotation() + Vector3(rotation, 0, 0)
	toReturn.x = clamp(toReturn.x, PI / -2, PI / 2)

	return toReturn

func look_leftright_rotation(rotation = 0):
	return Player.get_rotation() + Vector3(0, rotation, 0)

func _input(event):
	if event is InputEventMouseMotion:
		## We'll use the parent node "Player" to set our left-right rotation
		## This prevents us from adding the x-rotation to the y-rotation
		## which would result in a kind of flight-simulator camera
		Player.set_rotation(look_leftright_rotation(event.relative.x / -CAMERA_TURN_SPEED))

		## Now we can simply set our y-rotation for the camera, and let godot
		## handle the transformation of both together
		self.set_rotation(look_updown_rotation(event.relative.y / -CAMERA_TURN_SPEED))
