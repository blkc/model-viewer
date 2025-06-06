extends Node

var main_scene: Node3D
var shared_ik_pairs: Array[IkGroup]
var shared_fk_pairs: Array[FkGroup]


func _ready():
    # Load the shared world scene
    var scene := load("res://scenes/shared_scene.tscn")
    main_scene = scene.instantiate()

    # Get the configuration from the Configuration node
    var config_container: BoneIndicatorContainer = main_scene.get_node("Configuration/BoneIndicatorContainer")

    assert(config_container)

    shared_ik_pairs = config_container.ik_pairs.duplicate()
    shared_fk_pairs = config_container.fk_pairs.duplicate()
    # Remove the Configuration node entirely since it's just for storing settings
    main_scene.get_node("Configuration").queue_free()
