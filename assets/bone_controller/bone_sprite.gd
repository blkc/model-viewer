extends Button
class_name BoneController

enum Status {None, Clicked, Dragging, Gizmo}

const CLICK_DELAY := 0.5

@export var centered = true

static var manager: Manager

var curr_camera: Camera3D

var armature: Skeleton3D
var bone_id: int
var object_target: Node3D

var camera_plane: Plane

var ik_group: IkGroup

var raw_event_pos: Vector2

var status := Status.None
var mouse_position: Vector2

@onready var rect_offset = size / 2

signal dragging
signal dragging_start

func _setup(
        p_bone_id: int,
        p_curr_camera: Camera3D,
        p_armature: Skeleton3D,
        _p_is_magnet: bool,
        p_object_target: Node3D = null,
        p_ik_group: IkGroup = null,
    ):
    assert(p_bone_id != -1)

    if (!manager):
        manager = Manager.instance

    bone_id = p_bone_id

    object_target = p_object_target

    ik_group = p_ik_group
    curr_camera = p_curr_camera
    armature = p_armature

    button_down.connect(_on_button_down)
    button_up.connect(_on_button_up)
    dragging_start.connect(_on_dragging_start)
    dragging.connect(_on_dragging)

func flattened_button_position():
    var start = curr_camera.project_ray_origin(raw_event_pos)
    var ray_normal = curr_camera.project_ray_normal(raw_event_pos)
    return camera_plane.intersects_ray(start, ray_normal)

func _on_dragging():
    position = mouse_position

    var controller_pos = flattened_button_position()

    if object_target:
        object_target.global_position = controller_pos
        return

    armature.set_bone_pose_position(bone_id, controller_pos)

func _on_button_down():
    status = Status.Clicked

func _on_button_up():
    status = Status.None

func _on_dragging_start():
    var obj_global: Vector3
    if object_target:
        obj_global = object_target.global_position
    else:
        var bone: Transform3D = armature.get_bone_global_pose_no_override(bone_id)
        obj_global = bone.origin

    var towards_camera = obj_global.direction_to(curr_camera.global_position)
    camera_plane = Plane(towards_camera, obj_global)

func _input(event):
    if event is not InputEventMouseMotion:
        return

    raw_event_pos = event.position
    if centered:
        mouse_position = raw_event_pos - rect_offset
    else:
        mouse_position = raw_event_pos

    if status == Status.Clicked:
        status = Status.Dragging
        dragging_start.emit()

func _process(_delta):
    if status == Status.Dragging:
        dragging.emit()

    if object_target and !is_instance_valid(object_target):
        object_target = null
        return

    if !is_instance_valid(armature):
        queue_free()
        return

    if status == Status.Dragging or status == Status.Clicked:
        return

    var global_pos: Vector3
    if object_target:
        global_pos = object_target.global_position
    else:
        global_pos = Model.get_bone_global_position(armature, bone_id)

    var viewport = get_viewport()
    if viewport and curr_camera:
        var new_pos = curr_camera.unproject_position(global_pos)
        
        var viewport_container = viewport.get_parent()
        if viewport_container is SubViewportContainer:
            var viewport_manager = Manager.instance.viewport_manager
            var is_main_viewport = (viewport_container == viewport_manager.main_viewport_container)
            
            var viewport_scale = Vector2(viewport_container.size) / Vector2(viewport.size)
            
            new_pos = new_pos * viewport_scale
            
            if !is_main_viewport:
                new_pos = new_pos
            else:
                new_pos = new_pos + viewport_container.global_position
            
            position = new_pos - rect_offset
