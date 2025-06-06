# TODO: Review this entire script, idle detection seemingly is being used in a
# very weird manner
extends Resource
class_name IkGroup

const STATUS := BoneController.Status

@export var root: StringName
@export var magnet: StringName
@export var tip: StringName

var tip_index: int
var magnet_index: int

var instanced_tip: Node3D
var instanced_magnet: Node3D

var instanced_tip_buttons: Array[BoneController]
var instanced_magnet_buttons: Array[BoneController]

func detect_idle(curr_array: Array[BoneController]) -> bool:
    # Create a new array to store valid buttons
    var valid_buttons: Array[BoneController] = []

    for curr_button in curr_array:
        if is_instance_valid(curr_button):
            if curr_button.status != STATUS.None:
                return false
            valid_buttons.append(curr_button)

    # Replace the original array with only valid buttons
    curr_array.clear()
    curr_array.append_array(valid_buttons)
    return true

var is_tip_idle: bool:
    get: return detect_idle(instanced_tip_buttons)

var is_magnet_idle: bool:
    get: return detect_idle(instanced_magnet_buttons)

var is_idle:
    get: return is_tip_idle && is_magnet_idle
