extends Node2D
class_name BoneIndicatorContainer

var manager: Manager
@export var curr_camera: CameraController

@export var ik_pairs: Array[IkGroup]
@export var fk_pairs: Array[FkGroup]

# Add dictionary to track sprites per model
var model_sprites: Dictionary = {}

func instantiate_ik(model: Model):
    # Initialize sprite array for this model
    if !model_sprites.has(model):
        model_sprites[model] = []

    # Create sprites for each existing IK controller
    for controller in model.ik_controllers:
        var ik_group: IkGroup = controller.ik_group
        # Create bone sprites that reference the existing tip and magnet nodes
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

    # Add sprite to model tracking
    if !model_sprites.has(model):
        model_sprites[model] = []
    model_sprites[model].append(curr_sprite)

    # Initialize visibility based on model selection
    curr_sprite.visible = true

    # Add the sprite to the appropriate button array in IkGroup
    if ik_group:
        if is_magnet:
            ik_group.instanced_magnet_buttons.append(curr_sprite)
        else:
            ik_group.instanced_tip_buttons.append(curr_sprite)

    return curr_sprite

func instantiate_fk(model: Model):
    var armature := model.armature
    # Initialize sprite array for this model if needed
    if !model_sprites.has(model):
        model_sprites[model] = []

    for curr_pair in fk_pairs:
        var bone_index := armature.find_bone(curr_pair.target_bone)
        add_button(model, bone_index, false)

func set_bones_visible_for_model(model: Model, show_bones: bool):
    print(">>> Container '%s': set_bones_visible_for_model(model='%s', show_bones=%s)" % [get_path(), model.name, str(show_bones)])
    if model_sprites.has(model):
        print("    Model found in sprites dictionary.")
        var sprite_count = model_sprites[model].size()
        var visible_count = 0
        for i in range(sprite_count):
             var sprite = model_sprites[model][i]
             if is_instance_valid(sprite):
                 sprite.visible = show_bones # Set visibility based *only* on show_bones
                 if sprite.visible: visible_count += 1
             else:
                 print("    Warning: Invalid sprite instance at index %d" % i)
        print("    Set visibility for %d sprites. %d should now be visible based on show_bones flag." % [sprite_count, visible_count if show_bones else 0])
    else:
        print("    Model '%s' NOT found in this container's sprites dictionary." % model.name)

# New function to disable/enable bone sprites for a specific model
func set_bone_sprites_disabled_for_model(model: Model, disable: bool):
    if model_sprites.has(model):
        var sprites_for_model = model_sprites[model] as Array
        for sprite_node in sprites_for_model:
            if is_instance_valid(sprite_node) and sprite_node is BoneController:
                var bone_controller = sprite_node as BoneController
                bone_controller.disabled = disable

# Add a function to set visibility for all bone sprites
func set_all_bones_visible(show_bones: bool):
    for sprites in model_sprites.values():
        for sprite in sprites:
            sprite.visible = show_bones

func _on_tree_exiting():
    # Always deregister from the manager when exiting the active scene tree
    if Manager.instance and Manager.instance.bone_indicator_containers.has(self):
        print("Deregistering %s from manager list." % get_path())
        Manager.instance.bone_indicator_containers.erase(self)

    # Only clear the internal sprite dictionary if the node is actually being deleted,
    # not just removed temporarily (e.g., during reparenting).
    if is_queued_for_deletion():
        print("Clearing model_sprites for %s as it is queued for deletion." % get_path())
        model_sprites.clear()
    else:
         print("Not clearing model_sprites for %s as it is only exiting tree (reparenting?)." % get_path())

func _ready():
    manager = Manager.instance
    tree_exiting.connect(_on_tree_exiting)
    manager.bone_indicator_containers.append(self)

    for curr_model in manager.models:
        instantiate_ik(curr_model)
        instantiate_fk(curr_model)
