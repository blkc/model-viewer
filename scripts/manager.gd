extends Node
class_name Manager

@export var root_bone_name: StringName
@export var bone_sprite_scene: PackedScene
@export var models: Array[Model]
@export var bone_indicator_containers: Array[BoneIndicatorContainer]
@export var detail_names: Array[StringName] = [
    "middle",
    "ring",
    "thumb",
    "index",
]

@onready var control := %Control

@export var split_view: SubViewportContainer

static var instance: Manager

@onready var viewport_manager: Control = $"../ViewportManager"

const MAX_MODEL_LOAD_ATTEMPTS = 5

func _on_views_toggled(toggled_on: bool) -> void:
    split_view.visible = toggled_on

func _ready() -> void:
    Manager.instance = self
    print("Manager ready")

    if viewport_manager:
        viewport_manager.initial_setup_complete.connect(_load_default_model, CONNECT_ONE_SHOT)

static func add_model_to_scene(gltf_document_load, gltf_state_load, file_path: String = ""):
    var root_node = gltf_document_load.generate_scene(gltf_state_load)
    root_node.set_script(load("res://assets/model/model.gd"))

    if file_path.is_empty():
        return

    root_node.set_model_path(file_path, false)

    var model_container = SharedScene.main_scene.get_node("%ModelContainer")
    if model_container:
        model_container.add_child(root_node)
        print("Node added to scene with path:", root_node.model_path)
        return root_node
    else:
        printerr("ModelContainer not found in SharedScene")
        return null

func _load_default_model() -> void:
    var timer = get_tree().create_timer(0.5)
    await timer.timeout

    print("[Manager] Loading default model...")

    var http = HTTPRequest.new()
    add_child(http)

    http.request_completed.connect(_on_model_download_completed)

    var url = "https://pub-c417d4215d08462db4e44fe0c3fb8872.r2.dev/POSEDRAW_FEM_FINAL_V01.glb"
    var error = http.request(url)
    if error != OK:
        printerr("[Manager] An error occurred in the HTTP request:", error)
        http.queue_free()

func _on_model_download_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if get_node_or_null("HTTPRequest"):
        get_node_or_null("HTTPRequest").queue_free()
    
    if result != HTTPRequest.RESULT_SUCCESS:
        printerr("[Manager] Failed to download model - Result:", result)
        return

    if response_code != 200:
        printerr("[Manager] Failed to download model - HTTP code:", response_code)
        return

    var gltf_document = GLTFDocument.new()
    var gltf_state = GLTFState.new()
    var error = gltf_document.append_from_buffer(body, "", gltf_state)

    if error == OK:
        print("[Manager] Default model loaded successfully")
        var root_node = gltf_document.generate_scene(gltf_state)
        root_node.set_script(load("res://assets/model/model.gd"))
        
        var model_container = SharedScene.main_scene.get_node("%ModelContainer")
        if model_container:
            model_container.add_child(root_node)
            print("[Manager] Default model added to scene")
        else:
            printerr("[Manager] ModelContainer not found in SharedScene")
    else:
        printerr("[Manager] Error loading default model:", error_string(error))
