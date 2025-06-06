class_name Model
extends Node3D

var manager: Manager
var ik_controllers: Array
var model_path: String
var bone_sprite_scene: PackedScene
var detail_names: Array[StringName]
var armature: Skeleton3D
var sprite_bone: Array[Array] = []

var camera: Camera3D

func get_armature(curr_node: Node = self) -> Skeleton3D:
    for child in curr_node.get_children():
        if child is Skeleton3D:
            return child
        else:
            var returned := get_armature(child)
            if returned:
                return returned

    return

func parse_name(p_name: String) -> String:
    var new_name := p_name.to_lower()
    new_name = new_name.replace(" ", ".")
    new_name = new_name.replace("_", ".")
    new_name = new_name.replace("-", ".")
    return new_name

func prepare_bones():
    for curr_index in armature.get_bone_count():
        var bone_name := armature.get_bone_name(curr_index)
        bone_name = parse_name(bone_name)
        armature.set_bone_name(curr_index, bone_name)

func is_detailed(bone_name: String) -> bool:
    for curr_name in detail_names:
        if curr_name in bone_name:
            return true

    return false

static func get_bone_global_rest_transform(p_armature: Skeleton3D, bone_id: int) -> Transform3D:
    return p_armature.global_transform * p_armature.get_bone_global_rest(bone_id)

static func get_bone_global_transform(p_armature: Skeleton3D, bone_id: int) -> Transform3D:
    return p_armature.global_transform * p_armature.get_bone_global_pose(bone_id)

static func get_bone_global_position(p_armature: Skeleton3D, bone_id: int) -> Vector3:
    return get_bone_global_transform(p_armature, bone_id).origin


func _on_tree_exiting():
    if is_queued_for_deletion():
        manager.models.erase(self)


func _ready():
    camera = get_viewport().get_camera_3d()

    assert(camera, "Camera not found")
    manager = Manager.instance
    assert(manager, "No manager found")

    tree_exiting.connect(_on_tree_exiting)

    bone_sprite_scene = manager.bone_sprite_scene
    detail_names = manager.detail_names

    armature = get_armature()
    assert(armature, "Armature not found")
    prepare_bones()

    setup_ik_controllers()
    setup_constraints()

    manager.models.append(self)

    for curr_container in manager.bone_indicator_containers:
        curr_container.instantiate_ik(self)
        curr_container.instantiate_fk(self)

func setup_constraints() -> void:
    pass

func setup_ik_controllers(auto_start: bool = false):
    assert(ik_controllers.is_empty())

    for ik_group in SharedScene.shared_ik_pairs:
        var new_controller = IKController.new()
        new_controller._setup(self, ik_group, auto_start)
        ik_controllers.append(new_controller)


func set_model_path(path: String, is_internal: bool = false) -> void:
    model_path = path
    set_meta("is_internal", is_internal)


func _input(event) -> void:
    if event is not InputEventMouseButton:
        return
