extends Node3D
class_name CameraController

@onready var elevation = $Elevation
@onready var camera = $Elevation/Camera3D

func _ready():
    elevation.rotation_degrees.x = -30
    camera.position.z = 4