extends SkeletonIK3D
class_name IKController

var ik_group: IkGroup

var armature: Skeleton3D
var magnet_transform: Transform3D
var new_tip: Node3D
var new_magnet: Node3D

var model: Model
var auto_start: bool = false

func _setup(p_model: Model, p_ik_group: IkGroup, p_auto_start: bool = false):
    ik_group = p_ik_group
    model = p_model
    armature = p_model.armature
    auto_start = p_auto_start
    root_bone = ik_group.root
    tip_bone = ik_group.tip
    armature.add_child(self)

func _ready():
    var tip_index := armature.find_bone(tip_bone)
    var magnet_index := armature.find_bone(ik_group.magnet)

    var current_tip_global_transform := Model.get_bone_global_transform(armature, tip_index)
    var current_magnet_global_transform := Model.get_bone_global_transform(armature, magnet_index)

    name = root_bone + "_" + tip_bone

    new_tip = Node3D.new()
    add_child(new_tip)
    new_tip.name = name + "_controller_tip_target"
    new_tip.global_transform = current_tip_global_transform

    new_magnet = Node3D.new()
    add_child(new_magnet)
    new_magnet.name = name + "_controller_magnet_target"
    new_magnet.global_transform = current_magnet_global_transform

    ik_group.instanced_magnet = new_magnet
    ik_group.instanced_tip = new_tip
    ik_group.tip_index = tip_index
    ik_group.magnet_index = magnet_index

    self.target = new_tip.global_transform
    self.magnet = new_magnet.global_position
    self.use_magnet = true

    start()

    armature.skeleton_updated.connect(_on_skeleton_updated)

func _on_skeleton_updated():
    if ik_group.is_tip_idle:
        var current_bone_tip_transform = Model.get_bone_global_transform(armature, ik_group.tip_index)
        new_tip.global_transform = current_bone_tip_transform
    else:
        self.target = new_tip.global_transform

    if ik_group.is_magnet_idle:
        var current_bone_magnet_transform = Model.get_bone_global_transform(armature, ik_group.magnet_index)
        new_magnet.global_transform = current_bone_magnet_transform
    else:
        self.magnet = new_magnet.global_position
