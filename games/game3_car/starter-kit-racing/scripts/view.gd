extends Node3D

@export_group("Properties")
@export var target: Vehicle

@onready var camera = $Camera
const CAMERA_NEAR_Z := 24.0
const CAMERA_FAR_Z := 32.0

# Functions

func _physics_process(delta: float) -> void:
	if target == null:
		return
	
	# Ease position towards target vehicle position
	position = position.lerp(target.get_vehicle_position(), delta * 4.0)

	# Keep enough track and city context visible while the player drives.
	var speed_factor := clampf(absf(target.linear_speed), 0.0, 1.0)
	var target_z := lerpf(CAMERA_NEAR_Z, CAMERA_FAR_Z, speed_factor)
	camera.position.z = lerpf(camera.position.z, target_z, delta * 0.8)
