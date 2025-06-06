extends Node

var main_scene: Node3D
var shared_ik_pairs: Array[IkGroup]
var shared_fk_pairs: Array[FkGroup]


func _ready():
    var scene := load("res://scenes/shared_scene.tscn")
    main_scene = scene.instantiate()

    var config_container: BoneIndicatorContainer = main_scene.get_node("Configuration/BoneIndicatorContainer")

    assert(config_container)

    shared_ik_pairs = config_container.ik_pairs.duplicate()
    shared_fk_pairs = config_container.fk_pairs.duplicate()
    main_scene.get_node("Configuration").queue_free()
