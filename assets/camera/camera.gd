extends Node3D
class_name CameraController

@onready var elevation = $Elevation
@onready var camera = $Elevation/Camera3D

func _ready():
    # Set initial camera position and rotation
    elevation.rotation_degrees.x = -45 # 45 degrees elevation
    camera.position.z = 4 # Distance from center