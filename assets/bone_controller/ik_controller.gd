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
    auto_start = p_auto_start # auto_start is stored but not currently used to delay start()
    root_bone = ik_group.root
    tip_bone = ik_group.tip
    armature.add_child(self) # IKController becomes a child of the armature

func _ready():
    var tip_index := armature.find_bone(tip_bone)
    var magnet_index := armature.find_bone(ik_group.magnet)

    # Get CURRENT global transforms, not rest transforms
    var current_tip_global_transform := Model.get_bone_global_transform(armature, tip_index)
    var current_magnet_global_transform := Model.get_bone_global_transform(armature, magnet_index)

    name = root_bone + "_" + tip_bone

    new_tip = Node3D.new()
    add_child(new_tip) # Add before setting global_transform as it's parented to self
    new_tip.name = name + "_controller_tip_target" # More descriptive name
    new_tip.global_transform = current_tip_global_transform # Initialize to current pose

    new_magnet = Node3D.new()
    add_child(new_magnet) # Add before setting global_transform
    new_magnet.name = name + "_controller_magnet_target" # More descriptive name
    new_magnet.global_transform = current_magnet_global_transform # Initialize to current pose

    ik_group.instanced_magnet = new_magnet
    ik_group.instanced_tip = new_tip
    ik_group.tip_index = tip_index
    ik_group.magnet_index = magnet_index

    # Configure SkeletonIK3D properties BEFORE starting
    # These properties (target, magnet) are part of SkeletonIK3D
    self.target = new_tip.global_transform
    self.magnet = new_magnet.global_position
    self.use_magnet = true
    # self.override_tip_basis = true # This is the default, good for most cases

    start() # Now start the IK. It should begin from the current pose.

    armature.skeleton_updated.connect(_on_skeleton_updated)

func _on_skeleton_updated():
    # Ensure Model class is accessible, or armature/ik_group hold needed refs
    if not is_instance_valid(armature) or not is_instance_valid(ik_group):
        printerr("IKController: Armature or IKGroup is not valid in _on_skeleton_updated.")
        return
    if not is_instance_valid(new_tip) or not is_instance_valid(new_magnet):
        printerr("IKController: new_tip or new_magnet is not valid in _on_skeleton_updated.")
        return

    if ik_group.is_tip_idle:
        # If idle, make the new_tip node follow the bone's current global transform.
        # The IK target (self.target) itself remains unchanged while idle, preventing drift.
        # new_tip is updated so if it becomes active, interaction starts from the current bone position.
        var current_bone_tip_transform = Model.get_bone_global_transform(armature, ik_group.tip_index)
        new_tip.global_transform = current_bone_tip_transform
        # DO NOT update self.target here when idle to prevent feedback loop.
    else:
        # If not idle (e.g., being dragged), new_tip's global_transform is presumably updated by external logic.
        # The IK solver should target new_tip's current global_transform.
        self.target = new_tip.global_transform

    if ik_group.is_magnet_idle:
        # Similar logic for the magnet: update the visual handle, but don't feed back to the IK magnet position while idle.
        var current_bone_magnet_transform = Model.get_bone_global_transform(armature, ik_group.magnet_index)
        new_magnet.global_transform = current_bone_magnet_transform
        # DO NOT update self.magnet here when idle.
    else:
        # If not idle, new_magnet's global_transform is set by external logic.
        # The IK solver should use its current global position.
        self.magnet = new_magnet.global_position
