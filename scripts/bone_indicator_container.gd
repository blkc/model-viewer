extends Node2D
class_name BoneIndicatorContainer

var manager: Manager
@export var curr_camera: CameraController

@export var ik_pairs: Array[IkGroup]
@export var fk_pairs: Array[FkGroup]


func instantiate_ik(model: Model):
    for controller in model.ik_controllers:
        var ik_group: IkGroup = controller.ik_group
        add_button(model, ik_group.tip_index, false, ik_group.instanced_tip, ik_group)
        add_button(model, ik_group.magnet_index, true, ik_group.instanced_magnet, ik_group)

func add_button(
    model: Model,
    bone_id: int,
    is_magnet: bool,
    object_transform: Node3D = null,
    ik_group: IkGroup = null,
) -> BoneController:
    var curr_sprite := manager.bone_sprite_scene.instantiate()
    add_child(curr_sprite)

    curr_sprite._setup(
        bone_id,
        curr_camera.camera,
        model.armature,
        is_magnet,
        object_transform,
        ik_group,
    )

    if ik_group:
        if is_magnet:
            ik_group.instanced_magnet_buttons.append(curr_sprite)
        else:
            ik_group.instanced_tip_buttons.append(curr_sprite)

    return curr_sprite

func instantiate_fk(model: Model):
    var armature := model.armature

    for curr_pair in fk_pairs:
        var bone_index := armature.find_bone(curr_pair.target_bone)
        add_button(model, bone_index, false)

func _on_tree_exiting():
    if Manager.instance and Manager.instance.bone_indicator_containers.has(self):
        Manager.instance.bone_indicator_containers.erase(self)

func _ready():
    manager = Manager.instance
    tree_exiting.connect(_on_tree_exiting)
    manager.bone_indicator_containers.append(self)

    for curr_model in manager.models:
        instantiate_ik(curr_model)
        instantiate_fk(curr_model)
