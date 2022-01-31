extends Camera

onready var Player = get_parent()

const CAMERA_TURN_SPEED = 150

var enabled = true


func _ready():
	set_process_input(true)

func look_updown_rotation(rotation = 0):
	var toReturn = self.get_rotation() + Vector3(rotation, 0, 0)
	toReturn.x = clamp(toReturn.x, PI / -2, PI / 2)

	return toReturn

func look_leftright_rotation(rotation = 0):
	return Player.get_rotation() + Vector3(0, rotation, 0)

func _input(event):
	if(!enabled):
		return
	if event is InputEventMouseMotion:
		Player.set_rotation(look_leftright_rotation(event.relative.x / -CAMERA_TURN_SPEED))
		self.set_rotation(look_updown_rotation(event.relative.y / -CAMERA_TURN_SPEED))
