class_name ViewportManager
extends Control

signal initial_setup_complete

var main_viewport_container = null
var root_container = null

func _ready():
    # Create initial viewport containers
    main_viewport_container = create_viewport_container(true)
    add_child(main_viewport_container)

    main_viewport_container.size = get_tree().root.size

    call_deferred("emit_signal", "initial_setup_complete")

func create_viewport_container(is_main = false):
    var container = SubViewportContainer.new()
    container.stretch = true
    container.size_flags_horizontal = SIZE_EXPAND_FILL
    container.size_flags_vertical = SIZE_EXPAND_FILL
    
    # Set up viewport
    var sub_viewport = SubViewport.new()
    sub_viewport.world_3d = get_viewport().world_3d
    
    sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    sub_viewport.physics_object_picking = true
    sub_viewport.gui_embed_subwindows = false
    
    # Add camera
    var camera_rig = load("res://assets/camera/camera.tscn").instantiate()
    sub_viewport.add_child(camera_rig)
            
    if is_main:
        sub_viewport.add_child(SharedScene.main_scene)

    # Add to container
    container.add_child(sub_viewport)

    var bone_container = BoneIndicatorContainer.new()
    bone_container.curr_camera = camera_rig
    bone_container.ik_pairs = SharedScene.shared_ik_pairs
    bone_container.fk_pairs = SharedScene.shared_fk_pairs
    sub_viewport.add_child(bone_container)
    
    return container
